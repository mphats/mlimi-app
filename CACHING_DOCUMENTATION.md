# Caching Implementation Documentation

## Overview
This document explains the caching implementation in the Mlimi Flutter application. The caching system is designed to improve performance, reduce network usage, and provide a better user experience by storing API responses locally.

## Architecture

### Cache Service
The core of the caching system is the `CacheService` class which uses `shared_preferences` to store data locally.

Key features:
- Automatic expiration of cached data (5-15 minutes depending on data type)
- Automatic cache key generation based on endpoint and parameters
- Easy cache clearing mechanisms

### API Service Integration
The `ApiService` has been enhanced to support caching for GET requests:
- `useCache` parameter to enable/disable caching per request
- `cacheExpirySeconds` parameter to set custom expiration times
- Automatic cache clearing for POST/PUT/PATCH/DELETE requests

### Service Layer
All service classes have been updated to use caching for read operations:
- Products: Cached for 5 minutes
- Community posts: Cached for 5 minutes
- Weather data: Cached for 15 minutes
- Market prices: Cached for 5 minutes
- Newsletters: Cached for 10 minutes
- Pest diagnoses: Cached for 10 minutes

## Implementation Details

### Cache Key Generation
Cache keys are generated using the endpoint and query parameters:
```dart
String generateCacheKey(String endpoint, [Map<String, dynamic>? params]) {
  final buffer = StringBuffer('cache_$endpoint');
  if (params != null) {
    params..removeWhere((key, value) => value == null);
    final sortedParams = Map.fromEntries(params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
    buffer.write('?');
    buffer.write(sortedParams.entries.map((e) => '${e.key}=${e.value}').join('&'));
  }
  return buffer.toString();
}
```

### Cache Expiration
Cached data automatically expires based on the `cacheExpirySeconds` parameter:
```dart
Future<void> cacheResponse(String key, dynamic data, {int expirySeconds = 300}) async {
  final expiry = DateTime.now().add(Duration(seconds: expirySeconds)).millisecondsSinceEpoch;
  final cacheData = {
    'data': data,
    'expiry': expiry,
  };
  await _prefs.setString(key, jsonEncode(cacheData));
}
```

### Cache Retrieval
When retrieving cached data, the system checks for expiration:
```dart
Future<dynamic> getCachedResponse(String key) async {
  final cached = _prefs.getString(key);
  if (cached == null) return null;

  try {
    final decoded = jsonDecode(cached);
    final expiry = decoded['expiry'];
    
    // Check if cache has expired
    if (DateTime.now().millisecondsSinceEpoch > expiry) {
      await _prefs.remove(key);
      return null;
    }
    
    return decoded['data'];
  } catch (e) {
    // If there's an error parsing, remove the invalid cache
    await _prefs.remove(key);
    return null;
  }
}
```

## Usage Examples

### Using Cache in Service Methods
```dart
Future<ProductResult> getProducts({
  String? category,
  String? location,
  String? search,
  int page = 1,
  int pageSize = 20,
  bool useCache = true,
}) async {
  try {
    final queryParameters = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };

    // Add filters
    if (category != null && category.isNotEmpty) {
      queryParameters['category'] = category;
    }

    final response = await _apiService.get(
      AppConstants.products,
      queryParameters: queryParameters,
      useCache: useCache,
      cacheExpirySeconds: 300, // 5 minutes
    );

    // Process response...
  } catch (e) {
    // Handle errors...
  }
}
```

### Clearing Cache
```dart
// Clear all cache
await CacheService().clearAllCache();

// Clear specific cache entry
await CacheService().clearCache('cache_/api/v1/products?page=1&page_size=20');
```

## Cache Management

### Service Manager
The `ServiceManager` class provides a centralized way to manage all services and their cached data:
- Load all dashboard data with caching in parallel
- Refresh all data (bypassing cache)
- Clear all cached data

### Cache Statistics Screen
A dedicated screen shows cache usage statistics and allows manual cache clearing.

## Benefits

1. **Performance**: Cached data loads instantly, improving user experience
2. **Offline Access**: Users can access recently viewed data without internet
3. **Data Usage**: Reduced network requests mean less data consumption
4. **Battery Life**: Fewer network requests result in better battery performance
5. **User Experience**: Smoother scrolling and navigation

## Best Practices

1. **Cache Appropriate Data**: Only cache data that doesn't change frequently
2. **Set Appropriate Expiry Times**: Use shorter times for volatile data
3. **Clear Cache on Data Changes**: Always clear cache when posting/updating data
4. **Handle Cache Misses Gracefully**: Always have a fallback to fetch fresh data
5. **Monitor Cache Size**: Keep an eye on cache growth to prevent storage issues

## Troubleshooting

### Cache Not Working
1. Ensure `useCache: true` is set in API calls
2. Check that the cache expiry time is appropriate
3. Verify that the device has sufficient storage space

### Stale Data
1. Reduce cache expiry times for frequently changing data
2. Implement manual refresh mechanisms
3. Clear cache when users perform data-modifying operations

### Cache Size Issues
1. Monitor cache size regularly
2. Implement cache size limits if needed
3. Consider more aggressive cache clearing strategies