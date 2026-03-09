import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/token_handler.dart';
import '../utils/logger.dart';

class ApiClient {
  static const String _baseUrl = 'https://mlimi.cloud';
  
  /// Make an authenticated API call with automatic token refresh
  static Future<http.Response> authenticatedGet(String endpoint) async {
    return _makeAuthenticatedRequest('GET', endpoint);
  }
  
  /// Make an authenticated POST API call with automatic token refresh
  static Future<http.Response> authenticatedPost(
    String endpoint, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    return _makeAuthenticatedRequest(
      'POST', 
      endpoint, 
      body: body, 
      additionalHeaders: headers,
    );
  }
  
  /// Make an authenticated PUT API call with automatic token refresh
  static Future<http.Response> authenticatedPut(
    String endpoint, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    return _makeAuthenticatedRequest(
      'PUT', 
      endpoint, 
      body: body, 
      additionalHeaders: headers,
    );
  }
  
  /// Make an authenticated DELETE API call with automatic token refresh
  static Future<http.Response> authenticatedDelete(String endpoint) async {
    return _makeAuthenticatedRequest('DELETE', endpoint);
  }
  
  /// Private method to make authenticated requests with token refresh logic
  static Future<http.Response> _makeAuthenticatedRequest(
    String method,
    String endpoint, {
    Object? body,
    Map<String, String>? additionalHeaders,
  }) async {
    try {
      // Get current access token
      String? accessToken = await TokenHandler.getAccessToken();
      
      if (accessToken == null) {
        // No access token available, throw an exception
        throw Exception('No access token available. Please log in.');
      }
      
      // Prepare headers
      final Map<String, String> headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        ...?additionalHeaders,
      };
      
      // Prepare URL
      final Uri url = Uri.parse('$_baseUrl$endpoint');
      
      // Make initial request
      late http.Response response;
      
      switch (method) {
        case 'GET':
          response = await http.get(url, headers: headers);
          break;
        case 'POST':
          response = await http.post(url, headers: headers, body: jsonEncode(body));
          break;
        case 'PUT':
          response = await http.put(url, headers: headers, body: jsonEncode(body));
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }
      
      // If unauthorized, try to refresh token
      if (response.statusCode == 401) {
        Logger.info('Received 401 Unauthorized, attempting token refresh...');
        
        try {
          // Try to refresh the access token
          final newTokens = await TokenHandler.refreshAccessToken();
          
          if (newTokens != null) {
            // Successfully refreshed tokens
            Logger.info('Token refresh successful, retrying request...');
            
            // Update the authorization header with new access token
            headers['Authorization'] = 'Bearer ${newTokens['access']}';
            
            // Retry the original request with new token
            switch (method) {
              case 'GET':
                response = await http.get(url, headers: headers);
                break;
              case 'POST':
                response = await http.post(url, headers: headers, body: jsonEncode(body));
                break;
              case 'PUT':
                response = await http.put(url, headers: headers, body: jsonEncode(body));
                break;
              case 'DELETE':
                response = await http.delete(url, headers: headers);
                break;
            }
          } else {
            // Token refresh failed - user needs to log in again
            Logger.warn('Token refresh failed. User needs to log in again.');
            throw Exception('Session expired. Please log in again.');
          }
        } catch (refreshError) {
          // Handle errors during token refresh
          Logger.error('Error during token refresh: $refreshError');
          throw Exception('Authentication failed. Please log in again.');
        }
      }
      
      return response;
    } catch (e) {
      // Handle network errors and other exceptions
      Logger.error('Error making authenticated request: $e');
      rethrow;
    }
  }
  
  /// Make an unauthenticated API call (for login, registration, etc.)
  static Future<http.Response> publicPost(
    String endpoint, {
    Object? body,
  }) async {
    try {
      final Uri url = Uri.parse('$_baseUrl$endpoint');
      final headers = {'Content-Type': 'application/json'};
      
      return await http.post(url, headers: headers, body: jsonEncode(body));
    } catch (e) {
      // Handle network errors and other exceptions
      Logger.error('Error making public POST request: $e');
      rethrow;
    }
  }
}