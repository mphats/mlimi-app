
class WeatherModel {
  final int id;
  final String location;
  final double? latitude;
  final double? longitude;
  final double temperature;
  final int humidity;
  final double precipitation;
  final double windSpeed;
  final String description;
  final DateTime forecastDate;
  final bool isAlert;
  final String alertMessage;
  final DateTime recordedAt;
  
  // NASA GIBS specific fields
  final double? nasaPrecipitation;
  final double? nasaTemperature;
  final double? nasaVegetationIndex;
  final String nasaWarningLevel;
  final String nasaWarningDetails;

  WeatherModel({
    required this.id,
    required this.location,
    this.latitude,
    this.longitude,
    required this.temperature,
    required this.humidity,
    required this.precipitation,
    required this.windSpeed,
    required this.description,
    required this.forecastDate,
    required this.isAlert,
    required this.alertMessage,
    required this.recordedAt,
    this.nasaPrecipitation,
    this.nasaTemperature,
    this.nasaVegetationIndex,
    this.nasaWarningLevel = '',
    this.nasaWarningDetails = '',
  });

  // Getters for display formatting
  String get temperatureDisplay => '${temperature.toStringAsFixed(1)}°C';
  String get humidityDisplay => '$humidity%';
  String get precipitationDisplay => '${precipitation.toStringAsFixed(1)}mm';
  String get windSpeedDisplay => '${windSpeed.toStringAsFixed(1)} m/s';
  String get forecastDateDisplay => _formatDate(forecastDate);
  String get weatherIcon => _getWeatherIcon(description);
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final forecastDay = DateTime(date.year, date.month, date.day);
    
    if (forecastDay.isAtSameMomentAs(today)) {
      return 'Today';
    } else if (forecastDay.difference(today).inDays == 1) {
      return 'Tomorrow';
    } else {
      return '${_getWeekday(date.weekday)}, ${date.day} ${_getMonth(date.month)}';
    }
  }
  
  String _getWeekday(int weekday) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[weekday - 1];
  }
  
  String _getMonth(int month) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month];
  }
  
  String _getWeatherIcon(String description) {
    final desc = description.toLowerCase();
    
    if (desc.contains('rain') || desc.contains('shower')) {
      return '🌧️';
    } else if (desc.contains('cloud')) {
      return '☁️';
    } else if (desc.contains('sun')) {
      return '☀️';
    } else if (desc.contains('storm') || desc.contains('thunder')) {
      return '⛈️';
    } else if (desc.contains('snow')) {
      return '❄️';
    } else {
      return '🌤️';
    }
  }

  // Helper method to parse double values from various types
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  // Helper method to parse integer values from various types
  static int _parseInteger(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }

  // Helper method to parse nullable double values
  static double? _parseNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      id: json['id'] ?? 0,
      location: json['location'] ?? '',
      latitude: _parseNullableDouble(json['latitude']),
      longitude: _parseNullableDouble(json['longitude']),
      temperature: _parseDouble(json['temperature']),
      humidity: _parseInteger(json['humidity']),
      precipitation: _parseDouble(json['precipitation']),
      windSpeed: _parseDouble(json['wind_speed']),
      description: json['description'] ?? '',
      forecastDate: DateTime.tryParse(json['forecast_date']?.toString() ?? '') ?? DateTime.now(),
      isAlert: json['is_alert'] ?? false,
      alertMessage: json['alert_message'] ?? '',
      recordedAt: DateTime.tryParse(json['recorded_at']?.toString() ?? '') ?? DateTime.now(),
      nasaPrecipitation: _parseNullableDouble(json['nasa_precipitation']),
      nasaTemperature: _parseNullableDouble(json['nasa_temperature']),
      nasaVegetationIndex: _parseNullableDouble(json['nasa_vegetation_index']),
      nasaWarningLevel: json['nasa_warning_level'] ?? '',
      nasaWarningDetails: json['nasa_warning_details'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'temperature': temperature,
      'humidity': humidity,
      'precipitation': precipitation,
      'wind_speed': windSpeed,
      'description': description,
      'forecast_date': forecastDate.toIso8601String(),
      'is_alert': isAlert,
      'alert_message': alertMessage,
      'recorded_at': recordedAt.toIso8601String(),
      'nasa_precipitation': nasaPrecipitation,
      'nasa_temperature': nasaTemperature,
      'nasa_vegetation_index': nasaVegetationIndex,
      'nasa_warning_level': nasaWarningLevel,
      'nasa_warning_details': nasaWarningDetails,
    };
  }

  WeatherModel copyWith({
    int? id,
    String? location,
    double? latitude,
    double? longitude,
    double? temperature,
    int? humidity,
    double? precipitation,
    double? windSpeed,
    String? description,
    DateTime? forecastDate,
    bool? isAlert,
    String? alertMessage,
    DateTime? recordedAt,
    double? nasaPrecipitation,
    double? nasaTemperature,
    double? nasaVegetationIndex,
    String? nasaWarningLevel,
    String? nasaWarningDetails,
  }) {
    return WeatherModel(
      id: id ?? this.id,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      precipitation: precipitation ?? this.precipitation,
      windSpeed: windSpeed ?? this.windSpeed,
      description: description ?? this.description,
      forecastDate: forecastDate ?? this.forecastDate,
      isAlert: isAlert ?? this.isAlert,
      alertMessage: alertMessage ?? this.alertMessage,
      recordedAt: recordedAt ?? this.recordedAt,
      nasaPrecipitation: nasaPrecipitation ?? this.nasaPrecipitation,
      nasaTemperature: nasaTemperature ?? this.nasaTemperature,
      nasaVegetationIndex: nasaVegetationIndex ?? this.nasaVegetationIndex,
      nasaWarningLevel: nasaWarningLevel ?? this.nasaWarningLevel,
      nasaWarningDetails: nasaWarningDetails ?? this.nasaWarningDetails,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is WeatherModel &&
      other.id == id &&
      other.location == location &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.temperature == temperature &&
      other.humidity == humidity &&
      other.precipitation == precipitation &&
      other.windSpeed == windSpeed &&
      other.description == description &&
      other.forecastDate == forecastDate &&
      other.isAlert == isAlert &&
      other.alertMessage == alertMessage &&
      other.recordedAt == recordedAt &&
      other.nasaPrecipitation == nasaPrecipitation &&
      other.nasaTemperature == nasaTemperature &&
      other.nasaVegetationIndex == nasaVegetationIndex &&
      other.nasaWarningLevel == nasaWarningLevel &&
      other.nasaWarningDetails == nasaWarningDetails;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      location.hashCode ^
      latitude.hashCode ^
      longitude.hashCode ^
      temperature.hashCode ^
      humidity.hashCode ^
      precipitation.hashCode ^
      windSpeed.hashCode ^
      description.hashCode ^
      forecastDate.hashCode ^
      isAlert.hashCode ^
      alertMessage.hashCode ^
      recordedAt.hashCode ^
      nasaPrecipitation.hashCode ^
      nasaTemperature.hashCode ^
      nasaVegetationIndex.hashCode ^
      nasaWarningLevel.hashCode ^
      nasaWarningDetails.hashCode;
  }

  @override
  String toString() {
    return 'WeatherModel(id: $id, location: $location, temperature: $temperature, humidity: $humidity, precipitation: $precipitation, windSpeed: $windSpeed, description: $description, forecastDate: $forecastDate, isAlert: $isAlert, alertMessage: $alertMessage, recordedAt: $recordedAt, nasaPrecipitation: $nasaPrecipitation, nasaTemperature: $nasaTemperature, nasaVegetationIndex: $nasaVegetationIndex, nasaWarningLevel: $nasaWarningLevel, nasaWarningDetails: $nasaWarningDetails)';
  }
}