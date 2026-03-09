import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import 'logger.dart';

class TokenHandler {
  static const String _baseUrl = 'https://mlimi.cloud';
  static const String _tokenRefreshEndpoint = '/api/v1/auth/token/refresh/';
  static final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  /// Safely refresh access token, handling expired tokens gracefully
  static Future<Map<String, dynamic>?> refreshAccessToken() async {
    try {
      // Get refresh token from secure storage
      final refreshToken = await _secureStorage.read(key: AppConstants.refreshTokenKey);
      
      if (refreshToken == null || refreshToken.isEmpty) {
        // No refresh token available
        return null;
      }
      
      // Attempt to refresh the token
      final response = await http.post(
        Uri.parse('$_baseUrl$_tokenRefreshEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      );
      
      if (response.statusCode == 200) {
        // Success - return new tokens
        final data = jsonDecode(response.body);
        return {
          'access': data['access'],
          'refresh': data['refresh'], // In case it was rotated
        };
      } else if (response.statusCode == 401) {
        // Token refresh failed - likely expired refresh token
        // Try to parse error response
        try {
          final errorData = jsonDecode(response.body);
          
          // Check if it's specifically a token expiration error
          if (errorData['code'] == 'token_not_valid' && 
              (errorData['detail'] as String?)?.toLowerCase().contains('expired') == true) {
            // Refresh token has expired - user needs to log in again
            Logger.warn('Token has expired. Please log in again.');
            if (errorData.containsKey('exception_message')) {
              Logger.info('Exception message: ${errorData['exception_message']}');
            }
            if (errorData.containsKey('recommendation')) {
              Logger.info('Recommendation: ${errorData['recommendation']}');
            }
          } else {
            // Other token error
            Logger.error('Token refresh failed: $errorData');
          }
        } catch (parseError) {
          // If we can't parse the error response, just log the status code
          Logger.error('Token refresh failed with status ${response.statusCode}: ${response.body}');
        }
        
        // Clear stored tokens
        await clearTokens();
        return null;
      } else {
        // Unexpected error
        Logger.error('Unexpected error during token refresh: ${response.statusCode} - ${response.body}');
        // For non-401 errors, don't clear tokens immediately, let the app retry
        return null;
      }
    } catch (error) {
      Logger.error('Exception during token refresh: $error');
      // Network errors or other exceptions - don't clear tokens, let the app retry
      return null;
    }
  }
  
  /// Clear all stored tokens
  static Future<void> clearTokens() async {
    await _secureStorage.delete(key: AppConstants.accessTokenKey);
    await _secureStorage.delete(key: AppConstants.refreshTokenKey);
  }
  
  /// Store tokens securely
  static Future<void> storeTokens(String accessToken, String refreshToken) async {
    await _secureStorage.write(key: AppConstants.accessTokenKey, value: accessToken);
    await _secureStorage.write(key: AppConstants.refreshTokenKey, value: refreshToken);
  }
  
  /// Get access token from storage
  static Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: AppConstants.accessTokenKey);
  }
  
  /// Get refresh token from storage
  static Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: AppConstants.refreshTokenKey);
  }
  
  /// Check if tokens exist
  static Future<bool> hasTokens() async {
    final accessToken = await _secureStorage.read(key: AppConstants.accessTokenKey);
    final refreshToken = await _secureStorage.read(key: AppConstants.refreshTokenKey);
    return accessToken != null && refreshToken != null;
  }
}