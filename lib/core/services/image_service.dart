import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';

class ImageService {
  final ApiService _apiService = ApiService();

  /// Upload profile image
  Future<ImageUploadResult> uploadProfileImage(File imageFile) async {
    try {
      // Create FormData for multipart upload
      final formData = FormData.fromMap({
        'profile_image': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'profile_image${imageFile.path.substring(imageFile.path.lastIndexOf('.'))}',
        ),
      });

      final response = await _apiService.postMultipart(
        AppConstants.profileImageUpload,
        formData,
      );

      // Add logging to see the actual response structure
      debugPrint('Profile image upload response status: ${response.statusCode}');
      debugPrint('Profile image upload response data type: ${response.data.runtimeType}');
      debugPrint('Profile image upload response data: $response.data');

      if (response.statusCode == 200) {
        // Add comprehensive type checking for response data
        final data = response.data;
        
        // Validate that data is a Map before accessing its properties
        if (data is Map<String, dynamic>) {
          if (data['status'] == 'success') {
            // Ensure imageUrl is a String before using it
            final imageUrl = data['profile_image_url'];
            if (imageUrl is String) {
              // Verify the image URL is not empty
              if (imageUrl.isNotEmpty) {
                return ImageUploadResult.success(
                  message: data['message'] is String ? data['message'] : 'Profile image uploaded successfully',
                  imageUrl: imageUrl,
                );
              } else {
                return ImageUploadResult.failure(
                  message: 'Empty image URL returned from server',
                );
              }
            } else {
              return ImageUploadResult.failure(
                message: 'Invalid image URL format in response',
              );
            }
          } else {
            return ImageUploadResult.failure(
              message: data['message'] is String ? data['message'] : 'Failed to upload profile image',
            );
          }
        } else {
          // Additional logging for debugging
          debugPrint('Expected Map<String, dynamic> but got: ${data.runtimeType}');
          if (data is List) {
            debugPrint('List data length: ${data.length}');
          }
          return ImageUploadResult.failure(
            message: 'Invalid response format from server',
          );
        }
      } else {
        return ImageUploadResult.failure(
          message: 'Failed to upload profile image',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error in uploadProfileImage: $e');
      debugPrint('Stack trace: $stackTrace');
      return ImageUploadResult.failure(
        message: 'Error uploading profile image: $e',
      );
    }
  }

  /// Upload cover image
  Future<ImageUploadResult> uploadCoverImage(File imageFile) async {
    try {
      // Create FormData for multipart upload
      final formData = FormData.fromMap({
        'cover_image': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'cover_image${imageFile.path.substring(imageFile.path.lastIndexOf('.'))}',
        ),
      });

      final response = await _apiService.postMultipart(
        AppConstants.coverImageUpload,
        formData,
      );

      // Add logging to see the actual response structure
      debugPrint('Cover image upload response status: ${response.statusCode}');
      debugPrint('Cover image upload response data type: ${response.data.runtimeType}');
      debugPrint('Cover image upload response data: $response.data');

      if (response.statusCode == 200) {
        // Add comprehensive type checking for response data
        final data = response.data;
        
        // Validate that data is a Map before accessing its properties
        if (data is Map<String, dynamic>) {
          if (data['status'] == 'success') {
            // Ensure imageUrl is a String before using it
            final imageUrl = data['cover_image_url'];
            if (imageUrl is String) {
              // Verify the image URL is not empty
              if (imageUrl.isNotEmpty) {
                return ImageUploadResult.success(
                  message: data['message'] is String ? data['message'] : 'Cover image uploaded successfully',
                  imageUrl: imageUrl,
                );
              } else {
                return ImageUploadResult.failure(
                  message: 'Empty image URL returned from server',
                );
              }
            } else {
              return ImageUploadResult.failure(
                message: 'Invalid image URL format in response',
              );
            }
          } else {
            return ImageUploadResult.failure(
              message: data['message'] is String ? data['message'] : 'Failed to upload cover image',
            );
          }
        } else {
          // Additional logging for debugging
          debugPrint('Expected Map<String, dynamic> but got: ${data.runtimeType}');
          if (data is List) {
            debugPrint('List data length: ${data.length}');
          }
          return ImageUploadResult.failure(
            message: 'Invalid response format from server',
          );
        }
      } else {
        return ImageUploadResult.failure(
          message: 'Failed to upload cover image',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error in uploadCoverImage: $e');
      debugPrint('Stack trace: $stackTrace');
      return ImageUploadResult.failure(
        message: 'Error uploading cover image: $e',
      );
    }
  }

  /// Get profile images
  Future<ImageUrlsResult> getProfileImages() async {
    try {
      final response = await _apiService.get(AppConstants.profileImages);

      // Add logging to see the actual response structure
      debugPrint('Get profile images response status: ${response.statusCode}');
      debugPrint('Get profile images response data type: ${response.data.runtimeType}');
      debugPrint('Get profile images response data: $response.data');

      if (response.statusCode == 200) {
        final data = response.data;
        
        // Validate that data is a Map before accessing its properties
        if (data is Map<String, dynamic>) {
          // Use null-aware operators to safely access image URLs
          final profileImageUrl = data['profile_image_url'] is String ? data['profile_image_url'] : null;
          final coverImageUrl = data['cover_image_url'] is String ? data['cover_image_url'] : null;
          
          return ImageUrlsResult.success(
            profileImageUrl: profileImageUrl,
            coverImageUrl: coverImageUrl,
          );
        } else {
          // Additional logging for debugging
          debugPrint('Expected Map<String, dynamic> but got: ${data.runtimeType}');
          if (data is List) {
            debugPrint('List data length: ${data.length}');
          }
          return ImageUrlsResult.failure(
            message: 'Invalid response format from server',
          );
        }
      } else {
        return ImageUrlsResult.failure(
          message: 'Failed to get profile images',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error in getProfileImages: $e');
      debugPrint('Stack trace: $stackTrace');
      return ImageUrlsResult.failure(
        message: 'Error getting profile images: $e',
      );
    }
  }
}

/// Result class for image upload operations
class ImageUploadResult {
  final bool isSuccess;
  final String message;
  final String? imageUrl;

  ImageUploadResult._({
    required this.isSuccess,
    required this.message,
    this.imageUrl,
  });

  factory ImageUploadResult.success({
    required String message,
    String? imageUrl,
  }) {
    return ImageUploadResult._(
      isSuccess: true,
      message: message,
      imageUrl: imageUrl,
    );
  }

  factory ImageUploadResult.failure({
    required String message,
  }) {
    return ImageUploadResult._(
      isSuccess: false,
      message: message,
    );
  }

  bool get isFailure => !isSuccess;
}

/// Result class for getting image URLs
class ImageUrlsResult {
  final bool isSuccess;
  final String message;
  final String? profileImageUrl;
  final String? coverImageUrl;

  ImageUrlsResult._({
    required this.isSuccess,
    required this.message,
    this.profileImageUrl,
    this.coverImageUrl,
  });

  factory ImageUrlsResult.success({
    String? profileImageUrl,
    String? coverImageUrl,
  }) {
    return ImageUrlsResult._(
      isSuccess: true,
      message: 'Images retrieved successfully',
      profileImageUrl: profileImageUrl,
      coverImageUrl: coverImageUrl,
    );
  }

  factory ImageUrlsResult.failure({
    required String message,
  }) {
    return ImageUrlsResult._(
      isSuccess: false,
      message: message,
    );
  }

  bool get isFailure => !isSuccess;
}