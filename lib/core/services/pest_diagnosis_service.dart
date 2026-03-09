import 'dart:io';
import 'dart:math'; // Add this import for min function
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../models/pest_diagnosis_model.dart';
import '../utils/error_handler.dart';
import 'api_service.dart';
import 'async_task_service.dart';
import 'dart:convert';

class PestDiagnosisService {
  final ApiService _apiService = ApiService();
  final AsyncTaskService _asyncTaskService = AsyncTaskService();

  // Synchronous pest diagnosis with image - matching website approach exactly
  Future<DiagnosisServiceResult> diagnosePest({
    required String cropType,
    required String symptoms,
    File? image,
  }) async {
    try {
      final formData = FormData();
      
      // Add form fields exactly as the website does
      formData.fields.add(MapEntry('crop_type', cropType));
      formData.fields.add(MapEntry('symptoms', symptoms));

      // Add image if provided, using the same approach as the website
      if (image != null) {
        // Validate image before adding to form data
        if (!validateImage(image)) {
          return DiagnosisServiceResult.failure('Invalid image file. Please select a valid image (JPG, PNG, WEBP) under 5MB.');
        }
        
        formData.files.add(
          MapEntry(
            'image',
            await MultipartFile.fromFile(
              image.path,
              filename: 'pest_image.jpg',
            ),
          ),
        );
      }

      final response = await _apiService.postMultipart(
        AppConstants.pestDiagnosis,
        formData,
      );

      // Handle successful responses (both 200 and 201)
      if (response.statusCode == 201 || response.statusCode == 200) {
        // Check response data type and parse accordingly
        if (response.data is Map<String, dynamic>) {
          final diagnosis = PestDiagnosisModel.fromJson(response.data);
          return DiagnosisServiceResult.success(
            diagnoses: [diagnosis],
            message: 'Diagnosis completed successfully',
          );
        } else if (response.data is List) {
          final diagnoses = (response.data as List)
              .map((item) => PestDiagnosisModel.fromJson(item))
              .toList();
          return DiagnosisServiceResult.success(
            diagnoses: diagnoses,
            message: 'Diagnosis completed successfully',
          );
        } else {
          // For unexpected response formats, return success without data
          return DiagnosisServiceResult.success(
            message: 'Diagnosis completed successfully',
          );
        }
      }

      // Handle error responses
      return DiagnosisServiceResult.failure(ErrorHandler.formatApiErrorMessage(response.data));
    } on ValidationException catch (e) {
      return DiagnosisServiceResult.failure('Validation error: ${ErrorHandler.formatApiErrorMessage(e.message)}');
    } on ApiException catch (e) {
      // Handle authentication errors specifically
      if (e.message.contains('token') || e.message.contains('Token') || e.message.contains('403')) {
        return DiagnosisServiceResult.failure('Authentication error. Please log in again.');
      }
      return DiagnosisServiceResult.failure('Diagnosis failed: ${ErrorHandler.formatApiErrorMessage(e.message)}');
    } catch (e) {
      return DiagnosisServiceResult.failure(ErrorHandler.handleException(e));
    }
  }

  // Asynchronous pest diagnosis with task tracking - matching website approach exactly
  Future<DiagnosisServiceResult> diagnoseAsync({
    required String cropType,
    required String symptoms,
    File? image,
  }) async {
    try {
      // Create a task in our local tracking system
      final task = await _asyncTaskService.createTask(
        taskType: 'PEST_DIAGNOSIS',
        description: 'Diagnosing $cropType with symptoms: ${symptoms.substring(0, min(symptoms.length, 50))}${symptoms.length > 50 ? '...' : ''}',
      );

      final formData = FormData();
      
      // Add form fields exactly as the website does
      formData.fields.add(MapEntry('crop_type', cropType));
      formData.fields.add(MapEntry('symptoms', symptoms));

      // Add image if provided, using the same approach as the website
      if (image != null) {
        // Validate image before adding to form data
        if (!validateImage(image)) {
          return DiagnosisServiceResult.failure('Invalid image file. Please select a valid image (JPG, PNG, WEBP) under 5MB.');
        }
        
        formData.files.add(
          MapEntry(
            'image',
            await MultipartFile.fromFile(
              image.path,
              filename: 'pest_image.jpg',
            ),
          ),
        );
      }

      final response = await _apiService.postMultipart(
        AppConstants.asyncPestDiagnosis,
        formData,
      );

      if (response.statusCode == 202) {
        final result = DiagnosisResult.fromJson(response.data);
        
        // Update task with the remote task ID
        if (result.taskId != null) {
          await _asyncTaskService.updateTaskStatus(
            taskId: task.id,
            status: 'PROCESSING',
            progress: 0.2,
          );
        }

        return DiagnosisServiceResult.success(
          result: result,
          message: 'Diagnosis task created successfully',
        );
      }

      // Mark task as failed if API call fails
      await _asyncTaskService.updateTaskStatus(
        taskId: task.id,
        status: 'FAILED',
        errorMessage: ErrorHandler.formatApiErrorMessage(response.data),
      );

      return DiagnosisServiceResult.failure(ErrorHandler.formatApiErrorMessage(response.data));
    } on ValidationException catch (e) {
      return DiagnosisServiceResult.failure('Validation error: ${ErrorHandler.formatApiErrorMessage(e.message)}');
    } on ApiException catch (e) {
      // Handle authentication errors specifically
      if (e.message.contains('token') || e.message.contains('Token') || e.message.contains('403')) {
        return DiagnosisServiceResult.failure('Authentication error. Please log in again.');
      }
      return DiagnosisServiceResult.failure('Diagnosis failed: ${ErrorHandler.formatApiErrorMessage(e.message)}');
    } catch (e) {
      return DiagnosisServiceResult.failure(ErrorHandler.handleException(e));
    }
  }

  // Get diagnosis task status
  Future<DiagnosisServiceResult> getTaskStatus(String taskId) async {
    try {
      final response = await _apiService.get('/tasks/$taskId/');

      if (response.statusCode == 200) {
        final result = DiagnosisResult.fromJson(response.data);
        
        // Update our local task tracking
        final localTask = await _asyncTaskService.getTask(taskId);
        if (localTask != null) {
          double progress = 0.2;
          String status = 'PROCESSING';
          
          if (result.isCompleted) {
            progress = 1.0;
            status = 'COMPLETED';
          } else if (result.hasFailed) {
            status = 'FAILED';
          }
          
          await _asyncTaskService.updateTaskStatus(
            taskId: taskId,
            status: status,
            progress: progress,
            resultData: jsonEncode(response.data),
            completedAt: result.isCompleted || result.hasFailed ? DateTime.now() : null,
          );
        }

        return DiagnosisServiceResult.success(
          result: result,
          message: 'Task status retrieved',
        );
      }

      return DiagnosisServiceResult.failure(ErrorHandler.formatApiErrorMessage(response.data));
    } on ApiException catch (e) {
      return DiagnosisServiceResult.failure('Failed to get task status: ${ErrorHandler.formatApiErrorMessage(e.message)}');
    } catch (e) {
      return DiagnosisServiceResult.failure(ErrorHandler.handleException(e));
    }
  }

  // Get user's diagnosis history
  Future<DiagnosisServiceResult> getDiagnosisHistory({
    int page = 1,
    int pageSize = 20,
    bool useCache = false, // Don't cache user-specific data by default
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
        'ordering': '-created_at',
      };

      final response = await _apiService.get(
        AppConstants.pestDiagnosis,
        queryParameters: queryParameters,
        useCache: useCache,
      );

      if (response.statusCode == 200) {
        List<PestDiagnosisModel> diagnoses = [];
        int totalCount = 0;
        bool hasNext = false;
        bool hasPrevious = false;

        // Handle paginated response
        if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          // Paginated format
          if (data['results'] is List) {
            diagnoses = (data['results'] as List)
                .map((json) => PestDiagnosisModel.fromJson(json))
                .toList();
          }
          totalCount = data['count'] is int ? data['count'] as int : 0;
          hasNext = data['next'] != null;
          hasPrevious = data['previous'] != null;
        } else if (response.data is List) {
          // Non-paginated format - direct list of diagnoses
          diagnoses = (response.data as List)
              .map((json) => PestDiagnosisModel.fromJson(json))
              .toList();
          totalCount = diagnoses.length;
        }

        return DiagnosisServiceResult.success(
          diagnoses: diagnoses,
          totalCount: totalCount,
          hasNext: hasNext,
          hasPrevious: hasPrevious,
          message: 'Diagnosis history retrieved',
        );
      }

      return DiagnosisServiceResult.failure(ErrorHandler.formatApiErrorMessage(response.data));
    } on ApiException catch (e) {
      return DiagnosisServiceResult.failure('Failed to fetch diagnosis history: ${ErrorHandler.formatApiErrorMessage(e.message)}');
    } catch (e) {
      return DiagnosisServiceResult.failure(ErrorHandler.handleException(e));
    }
  }

  // Get diagnosis by ID
  Future<DiagnosisServiceResult> getDiagnosis(
    int diagnosisId, {
    bool useCache = true,
  }) async {
    try {
      final response = await _apiService.get(
        '${AppConstants.pestDiagnosis}/$diagnosisId',
        useCache: useCache,
        cacheExpirySeconds: 600, // Cache for 10 minutes
      );

      if (response.statusCode == 200) {
        final diagnosis = PestDiagnosisModel.fromJson(response.data);
        return DiagnosisServiceResult.success(
          diagnoses: [diagnosis],
          message: 'Diagnosis retrieved',
        );
      }

      return DiagnosisServiceResult.failure(ErrorHandler.formatApiErrorMessage(response.data));
    } on ApiException catch (e) {
      return DiagnosisServiceResult.failure('Failed to fetch diagnosis: ${ErrorHandler.formatApiErrorMessage(e.message)}');
    } catch (e) {
      return DiagnosisServiceResult.failure(ErrorHandler.handleException(e));
    }
  }

  // Delete diagnosis
  Future<DiagnosisServiceResult> deleteDiagnosis(int diagnosisId) async {
    try {
      final response = await _apiService.delete(
        '${AppConstants.pestDiagnosis}/$diagnosisId',
      );

      if (response.statusCode == 204) {
        return DiagnosisServiceResult.success(
          diagnoses: [],
          message: 'Diagnosis deleted successfully',
        );
      }

      return DiagnosisServiceResult.failure(ErrorHandler.formatApiErrorMessage(response.data));
    } on ApiException catch (e) {
      return DiagnosisServiceResult.failure('Failed to delete diagnosis: ${ErrorHandler.formatApiErrorMessage(e.message)}');
    } catch (e) {
      return DiagnosisServiceResult.failure(ErrorHandler.handleException(e));
    }
  }

  // Get farming advice based on diagnosis
  Future<DiagnosisServiceResult> getFarmingAdvice({
    required double latitude,
    required double longitude,
    required String cropType,
    required String season,
  }) async {
    try {
      final response = await _apiService.post(
        '/farming-advice',
        data: {
          'lat': latitude,
          'lng': longitude,
          'crop_type': cropType,
          'season': season,
        },
      );

      if (response.statusCode == 200) {
        return DiagnosisServiceResult.success(
          extraData: response.data,
          message: 'Farming advice retrieved',
        );
      }

      return DiagnosisServiceResult.failure(ErrorHandler.formatApiErrorMessage(response.data));
    } on ApiException catch (e) {
      return DiagnosisServiceResult.failure('Failed to get farming advice: ${ErrorHandler.formatApiErrorMessage(e.message)}');
    } catch (e) {
      return DiagnosisServiceResult.failure(ErrorHandler.handleException(e));
    }
  }

  // Get market analysis
  Future<DiagnosisServiceResult> getMarketAnalysis({
    required String cropType,
    required String district,
    required double quantity,
  }) async {
    try {
      final response = await _apiService.post(
        '/market-analysis',
        data: {
          'crop_type': cropType,
          'district': district,
          'quantity': quantity,
        },
      );

      if (response.statusCode == 200) {
        return DiagnosisServiceResult.success(
          extraData: response.data,
          message: 'Market analysis retrieved',
        );
      }

      return DiagnosisServiceResult.failure(ErrorHandler.formatApiErrorMessage(response.data));
    } on ApiException catch (e) {
      return DiagnosisServiceResult.failure('Failed to get market analysis: ${ErrorHandler.formatApiErrorMessage(e.message)}');
    } catch (e) {
      return DiagnosisServiceResult.failure(ErrorHandler.handleException(e));
    }
  }

  // Validate image for diagnosis
  bool validateImage(File image) {
    // Check file size (max 5MB)
    if (image.lengthSync() > AppConstants.maxImageSize) {
      return false;
    }

    // Check file extension
    final extension = image.path.split('.').last.toLowerCase();
    final allowedExtensions = AppConstants.allowedImageTypes.map(
      (e) => e.substring(1),
    );
    return allowedExtensions.contains(extension);
  }

  // Get supported crop types
  List<String> getSupportedCropTypes() {
    return [
      'Maize',
      'Rice',
      'Beans',
      'Tomatoes',
      'Cassava',
      'Sweet Potato',
      'Groundnuts',
      'Soybean',
      'Cotton',
      'Tobacco',
      'Tea',
      'Coffee',
      'Sugarcane',
      'Wheat',
      'Sorghum',
      'Millet',
      'Cabbage',
      'Onions',
      'Peppers',
      'Other',
    ];
  }

  // Get common symptoms for dropdown/suggestions
  List<String> getCommonSymptoms() {
    return [
      'Yellow leaves',
      'Brown spots on leaves',
      'Wilting plants',
      'Stunted growth',
      'Holes in leaves',
      'White powdery coating',
      'Black spots',
      'Curled leaves',
      'Dried leaves',
      'Root rot',
      'Stem borer damage',
      'Aphid infestation',
      'Fungal growth',
      'Bacterial infection',
      'Nutrient deficiency',
    ];
  }
}

// Diagnosis service result wrapper
class DiagnosisServiceResult {
  final bool isSuccess;
  final String message;
  final DiagnosisResult? result;
  final List<PestDiagnosisModel> diagnoses;
  final int totalCount;
  final bool hasNext;
  final bool hasPrevious;
  final Map<String, dynamic>? extraData;

  DiagnosisServiceResult._({
    required this.isSuccess,
    required this.message,
    this.result,
    required this.diagnoses,
    this.totalCount = 0,
    this.hasNext = false,
    this.hasPrevious = false,
    this.extraData,
  });

  factory DiagnosisServiceResult.success({
    DiagnosisResult? result,
    List<PestDiagnosisModel> diagnoses = const [],
    String message = 'Success',
    int totalCount = 0,
    bool hasNext = false,
    bool hasPrevious = false,
    Map<String, dynamic>? extraData,
  }) {
    return DiagnosisServiceResult._(
      isSuccess: true,
      message: message,
      result: result,
      diagnoses: diagnoses,
      totalCount: totalCount,
      hasNext: hasNext,
      hasPrevious: hasPrevious,
      extraData: extraData,
    );
  }

  factory DiagnosisServiceResult.failure(String message) {
    return DiagnosisServiceResult._(
      isSuccess: false,
      message: message,
      diagnoses: [],
    );
  }

  bool get isFailure => !isSuccess;
  bool get hasResult => result != null;
  bool get hasDiagnoses => diagnoses.isNotEmpty || result != null;
  PestDiagnosisModel? get firstDiagnosis =>
      diagnoses.isNotEmpty ? diagnoses.first : null;

  @override
  String toString() {
    return 'DiagnosisServiceResult(isSuccess: $isSuccess, message: $message, hasResult: $hasResult, diagnosesCount: ${diagnoses.length})';
  }
}