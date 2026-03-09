import '../services/cache_service.dart';

class CacheUtils {
  static final CacheService _cacheService = CacheService();

  // Clear all cache
  static Future<void> clearAllCache() async {
    await _cacheService.clearAllCache();
  }

  // Clear specific cache by key
  static Future<void> clearCache(String key) async {
    await _cacheService.clearCache(key);
  }

  // Clear cache for a specific endpoint
  static Future<void> clearEndpointCache(String endpoint) async {
    final cacheKey = _cacheService.generateCacheKey(endpoint);
    await _cacheService.clearCache(cacheKey);
  }

  // Get cache size (approximate)
  static Future<int> getCacheSize() async {
    // This is a simplified implementation
    // In a real app, you might want to calculate actual cache size
    return 0;
  }

  // Check if cache is enabled
  static bool isCacheEnabled() {
    // You can implement logic to enable/disable cache based on app settings
    return true;
  }
}
