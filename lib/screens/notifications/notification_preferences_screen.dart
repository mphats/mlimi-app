import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/notification_service.dart';
import '../../core/providers/auth_provider.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';  // Removed for Windows build

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  final NotificationService _notificationService = NotificationService();
  late Map<String, bool> _preferences;
  // String _fcmToken = 'Loading...';  // Removed for Windows build
  final String _fcmToken = 'Not available (Firebase disabled)';  // Updated for Windows build

  @override
  void initState() {
    super.initState();
    _preferences = _notificationService.getNotificationPreferences();
    // _loadFcmToken();  // Removed for Windows build
  }

  // Future<void> _loadFcmToken() async {  // Removed for Windows build
  /*
  Future<void> _loadFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      setState(() {
        _fcmToken = token ?? 'Not available';
      });
    } catch (e) {
      setState(() {
        _fcmToken = 'Error loading token';
      });
    }
  }
  */

  Future<void> _updatePreference(String category, bool value) async {
    setState(() {
      _preferences[category] = value;
    });
    await _notificationService.setNotificationPreference(category, value);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isFarmer = authProvider.user?.role == 'FARMER';
    final isAgronomist = authProvider.user?.role == 'AGRONOMIST';
    final showConsultationOption = isFarmer || isAgronomist;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.notificationPreferences),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Manage your notification preferences',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildPreferenceTile(
              'Newsletter Updates',
              'Receive farming tips and market updates',
              'newsletters',
              Icons.newspaper,
            ),
            _buildPreferenceTile(
              'Market Updates',
              'Get notified about price changes',
              'market_updates',
              Icons.trending_up,
            ),
            _buildPreferenceTile(
              'Weather Alerts',
              'Important weather notifications',
              'weather_alerts',
              Icons.wb_sunny,
            ),
            _buildPreferenceTile(
              'Pest Alerts',
              'Notifications about pest outbreaks',
              'pest_alerts',
              Icons.bug_report,
            ),
            _buildPreferenceTile(
              'Community Mentions',
              'When someone mentions you in posts',
              'community_mentions',
              Icons.people,
            ),
            if (showConsultationOption)
              _buildPreferenceTile(
                'Consultation Updates',
                'Notifications about your consultations',
                'consultation_update',
                Icons.question_answer,
              ),
            _buildPreferenceTile(
              'General Notifications',
              'Other important app notifications',
              'general',
              Icons.notifications,
            ),
            const SizedBox(height: 24),
            // FCM Token Information Section - Modified for Windows build
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Device Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FCM Token',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _fcmToken,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: null,  // Disabled for Windows build
                          child: const Text('Refresh Token'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Show a test notification
                    _notificationService.showGeneralNotification(
                      'Test Notification',
                      'This is a test notification to verify your settings',
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Test notification sent!'),
                      ),
                    );
                  },
                  child: const Text('Send Test Notification'),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceTile(
    String title,
    String subtitle,
    String category,
    IconData icon,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      secondary: Icon(icon),
      value: _preferences[category] ?? true,
      onChanged: (value) => _updatePreference(category, value),
    );
  }
}