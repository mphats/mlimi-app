import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Cache API response
  Future<void> cacheResponse(
    String key,
    dynamic data, {
    int expirySeconds = 300,
  }) async {
    final expiry = DateTime.now()
        .add(Duration(seconds: expirySeconds))
        .millisecondsSinceEpoch;
    final cacheData = {'data': data, 'expiry': expiry};
    await _prefs.setString(key, jsonEncode(cacheData));
  }

  // Get cached response
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

  // Clear specific cache
  Future<void> clearCache(String key) async {
    await _prefs.remove(key);
  }

  // Clear all cache
  Future<void> clearAllCache() async {
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('cache_')) {
        await _prefs.remove(key);
      }
    }
  }

  // Generate cache key from endpoint and parameters
  String generateCacheKey(String endpoint, [Map<String, dynamic>? params]) {
    final buffer = StringBuffer('cache_$endpoint');
    if (params != null) {
      params.removeWhere((key, value) => value == null);
      final sortedParams = Map.fromEntries(
        params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
      );
      buffer.write('?');
      buffer.write(
        sortedParams.entries.map((e) => '${e.key}=${e.value}').join('&'),
      );
    }
    return buffer.toString();
  }
  
  // Offline data storage methods
  
  // Store data for offline use with request details
  Future<void> storeOfflineData(String key, {
    required String method,
    required String path,
    dynamic data,
    Map<String, String>? headers,
  }) async {
    final offlineData = {
      'method': method,
      'path': path,
      'data': data,
      'headers': headers,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'synced': false,
      'retryCount': 0,
    };
    await _prefs.setString('offline_$key', jsonEncode(offlineData));
  }
  
  // Get offline data
  Future<dynamic> getOfflineData(String key) async {
    final offline = _prefs.getString('offline_$key');
    if (offline == null) return null;
    
    try {
      final decoded = jsonDecode(offline);
      return decoded['data'];
    } catch (e) {
      await _prefs.remove('offline_$key');
      return null;
    }
  }
  
  // Mark offline data as synced
  Future<void> markAsSynced(String key) async {
    final offline = _prefs.getString('offline_$key');
    if (offline == null) return;
    
    try {
      final decoded = jsonDecode(offline);
      decoded['synced'] = true;
      await _prefs.setString('offline_$key', jsonEncode(decoded));
    } catch (e) {
      // Ignore errors
    }
  }
  
  // Increment retry count for failed sync attempts
  Future<void> incrementRetryCount(String key) async {
    final offline = _prefs.getString('offline_$key');
    if (offline == null) return;
    
    try {
      final decoded = jsonDecode(offline);
      decoded['retryCount'] = (decoded['retryCount'] as int) + 1;
      await _prefs.setString('offline_$key', jsonEncode(decoded));
    } catch (e) {
      // Ignore errors
    }
  }
  
  // Get retry count for an offline request
  Future<int> getRetryCount(String key) async {
    final offline = _prefs.getString('offline_$key');
    if (offline == null) return 0;
    
    try {
      final decoded = jsonDecode(offline);
      return decoded['retryCount'] as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }
  
  // Get all unsynced offline data with full request details
  Future<Map<String, dynamic>> getUnsyncedData() async {
    final unsynced = <String, dynamic>{};
    final keys = _prefs.getKeys();
    
    for (final key in keys) {
      if (key.startsWith('offline_')) {
        final data = _prefs.getString(key);
        if (data != null) {
          try {
            final decoded = jsonDecode(data);
            if (decoded is Map && decoded['synced'] == false) {
              final originalKey = key.substring(8); // Remove 'offline_' prefix
              unsynced[originalKey] = decoded;
            }
          } catch (e) {
            // Ignore invalid data
          }
        }
      }
    }
    
    return unsynced;
  }
  
  // Clear synced offline data
  Future<void> clearSyncedOfflineData() async {
    final keys = _prefs.getKeys();
    
    for (final key in keys) {
      if (key.startsWith('offline_')) {
        final data = _prefs.getString(key);
        if (data != null) {
          try {
            final decoded = jsonDecode(data);
            if (decoded is Map && decoded['synced'] == true) {
              await _prefs.remove(key);
            }
          } catch (e) {
            // Remove invalid data
            await _prefs.remove(key);
          }
        }
      }
    }
  }
  
  // Get all offline data for display/debugging
  Future<List<Map<String, dynamic>>> getAllOfflineData() async {
    final allData = <Map<String, dynamic>>[];
    final keys = _prefs.getKeys();
    
    for (final key in keys) {
      if (key.startsWith('offline_')) {
        final data = _prefs.getString(key);
        if (data != null) {
          try {
            final decoded = jsonDecode(data) as Map<String, dynamic>;
            final originalKey = key.substring(8); // Remove 'offline_' prefix
            decoded['key'] = originalKey;
            allData.add(decoded);
          } catch (e) {
            // Ignore invalid data
          }
        }
      }
    }
    
    return allData;
  }
}