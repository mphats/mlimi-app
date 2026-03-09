import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/weather_service.dart';
import '../../core/services/offline_service.dart';
import '../../core/models/weather_model.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final _weatherService = WeatherService();
  List<WeatherModel> _weatherData = [];
  List<WeatherWarning> _weatherWarnings = [];
  String _location = 'Blantyre';
  bool _isOfflineMode = false;

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    try {
      final result = await _weatherService.getWeatherForecast(
        days: 7,
        location: _location,
      );

      if (result.isSuccess) {
        setState(() {
          _weatherData = result.forecast;
        });
        
        // Load NASA GIBS warnings
        await _loadWeatherWarnings();
        
        // Save data for offline use
        final List<Map<String, dynamic>> offlineData = 
            result.forecast.map((w) => w.toJson()).toList();
        await OfflineService.saveWeatherData(offlineData);
      } else {
        // Try to load offline data if API fails
        await _loadOfflineData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${result.message}. Showing offline data.'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }
    } catch (e) {
      // Try to load offline data if API fails
      await _loadOfflineData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load weather data: ${e.toString()}. Showing offline data.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _loadWeatherWarnings() async {
    try {
      final warnings = await _weatherService.getWeatherWarnings(
        location: _location,
      );
      
      if (mounted) {
        setState(() {
          _weatherWarnings = warnings;
        });
      }
    } catch (e) {
      // Silently fail if warnings cannot be loaded
      debugPrint('Failed to load weather warnings: $e');
    }
  }

  Future<void> _loadOfflineData() async {
    try {
      final isRecent = await OfflineService.isDataRecent();
      if (isRecent) {
        final offlineData = await OfflineService.getWeatherData();
        if (offlineData != null && offlineData.isNotEmpty) {
          final forecast = offlineData.map((json) => WeatherModel.fromJson(json)).toList();
          if (mounted) {
            setState(() {
              _weatherData = forecast;
              _isOfflineMode = true;
            });
          }
        }
      }
    } catch (e) {
      // Silently fail if offline data is not available
      debugPrint('Failed to load offline data: $e');
    }
  }

  Future<void> _refreshWeatherData() async {
    await _loadWeatherData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.weather),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isOfflineMode)
            IconButton(
              icon: const Icon(Icons.offline_pin, color: AppColors.warning),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Showing offline data. Connect to the internet for latest updates.'),
                    backgroundColor: AppColors.warning,
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshWeatherData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshWeatherData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Current and forecast weather conditions',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),

              // Location Selector
              _buildLocationSelector(),
              const SizedBox(height: 24),

              // Weather Warnings
              if (_weatherWarnings.isNotEmpty)
                _buildWeatherWarnings(),
              const SizedBox(height: 24),

              // Current Weather
              if (_weatherData.isNotEmpty)
                _buildCurrentWeather(_weatherData.first),
              const SizedBox(height: 24),

              // Forecast
              _buildForecast(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Enter location',
                    border: OutlineInputBorder(),
                  ),
                  controller: TextEditingController(text: _location),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      setState(() {
                        _location = value.trim();
                      });
                      _loadWeatherData();
                    }
                  },
                  onChanged: (value) {
                    // Update location as user types if needed
                  },
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 100,
                height: 40,
                child: ElevatedButton(
                  onPressed: () {
                    final controller = TextEditingController(text: _location);
                    // Get the current text field value
                    final newLocation = controller.text;
                    if (newLocation.trim().isNotEmpty) {
                      setState(() {
                        _location = newLocation.trim();
                      });
                      _loadWeatherData();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Update'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherWarnings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber, color: AppColors.warning),
              const SizedBox(width: 8),
              Text(
                'Weather Warnings',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._weatherWarnings.map((warning) => _buildWarningItem(warning)),
        ],
      ),
    );
  }

  Widget _buildWarningItem(WeatherWarning warning) {
    Color warningColor;
    IconData warningIcon;
    
    switch (warning.severity) {
      case 'high':
        warningColor = AppColors.error;
        warningIcon = Icons.error;
        break;
      case 'moderate':
        warningColor = AppColors.warning;
        warningIcon = Icons.warning_amber;
        break;
      default:
        warningColor = AppColors.info;
        warningIcon = Icons.info;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(warningIcon, color: warningColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              warning.message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentWeather(WeatherModel currentWeather) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade400, Colors.blue.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _location,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    currentWeather.forecastDateDisplay,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  // Show alert indicator if there's a NASA warning
                  if (currentWeather.isAlert)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning, size: 16, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Weather Alert',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              Text(
                currentWeather.weatherIcon,
                style: const TextStyle(fontSize: 48),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currentWeather.temperatureDisplay,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                currentWeather.description,
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeatherDetail(
                Icons.water_drop_outlined,
                'Humidity',
                currentWeather.humidityDisplay,
                Colors.white,
              ),
              _buildWeatherDetail(
                Icons.air,
                'Wind',
                currentWeather.windSpeedDisplay,
                Colors.white,
              ),
              _buildWeatherDetail(
                Icons.opacity_outlined,
                'Rain',
                currentWeather.precipitationDisplay,
                Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildForecast() {
    if (_weatherData.length <= 1) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '7-Day Forecast',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SizedBox(
            height: (_weatherData.length - 1) * 70.0, // Approximate height per item
            child: Column(
              children: _weatherData.skip(1).map((weather) {
                return _buildForecastItem(weather);
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForecastItem(WeatherModel weather) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              weather.forecastDateDisplay,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              weather.weatherIcon,
              style: const TextStyle(fontSize: 24),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              weather.description,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              weather.temperatureDisplay,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Show warning icon if there's a NASA alert for this day
          if (weather.isAlert)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.warning, color: AppColors.warning, size: 16),
            ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetail(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: color.withValues(alpha: 0.8)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}