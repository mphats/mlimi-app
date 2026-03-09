import '../constants/app_constants.dart';

class ImageUrlProcessor {
  /// Process image URLs to ensure they are absolute URLs
  static String processImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return '';
    }

    // If it's already an absolute URL, return as is
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }

    // If it's a relative URL, prepend the base URL
    if (imageUrl.startsWith('/')) {
      // Ensure there's no double slash when concatenating
      final baseUrl = AppConstants.baseUrl.endsWith('/') 
          ? AppConstants.baseUrl.substring(0, AppConstants.baseUrl.length - 1) 
          : AppConstants.baseUrl;
      return '$baseUrl$imageUrl';
    }

    // For any other case, return as is
    return imageUrl;
  }

  /// Validate if a URL is properly formatted
  static bool isValidUrl(String url) {
    if (url.isEmpty) return false;
    
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }
}