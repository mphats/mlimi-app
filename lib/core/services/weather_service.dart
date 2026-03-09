import '../constants/app_constants.dart';
import '../models/weather_model.dart';
import 'api_service.dart';

class WeatherService {
  final ApiService _apiService = ApiService();

  // Get current weather data
  Future<WeatherResult> getCurrentWeather({
    String? location,
    double? latitude,
    double? longitude,
    bool useCache = true,
  }) async {
    try {
      final queryParameters = <String, dynamic>{};

      // Only add non-null, non-empty parameters
      if (location != null && location.isNotEmpty) {
        queryParameters['location'] = location;
      } else if (latitude != null && longitude != null) {
        queryParameters['lat'] = latitude;
        queryParameters['lon'] = longitude;
      }

      final response = await _apiService.get(
        AppConstants.weather,
        queryParameters: queryParameters,
        useCache: useCache,
        cacheExpirySeconds:
            900, // Cache for 15 minutes (weather doesn't change frequently)
      );

      if (response.statusCode == 200) {
        final weather = WeatherModel.fromJson(response.data);
        return WeatherResult.success(weather: weather);
      }

      return WeatherResult.failure('Failed to fetch weather data');
    } on ApiException catch (e) {
      return WeatherResult.failure(
        'Failed to fetch weather data: ${e.message}',
      );
    } catch (e) {
      return WeatherResult.failure(
        'Failed to fetch weather data: ${e.toString()}',
      );
    }
  }

  // Get weather forecast
  Future<WeatherResult> getWeatherForecast({
    String? location,
    double? latitude,
    double? longitude,
    int days = 7,
    bool useCache = true,
  }) async {
    try {
      final queryParameters = <String, dynamic>{'days': days};

      // Only add non-null, non-empty parameters
      if (location != null && location.isNotEmpty) {
        queryParameters['location'] = location;
      } else if (latitude != null && longitude != null) {
        queryParameters['lat'] = latitude;
        queryParameters['lon'] = longitude;
      }

      final response = await _apiService.get(
        AppConstants.weather,
        queryParameters: queryParameters,
        useCache: useCache,
        cacheExpirySeconds: 1800, // Cache for 30 minutes
      );

      if (response.statusCode == 200) {
        // Handle both single weather object and list of forecasts
        if (response.data is List) {
          final forecast = (response.data as List)
              .map((json) => WeatherModel.fromJson(json))
              .toList();
          return WeatherResult.success(forecast: forecast);
        } else {
          // Single weather object
          final weather = WeatherModel.fromJson(response.data);
          return WeatherResult.success(weather: weather);
        }
      }

      return WeatherResult.failure('Failed to fetch weather forecast');
    } on ApiException catch (e) {
      return WeatherResult.failure(
        'Failed to fetch weather forecast: ${e.message}',
      );
    } catch (e) {
      return WeatherResult.failure(
        'Failed to fetch weather forecast: ${e.toString()}',
      );
    }
  }
  
  // Get NASA GIBS warnings for weather patterns
  Future<List<WeatherWarning>> getWeatherWarnings({
    String? location,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final queryParameters = <String, dynamic>{};

      // Only add non-null, non-empty parameters
      if (location != null && location.isNotEmpty) {
        queryParameters['location'] = location;
      } else if (latitude != null && longitude != null) {
        queryParameters['lat'] = latitude;
        queryParameters['lon'] = longitude;
      }

      final response = await _apiService.get(
        AppConstants.weather,
        queryParameters: queryParameters,
        useCache: true,
        cacheExpirySeconds: 900, // Cache for 15 minutes
      );

      if (response.statusCode == 200) {
        // Parse NASA GIBS warnings from the response
        final List<WeatherWarning> warnings = [];
        
        if (response.data is List) {
          final forecastData = response.data as List;
          for (var item in forecastData) {
            final weather = WeatherModel.fromJson(item);
            if (weather.isAlert && weather.alertMessage.isNotEmpty) {
              warnings.add(WeatherWarning(
                date: weather.forecastDate,
                message: weather.alertMessage,
                severity: _determineWarningSeverity(weather),
                type: _determineWarningType(weather),
              ));
            }
          }
        }
        
        return warnings;
      }

      return [];
    } catch (e) {
      // Silently fail and return empty list if warnings cannot be fetched
      return [];
    }
  }
  
  // Helper method to determine warning severity
  String _determineWarningSeverity(WeatherModel weather) {
    // Check NASA warning level first
    if (weather.nasaWarningLevel.isNotEmpty) {
      return weather.nasaWarningLevel;
    }
    
    // Fallback to basic severity determination
    if (weather.precipitation > 10.0 || 
        weather.windSpeed > 20.0 || 
        weather.temperature > 35.0 || 
        weather.temperature < 5.0) {
      return 'high';
    } else if (weather.precipitation > 5.0 || 
               weather.windSpeed > 15.0 || 
               (weather.temperature > 30.0 && weather.temperature <= 35.0) ||
               (weather.temperature >= 5.0 && weather.temperature < 10.0)) {
      return 'moderate';
    }
    
    return 'low';
  }
  
  // Helper method to determine warning type
  String _determineWarningType(WeatherModel weather) {
    if (weather.precipitation > 5.0) {
      return 'precipitation';
    } else if (weather.windSpeed > 15.0) {
      return 'wind';
    } else if (weather.temperature > 35.0 || weather.temperature < 5.0) {
      return 'temperature';
    } else if (weather.humidity > 90) {
      return 'humidity';
    }
    
    return 'general';
  }
}

// Weather service result wrapper
class WeatherResult {
  final bool isSuccess;
  final String message;
  final WeatherModel? weather;
  final List<WeatherModel> forecast;

  WeatherResult._({
    required this.isSuccess,
    required this.message,
    this.weather,
    List<WeatherModel>? forecast,
  }) : forecast = forecast ?? [];

  factory WeatherResult.success({
    WeatherModel? weather,
    List<WeatherModel>? forecast,
  }) {
    return WeatherResult._(
      isSuccess: true,
      message: 'Success',
      weather: weather,
      forecast: forecast,
    );
  }

  factory WeatherResult.failure(String message) {
    return WeatherResult._(isSuccess: false, message: message);
  }

  bool get isFailure => !isSuccess;
  bool get hasWeather => weather != null;
  bool get hasForecast => forecast.isNotEmpty;

  @override
  String toString() {
    return 'WeatherResult(isSuccess: $isSuccess, message: $message)';
  }
}

// Weather warning model for NASA GIBS alerts
class WeatherWarning {
  final DateTime date;
  final String message;
  final String severity; // low, moderate, high
  final String type; // precipitation, temperature, wind, humidity, general

  WeatherWarning({
    required this.date,
    required this.message,
    required this.severity,
    required this.type,
  });

  @override
  String toString() {
    return 'WeatherWarning(date: $date, message: $message, severity: $severity, type: $type)';
  }
}