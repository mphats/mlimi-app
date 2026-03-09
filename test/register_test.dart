import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mulimi/core/constants/app_constants.dart';

void main() {
  group('Registration API Tests', () {
    test('Register endpoint should be accessible without trailing slash', () async {
      // Test the exact URL that the Flutter app will use
      final url = Uri.parse('${AppConstants.apiAuth}/register');
      
      // Print the URL for debugging
      debugPrint('Testing registration URL: $url');
      
      // Verify the URL format is correct
      expect(url.path, '/api/v1/auth/register');
      expect(url.path, isNot('/api/v1/auth/register/'));
    });

    // This test would require a running server, so it's commented out for now
    /*
    test('Register endpoint should accept POST requests', () async {
      final url = Uri.parse('${AppConstants.apiAuth}/register');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': 'testuser',
          'email': 'test@example.com',
          'password': 'testpassword123',
          'role': 'FARMER'
        }),
      );
      
      // We expect either 201 (created) or 400 (bad request) but not 404
      expect(response.statusCode, isNot(404));
    });
    */
  });
}