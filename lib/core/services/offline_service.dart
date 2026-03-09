import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineService {
  static const String _weatherDataKey = 'offline_weather_data';
  static const String _marketPricesKey = 'offline_market_prices';
  static const String _diagnosisHistoryKey = 'offline_diagnosis_history';
  static const String _lastUpdatedKey = 'last_updated';

  // Save weather data for offline use
  static Future<void> saveWeatherData(List<Map<String, dynamic>> data) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(data);
    await prefs.setString(_weatherDataKey, encodedData);
    await prefs.setString(_lastUpdatedKey, DateTime.now().toIso8601String());
  }

  // Get saved weather data
  static Future<List<Map<String, dynamic>>?> getWeatherData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString(_weatherDataKey);
    
    if (encodedData != null) {
      final List<dynamic> data = jsonDecode(encodedData);
      return data.cast<Map<String, dynamic>>();
    }
    
    return null;
  }

  // Save market prices for offline use
  static Future<void> saveMarketPrices(List<Map<String, dynamic>> data) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(data);
    await prefs.setString(_marketPricesKey, encodedData);
    await prefs.setString(_lastUpdatedKey, DateTime.now().toIso8601String());
  }

  // Get saved market prices
  static Future<List<Map<String, dynamic>>?> getMarketPrices() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString(_marketPricesKey);
    
    if (encodedData != null) {
      final List<dynamic> data = jsonDecode(encodedData);
      return data.cast<Map<String, dynamic>>();
    }
    
    return null;
  }

  // Save diagnosis history for offline use
  static Future<void> saveDiagnosisHistory(List<Map<String, dynamic>> data) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(data);
    await prefs.setString(_diagnosisHistoryKey, encodedData);
    await prefs.setString(_lastUpdatedKey, DateTime.now().toIso8601String());
  }

  // Get saved diagnosis history
  static Future<List<Map<String, dynamic>>?> getDiagnosisHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString(_diagnosisHistoryKey);
    
    if (encodedData != null) {
      final List<dynamic> data = jsonDecode(encodedData);
      return data.cast<Map<String, dynamic>>();
    }
    
    return null;
  }

  // Check if offline data is recent (less than 24 hours old)
  static Future<bool> isDataRecent() async {
    final prefs = await SharedPreferences.getInstance();
    final String? lastUpdated = prefs.getString(_lastUpdatedKey);
    
    if (lastUpdated != null) {
      final DateTime lastUpdate = DateTime.parse(lastUpdated);
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(lastUpdate);
      
      // Data is recent if less than 24 hours old
      return difference.inHours < 24;
    }
    
    return false;
  }

  // Clear all offline data
  static Future<void> clearOfflineData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_weatherDataKey);
    await prefs.remove(_marketPricesKey);
    await prefs.remove(_diagnosisHistoryKey);
    await prefs.remove(_lastUpdatedKey);
  }
}