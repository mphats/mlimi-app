import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../constants/app_constants.dart';
import 'cache_service.dart';
import '../../models/consultation_model.dart';
import '../../models/consultation_message_model.dart';
import '../models/user_model.dart';
import '../utils/logger.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final CacheService _cacheService = CacheService();
  final Connectivity _connectivity = Connectivity();

  void initialize() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiV1,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add request/response interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token to requests
          final token = await getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // Log request details in debug mode
          _logRequest(options);
          handler.next(options);
        },
        onResponse: (response, handler) {
          // Log response details in debug mode
          _logResponse(response);
          handler.next(response);
        },
        onError: (error, handler) async {
          _logError(error);

          // Handle token expiry (401 Unauthorized or 403 Forbidden)
          if (error.response?.statusCode == 401 ||
              error.response?.statusCode == 403) {
            // Check if it's a token-related error
            final errorData = error.response?.data;
            bool isTokenError = false;
            
            // Handle different error response formats
            if (errorData is Map) {
              // Check for token_not_valid code
              if (errorData['code'] == 'token_not_valid') {
                isTokenError = true;
              }
              // Check for detail field with token expiration message
              else if (errorData['detail'] is String && 
                       (errorData['detail'].toString().contains('Token is invalid or expired') ||
                        errorData['detail'].toString().contains('Token is expired'))) {
                isTokenError = true;
              }
              // Check for nested detail structure
              else if (errorData['detail'] is Map && 
                       errorData['detail'].containsKey('string') &&
                       errorData['detail']['string'].toString().contains('Token is expired')) {
                isTokenError = true;
              }
              // Check for messages array with token error details
              else if (errorData.containsKey('messages') && errorData['messages'] is List) {
                final messages = errorData['messages'] as List;
                if (messages.isNotEmpty && messages[0] is Map) {
                  final firstMessage = messages[0] as Map;
                  if (firstMessage.containsKey('message') && 
                      firstMessage['message'].toString().contains('Token is expired')) {
                    isTokenError = true;
                  }
                }
              }
            }

            if (isTokenError) {
              final refreshed = await _refreshToken();
              if (refreshed) {
                // Retry the original request with new token
                final token = await getAccessToken();
                final options = error.requestOptions;
                options.headers['Authorization'] = 'Bearer $token';

                try {
                  final response = await _dio.fetch(options);
                  handler.resolve(response);
                  return;
                } catch (e) {
                  // If retry fails, proceed with original error
                }
              } else {
                // Refresh failed, clear tokens and redirect to login
                await clearTokens();
                // Notify the app that authentication has failed
                // This could be done through a callback or event system
              }
            }
          }

          handler.next(error);
        },
      ),
    );
  }

  // Token management methods
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    try {
      await _secureStorage.write(
        key: AppConstants.accessTokenKey,
        value: accessToken,
      );
      await _secureStorage.write(
        key: AppConstants.refreshTokenKey,
        value: refreshToken,
      );
    } catch (e) {
      throw Exception('Failed to save tokens: $e');
    }
  }

  Future<String?> getAccessToken() async {
    try {
      return await _secureStorage.read(key: AppConstants.accessTokenKey);
    } catch (e) {
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.read(key: AppConstants.refreshTokenKey);
    } catch (e) {
      return null;
    }
  }

  Future<void> clearTokens() async {
    try {
      await _secureStorage.delete(key: AppConstants.accessTokenKey);
      await _secureStorage.delete(key: AppConstants.refreshTokenKey);
      await _secureStorage.delete(key: AppConstants.userDataKey);
    } catch (e) {
      // Ignore errors when clearing tokens
    }
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _dio.post(
        AppConstants.refreshToken,
        data: {'refresh': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        // Check if data is valid
        if (data is Map<String, dynamic> && data.containsKey('access')) {
          // Save both access and refresh tokens (refresh token might be renewed)
          await saveTokens(data['access'], data['refresh'] ?? refreshToken);
          return true;
        } else {
          // Invalid response format, clear tokens
          await clearTokens();
          return false;
        }
      }
      // If refresh fails with 401/403, clear tokens
      else if (response.statusCode == 401 || response.statusCode == 403) {
        await clearTokens();
        return false;
      }
    } catch (e) {
      // Refresh token is invalid or expired, clear all tokens
      await clearTokens();
    }
    return false;
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null;
  }

  // Check network connectivity
  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    // In connectivity_plus v6+, checkConnectivity returns List<ConnectivityResult>
    return result.any((r) => r != ConnectivityResult.none);
  }

  // Generic HTTP methods with caching and offline support
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool useCache = false,
    int cacheExpirySeconds = 300, // 5 minutes default
  }) async {
    // Check if we're online
    final online = await isOnline();
    
    // If offline and caching is enabled, try to return cached data
    if (!online && useCache) {
      final cacheKey = _cacheService.generateCacheKey(path, queryParameters);
      final cachedResponse = await _cacheService.getCachedResponse(cacheKey);
      
      if (cachedResponse != null) {
        // Return cached response
        return Response(
          data: cachedResponse,
          statusCode: 200,
          requestOptions: RequestOptions(path: path),
        );
      }
    }
    
    try {
      // If caching is enabled, check cache first
      if (useCache && online) {
        final cacheKey = _cacheService.generateCacheKey(path, queryParameters);
        final cachedResponse = await _cacheService.getCachedResponse(cacheKey);

        if (cachedResponse != null) {
          // Return cached response
          return Response(
            data: cachedResponse,
            statusCode: 200,
            requestOptions: RequestOptions(path: path),
          );
        }
      }

      // Make actual API call
      final response = await _dio.get(path, queryParameters: queryParameters);

      // Log response details for debugging
      assert(() {
        Logger.debug('🟢 API Response: ${response.statusCode} ${response.requestOptions.uri}');
        Logger.debug('Response Data Type: ${response.data.runtimeType}');
        if (response.data is Map) {
          Logger.debug('Response Data Keys: ${response.data.keys}');
        } else if (response.data is List) {
          Logger.debug('Response Data Length: ${response.data.length}');
        }
        return true;
      }());

      // If caching is enabled and we're online, cache the response
      if (useCache && online) {
        final cacheKey = _cacheService.generateCacheKey(path, queryParameters);
        await _cacheService.cacheResponse(
          cacheKey,
          response.data,
          expirySeconds: cacheExpirySeconds,
        );
      }

      return response;
    } on DioException catch (e) {
      // If we're offline and this is a network error, try to return cached data
      if (!online && e.type == DioExceptionType.connectionError) {
        if (useCache) {
          final cacheKey = _cacheService.generateCacheKey(path, queryParameters);
          final cachedResponse = await _cacheService.getCachedResponse(cacheKey);
          
          if (cachedResponse != null) {
            // Return cached response
            return Response(
              data: cachedResponse,
              statusCode: 200,
              requestOptions: RequestOptions(path: path),
            );
          }
        }
      }
      
      throw _handleDioError(e);
    }
  }

  Future<Response> post(String path, {dynamic data, Options? options}) async {
    // Check if we're online
    final online = await isOnline();
    
    // If offline, store data for later sync using enhanced method
    if (!online) {
      await storeOfflinePost(path, data);
      
      // Return a simulated success response
      return Response(
        data: {'message': 'Data saved for offline sync'},
        statusCode: 200,
        requestOptions: RequestOptions(path: path),
      );
    }
    
    try {
      // Clear cache for this endpoint when posting new data
      final cacheKey = _cacheService.generateCacheKey(path);
      await _cacheService.clearCache(cacheKey);

      return await _dio.post(path, data: data, options: options);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> put(String path, {dynamic data}) async {
    // Check if we're online
    final online = await isOnline();
    
    // If offline, store data for later sync using enhanced method
    if (!online) {
      await storeOfflinePut(path, data);
      
      // Return a simulated success response
      return Response(
        data: {'message': 'Data saved for offline sync'},
        statusCode: 200,
        requestOptions: RequestOptions(path: path),
      );
    }
    
    try {
      // Clear cache for this endpoint when updating data
      final cacheKey = _cacheService.generateCacheKey(path);
      await _cacheService.clearCache(cacheKey);

      return await _dio.put(path, data: data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> patch(String path, {dynamic data}) async {
    // Check if we're online
    final online = await isOnline();
    
    // If offline, store data for later sync using enhanced method
    if (!online) {
      await storeOfflinePatch(path, data);
      
      // Return a simulated success response
      return Response(
        data: {'message': 'Data saved for offline sync'},
        statusCode: 200,
        requestOptions: RequestOptions(path: path),
      );
    }
    
    try {
      // Clear cache for this endpoint when patching data
      final cacheKey = _cacheService.generateCacheKey(path);
      await _cacheService.clearCache(cacheKey);

      return await _dio.patch(path, data: data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> delete(String path, {dynamic data}) async {
    // Check if we're online
    final online = await isOnline();
    
    // If offline, store data for later sync using enhanced method
    if (!online) {
      await storeOfflineDelete(path, data);
      
      // Return a simulated success response
      return Response(
        data: {'message': 'Data saved for offline sync'},
        statusCode: 200,
        requestOptions: RequestOptions(path: path),
      );
    }
    
    try {
      // Clear cache for this endpoint when deleting data
      final cacheKey = _cacheService.generateCacheKey(path);
      await _cacheService.clearCache(cacheKey);

      return await _dio.delete(path, data: data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> postMultipart(String path, FormData formData) async {
    // Check if we're online
    final online = await isOnline();
    
    // If offline, store data for later sync
    if (!online) {
      final cacheKey = _cacheService.generateCacheKey(path, {'method': 'post_multipart'});
      await _cacheService.storeOfflineData(
        cacheKey,
        method: 'post_multipart',
        path: path,
        data: {
          'formData': formData.fields.map((field) => {'key': field.key, 'value': field.value}).toList(),
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      
      // Return a simulated success response
      return Response(
        data: {'message': 'Data saved for offline sync'},
        statusCode: 200,
        requestOptions: RequestOptions(path: path),
      );
    }
    
    try {
      // Clear cache for this endpoint when posting new data
      final cacheKey = _cacheService.generateCacheKey(path);
      await _cacheService.clearCache(cacheKey);

      // Let Dio handle the Content-Type header automatically for multipart data
      final response = await _dio.post(
        path,
        data: formData,
      );
      
      // Validate response data structure
      if (response.data != null) {
        // Ensure response data is of expected type (Map or List)
        if (!(response.data is Map || response.data is List)) {
          throw ApiException('Invalid response data type: ${response.data.runtimeType}');
        }
      }
      
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      // Catch any unexpected errors and wrap them in ApiException
      throw ApiException('Unexpected error during multipart upload: $e');
    }
  }

  Future<Response> putMultipart(String path, FormData formData) async {
    // Check if we're online
    final online = await isOnline();
    
    // If offline, store data for later sync
    if (!online) {
      final cacheKey = _cacheService.generateCacheKey(path, {'method': 'put_multipart'});
      await _cacheService.storeOfflineData(
        cacheKey,
        method: 'put_multipart',
        path: path,
        data: {
          'formData': formData.fields.map((field) => {'key': field.key, 'value': field.value}).toList(),
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      
      // Return a simulated success response
      return Response(
        data: {'message': 'Data saved for offline sync'},
        statusCode: 200,
        requestOptions: RequestOptions(path: path),
      );
    }
    
    try {
      // Clear cache for this endpoint when updating data
      final cacheKey = _cacheService.generateCacheKey(path);
      await _cacheService.clearCache(cacheKey);

      // Let Dio handle the Content-Type header automatically for multipart data
      final response = await _dio.put(
        path,
        data: formData,
      );
      
      // Validate response data structure
      if (response.data != null) {
        // Ensure response data is of expected type (Map or List)
        if (!(response.data is Map || response.data is List)) {
          throw ApiException('Invalid response data type: ${response.data.runtimeType}');
        }
      }
      
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      // Catch any unexpected errors and wrap them in ApiException
      throw ApiException('Unexpected error during multipart upload: $e');
    }
  }

  // Synchronize offline data when connectivity is restored
  Future<void> syncOfflineData() async {
    final online = await isOnline();
    if (!online) return;
    
    try {
      final unsyncedData = await _cacheService.getUnsyncedData();
      
      for (final entry in unsyncedData.entries) {
        final key = entry.key;
        final requestData = entry.value;
        
        // Skip if retry count is too high (prevent infinite retries)
        final retryCount = await _cacheService.getRetryCount(key);
        if (retryCount > 3) {
                Logger.debug('Skipping sync for $key due to too many retries');
          continue;
        }
        
        if (requestData is Map && requestData['method'] != null) {
          try {
            Response response;
            
            // Add authentication header if available
            final token = await getAccessToken();
            final headers = <String, String>{};
            if (token != null) {
              headers['Authorization'] = 'Bearer $token';
            }
            
            // Add any custom headers from the request
            if (requestData['headers'] is Map) {
              (requestData['headers'] as Map).forEach((k, v) {
                if (k is String && v is String) {
                  headers[k] = v;
                }
              });
            }
            
            switch (requestData['method']) {
              case 'post':
                response = await _dio.post(
                  requestData['path'], 
                  data: requestData['data'],
                  options: Options(headers: headers),
                );
                break;
              case 'put':
                response = await _dio.put(
                  requestData['path'], 
                  data: requestData['data'],
                  options: Options(headers: headers),
                );
                break;
              case 'patch':
                response = await _dio.patch(
                  requestData['path'], 
                  data: requestData['data'],
                  options: Options(headers: headers),
                );
                break;
              case 'delete':
                response = await _dio.delete(
                  requestData['path'], 
                  data: requestData['data'],
                  options: Options(headers: headers),
                );
                break;
              default:
                continue;
            }
            
            // If successful, mark as synced
            if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
              await _cacheService.markAsSynced(key);
                    Logger.debug('Successfully synced offline data for $key');
            } else {
              // Increment retry count for failed attempts
              await _cacheService.incrementRetryCount(key);
                    Logger.debug('Failed to sync offline data for $key. Status: ${response.statusCode}');
            }
          } catch (e) {
            // Increment retry count for failed attempts
            await _cacheService.incrementRetryCount(key);
                  Logger.debug('Failed to sync offline data for $key: $e');
          }
        }
      }
      
      // Clean up synced data
      await _cacheService.clearSyncedOfflineData();
    } catch (e) {
            Logger.error('Error during offline data sync: $e');
    }
  }

  // Enhanced offline data storage methods
  Future<void> storeOfflinePost(String path, dynamic data, {Map<String, String>? headers}) async {
    final key = 'post_${DateTime.now().millisecondsSinceEpoch}_${path.hashCode}';
    await _cacheService.storeOfflineData(
      key,
      method: 'post',
      path: path,
      data: data,
      headers: headers,
    );
  }
  
  Future<void> storeOfflinePut(String path, dynamic data, {Map<String, String>? headers}) async {
    final key = 'put_${DateTime.now().millisecondsSinceEpoch}_${path.hashCode}';
    await _cacheService.storeOfflineData(
      key,
      method: 'put',
      path: path,
      data: data,
      headers: headers,
    );
  }
  
  Future<void> storeOfflinePatch(String path, dynamic data, {Map<String, String>? headers}) async {
    final key = 'patch_${DateTime.now().millisecondsSinceEpoch}_${path.hashCode}';
    await _cacheService.storeOfflineData(
      key,
      method: 'patch',
      path: path,
      data: data,
      headers: headers,
    );
  }
  
  Future<void> storeOfflineDelete(String path, dynamic data, {Map<String, String>? headers}) async {
    final key = 'delete_${DateTime.now().millisecondsSinceEpoch}_${path.hashCode}';
    await _cacheService.storeOfflineData(
      key,
      method: 'delete',
      path: path,
      data: data,
      headers: headers,
    );
  }

  // Method to clear all cache
  Future<void> clearAllCache() async {
    await _cacheService.clearAllCache();
  }

  // Method to register FCM token with backend
  Future<void> registerFcmToken(String token) async {
    try {
      await _dio.post(
        '/fcm/register-device',
        data: {
          'fcm_token': token,
          'device_type': 'mobile',
        },
      );
    } catch (e) {
      throw Exception('Failed to register FCM token: $e');
    }
  }

  // Language switching method
  Future<Response> setLanguage(String languageCode) async {
    try {
      final response = await _dio.post(
        AppConstants.setLanguage,
        data: {'language': languageCode},
      );
      return response;
    } on DioException catch (e) {
      throw Exception('Failed to set language: ${e.message}');
    }
  }

  // Consultation methods
  Future<List<ConsultationModel>> getConsultations() async {
    try {
      final response = await _dio.get('/consultations');
      if (response.statusCode == 200) {
        final List consultations = response.data;
        return consultations
            .map((json) => ConsultationModel.fromJson(json))
            .toList();
      } else {
        throw ApiException('Failed to load consultations');
      }
    } catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ConsultationModel> getConsultation(int id) async {
    try {
      final response = await _dio.get('/consultations/$id');
      if (response.statusCode == 200) {
        return ConsultationModel.fromJson(response.data);
      } else {
        throw ApiException('Failed to load consultation');
      }
    } catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ConsultationModel> createConsultation(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/consultations', data: data);
      if (response.statusCode == 201) {
        return ConsultationModel.fromJson(response.data);
      } else {
        throw ApiException('Failed to create consultation');
      }
    } catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ConsultationModel> updateConsultation(
      int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch('/consultations/$id', data: data);
      if (response.statusCode == 200) {
        return ConsultationModel.fromJson(response.data);
      } else {
        throw ApiException('Failed to update consultation');
      }
    } catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<ConsultationMessageModel>> getConsultationMessages(
      int consultationId) async {
    try {
      final response = await _dio.get('/consultations/$consultationId/messages/list');
      if (response.statusCode == 200) {
        final List messages = response.data;
        return messages
            .map((json) => ConsultationMessageModel.fromJson(json))
            .toList();
      } else {
        throw ApiException('Failed to load messages');
      }
    } catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ConsultationMessageModel> sendConsultationMessage(
      int consultationId, String message) async {
    try {
      final response = await _dio.post(
        '/consultations/$consultationId/messages',
        data: {'message': message},
      );
      if (response.statusCode == 201) {
        return ConsultationMessageModel.fromJson(response.data);
      } else {
        throw ApiException('Failed to send message');
      }
    } catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<UserModel>> getExperts() async {
    try {
      final response = await _dio.get('/experts');
      if (response.statusCode == 200) {
        final List experts = response.data;
        return experts.map((json) => UserModel.fromJson(json)).toList();
      } else {
        throw ApiException('Failed to load experts');
      }
    } catch (e) {
      throw _handleDioError(e);
    }
  }

  // Error handling
  Exception _handleDioError(Object error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return TimeoutException(
            'Request timeout. Please check your connection.',
          );

        case DioExceptionType.connectionError:
          // Enhanced error message with more specific guidance
          final baseUrl = AppConstants.baseUrl;
          return NetworkException(
            'Cannot connect to server at $baseUrl. Please ensure:\n' '• Django server is running\n' '• Server is accessible at the correct address\n' '• Your internet connection is stable\n' '• Windows Firewall allows connections on port 8000',
          );

        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final message =
              error.response?.data?['message'] ??
              error.response?.data?['detail'] ??
              'Server error';

          switch (statusCode) {
            case 400:
              return BadRequestException(message);
            case 401:
              return UnauthorizedException('Unauthorized access');
            case 403:
              return ForbiddenException('Access forbidden');
            case 404:
              return NotFoundException('Resource not found');
            case 422:
              return ValidationException(
                _parseValidationErrors(error.response?.data),
              );
            case 500:
              return ServerException('Internal server error');
            default:
              return ApiException('HTTP $statusCode: $message');
          }

        case DioExceptionType.cancel:
          return RequestCancelledException('Request was cancelled');

        default:
          return ApiException('Unexpected error: ${error.message}');
      }
    } else {
      // Handle non-DioException errors
      return ApiException('Unexpected error: $error');
    }
  }

  String _parseValidationErrors(dynamic errorData) {
    if (errorData is Map<String, dynamic>) {
      final errors = <String>[];
      errorData.forEach((key, value) {
        if (value is List) {
          errors.addAll(value.map((e) => e.toString()));
        } else {
          errors.add(value.toString());
        }
      });
      return errors.join(', ');
    }
    return errorData?.toString() ?? 'Validation error';
  }

  // Enhanced connectivity testing methods
  Future<bool> checkConnectivity() async {
    try {
      final response = await _dio.get(AppConstants.healthCheck);
      return response.statusCode == 200;
    } catch (e) {
      // Log detailed error information for debugging
      if (e is DioException) {
        Logger.debug('DEBUG: API Error - Status: ${e.response?.statusCode}, '
              'Path: ${e.requestOptions.path}, '
              'Type: ${e.type}, '
              'Message: ${e.message}');
      } else {
        Logger.debug('DEBUG: Non-Dio error: $e');
      }
      return false;
    }
  }

  Future<ServerStatus> getServerStatus() async {
    try {
      final response = await _dio.get(AppConstants.healthCheck);
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return ServerStatus(
          isHealthy: data['status'] == 'healthy',
          message: data['message'] ?? 'Server is running',
          timestamp: data['timestamp'] != null 
              ? DateTime.parse(data['timestamp']) 
              : DateTime.now(),
        );
      } else {
        return ServerStatus(
          isHealthy: false,
          message: 'Server returned status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is DioException) {
        return ServerStatus(
          isHealthy: false,
          message: 'Connection error: ${e.type.toString()}. '
                  'Please ensure the Django server is running at ${AppConstants.baseUrl}',
        );
      } else {
        return ServerStatus(
          isHealthy: false,
          message: 'Unexpected error: $e',
        );
      }
    }
  }

  Future<List<EndpointTestResult>> testBasicEndpoints() async {
    final endpoints = [
      AppConstants.healthCheck,
      AppConstants.login,
      AppConstants.register,
    ];
    
    final results = <EndpointTestResult>[];
    
    for (final endpoint in endpoints) {
      final result = await _testEndpoint(endpoint);
      results.add(result);
    }
    
    return results;
  }
  
  Future<EndpointTestResult> _testEndpoint(String path) async {
    try {
      final response = await _dio.get(path);
      return EndpointTestResult(
        path: path,
        success: response.statusCode == 200,
        statusCode: response.statusCode,
        message: 'Success',
      );
    } catch (e) {
      if (e is DioException) {
        return EndpointTestResult(
          path: path,
          success: false,
          statusCode: e.response?.statusCode,
          message: '${e.type}: ${e.message}',
        );
      } else {
        return EndpointTestResult(
          path: path,
          success: false,
          message: 'Unexpected error: $e',
        );
      }
    }
  }

  // Logging methods (for debugging)
  void _logRequest(RequestOptions options) {
    // Only log in debug mode
    assert(() {
      Logger.debug('🟢 API Request: ${options.method} ${options.uri}');
      if (options.data != null) {
        Logger.debug('📤 Request Data: ${options.data}');
      }
      return true;
    }());
  }

  void _logResponse(Response response) {
    assert(() {
      Logger.debug('🟣 API Response: ${response.statusCode} ${response.requestOptions.uri}');
      return true;
    }());
  }

  void _logError(DioException error) {
    assert(() {
      Logger.debug('🔴 API Error: ${error.type} ${error.requestOptions.uri}');
      Logger.debug('Error Message: ${error.message}');
      if (error.response != null) {
        Logger.debug('Response: ${error.response?.data}');
      }
      return true;
    }());
  }
}

// Custom exception classes
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  NetworkException(super.message);
}

class TimeoutException extends ApiException {
  TimeoutException(super.message);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(super.message);
}

class ForbiddenException extends ApiException {
  ForbiddenException(super.message);
}

class NotFoundException extends ApiException {
  NotFoundException(super.message);
}

class BadRequestException extends ApiException {
  BadRequestException(super.message);
}

class ValidationException extends ApiException {
  ValidationException(super.message);
}

class ServerException extends ApiException {
  ServerException(super.message);
}

class RequestCancelledException extends ApiException {
  RequestCancelledException(super.message);
}

class ServerStatus {
  final bool isHealthy;
  final String message;
  final DateTime? timestamp;

  ServerStatus({
    required this.isHealthy,
    required this.message,
    this.timestamp,
  });
}

class EndpointTestResult {
  final String path;
  final bool success;
  final int? statusCode;
  final String message;

  EndpointTestResult({
    required this.path,
    required this.success,
    this.statusCode,
    required this.message,
  });
}
