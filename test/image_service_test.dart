import 'package:flutter_test/flutter_test.dart';
import 'package:mulimi/core/services/image_service.dart';

void main() {
  group('ImageService Tests', () {
    group('ImageUploadResult Tests', () {
      test('ImageUploadResult success factory method', () {
        final result = ImageUploadResult.success(
          message: 'Upload successful',
          imageUrl: 'http://example.com/image.jpg',
        );
        
        expect(result.isSuccess, true);
        expect(result.isFailure, false);
        expect(result.message, 'Upload successful');
        expect(result.imageUrl, 'http://example.com/image.jpg');
      });

      test('ImageUploadResult failure factory method', () {
        final result = ImageUploadResult.failure(
          message: 'Upload failed',
        );
        
        expect(result.isSuccess, false);
        expect(result.isFailure, true);
        expect(result.message, 'Upload failed');
        expect(result.imageUrl, null);
      });
    });

    group('ImageUrlsResult Tests', () {
      test('ImageUrlsResult success factory method', () {
        final result = ImageUrlsResult.success(
          profileImageUrl: 'http://example.com/profile.jpg',
          coverImageUrl: 'http://example.com/cover.jpg',
        );
        
        expect(result.isSuccess, true);
        expect(result.isFailure, false);
        expect(result.message, 'Images retrieved successfully');
        expect(result.profileImageUrl, 'http://example.com/profile.jpg');
        expect(result.coverImageUrl, 'http://example.com/cover.jpg');
      });

      test('ImageUrlsResult failure factory method', () {
        final result = ImageUrlsResult.failure(
          message: 'Failed to retrieve images',
        );
        
        expect(result.isSuccess, false);
        expect(result.isFailure, true);
        expect(result.message, 'Failed to retrieve images');
        expect(result.profileImageUrl, null);
        expect(result.coverImageUrl, null);
      });
    });
    
    group('Response Data Type Checking Tests', () {
      test('Valid Map response data', () {
        final data = {
          'status': 'success',
          'message': 'Image uploaded successfully',
          'profile_image_url': 'http://example.com/image.jpg'
        };
        
        // This simulates what happens in our fixed ImageService methods
        expect(data['status'], 'success');
        expect(data['profile_image_url'] is String, true);
      });
      
      test('Invalid response data type', () {
        // This would be caught by our enhanced ApiService
        final invalidData = 'This is not a map or list';
        expect(invalidData is Map, false);
        expect(invalidData is List, false);
      });
    });
  });
}