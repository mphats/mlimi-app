import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show Platform;
import '../utils/logger.dart';


class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final StreamController<NotificationModel> _notificationController =
      StreamController<NotificationModel>.broadcast();
  late SharedPreferences _prefs;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Stream<NotificationModel> get onNotification =>
      _notificationController.stream;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // Load notification preferences
    await _loadPreferences();
    
    // Initialize local notifications for all platforms including Windows
    await _initializeLocalNotifications();
  }

  // Initialize local notifications for all platforms
  Future<void> _initializeLocalNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      final DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      // Windows initialization settings
      final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
        windows: WindowsInitializationSettings(
          appName: 'Mulimi',
          appUserModelId: 'com.mulimi.app',
          guid: '541466aa-43d7-4538-a6ab-46c108630000',
        ),
      );
      
      await _localNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Handle notification tap
          Logger.info('Notification tapped: ${response.payload}');
        },
      );
      
      // Request permissions on iOS
      if (Platform.isIOS) {
        await _localNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
      }
      
      Logger.info('Local notifications initialized successfully');
    } catch (e) {
      Logger.error('Error initializing local notifications: $e');
    }
  }

  // Show a local notification
  Future<void> showNotification(NotificationModel notification) async {
    // Check if user has enabled notifications for this category
    final isEnabled = await isNotificationEnabled(notification.category);
    if (isEnabled) {
      // Add to notification stream
      _notificationController.add(notification);
      
      // Show the local notification
      await _showLocalNotification(notification);
      
      // Save to local storage for history
      await _saveNotification(notification);
    }
  }

  // Show local notification using flutter_local_notifications plugin
  Future<void> _showLocalNotification(NotificationModel notification) async {
    try {
      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'mulimi_channel_id',
        'Mulimi Notifications',
        channelDescription: 'Notification channel for Mulimi app',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
      );

      const DarwinNotificationDetails iOSNotificationDetails =
          DarwinNotificationDetails();

      // Windows notification details
      const WindowsNotificationDetails windowsNotificationDetails =
          WindowsNotificationDetails();

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iOSNotificationDetails,
        windows: windowsNotificationDetails,
      );

      await _localNotificationsPlugin.show(
        int.parse(notification.id) % 1000000, // Ensure it's within int range
        notification.title,
        notification.content,
        notificationDetails,
        payload: notification.toJson(),
      );
    } catch (e) {
      Logger.error('Error showing local notification: $e');
    }
  }

  // Save notification to local storage
  Future<void> _saveNotification(NotificationModel notification) async {
    final notifications = await getNotificationHistory();
    notifications.add(notification);
    
    // Keep only the last 100 notifications
    if (notifications.length > 100) {
      notifications.removeRange(0, notifications.length - 100);
    }
    
    final List<String> serialized = 
        notifications.map((n) => n.toJson()).toList();
    
    await _prefs.setStringList('notifications', serialized);
  }

  // Get notification history
  Future<List<NotificationModel>> getNotificationHistory() async {
    final List<String>? serialized = _prefs.getStringList('notifications');
    if (serialized == null || serialized.isEmpty) {
      return [];
    }
    
    return serialized
        .map((json) => NotificationModel.fromJson(json))
        .toList()
        .reversed
        .toList();
  }

  // Clear notification history
  Future<void> clearNotificationHistory() async {
    await _prefs.remove('notifications');
  }

  // Notification preferences
  final Map<String, bool> _notificationPreferences = {
    'newsletters': true,
    'market_updates': true,
    'weather_alerts': true,
    'pest_alerts': true,
    'community_mentions': true,
    'general': true,
  };

  // Load preferences from storage
  Future<void> _loadPreferences() async {
    for (final category in _notificationPreferences.keys) {
      final key = 'notification_pref_$category';
      if (_prefs.containsKey(key)) {
        _notificationPreferences[category] = _prefs.getBool(key) ?? true;
      }
    }
  }

  // Check if notification is enabled for a category
  Future<bool> isNotificationEnabled(String category) async {
    return _notificationPreferences[category] ?? true;
  }

  // Set notification preference for a category
  Future<void> setNotificationPreference(String category, bool enabled) async {
    _notificationPreferences[category] = enabled;
    await _prefs.setBool('notification_pref_$category', enabled);
  }

  // Get all notification preferences
  Map<String, bool> getNotificationPreferences() {
    return Map.from(_notificationPreferences);
  }

  // Create different types of notifications
  Future<void> showNewsletterNotification(String title, String content) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      category: 'newsletters',
      timestamp: DateTime.now(),
    );
    
    await showNotification(notification);
  }

  Future<void> showMarketUpdateNotification(String title, String content) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      category: 'market_updates',
      timestamp: DateTime.now(),
    );
    
    await showNotification(notification);
  }

  Future<void> showWeatherAlertNotification(String title, String content) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      category: 'weather_alerts',
      timestamp: DateTime.now(),
    );
    
    await showNotification(notification);
  }

  Future<void> showPestAlertNotification(String title, String content) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      category: 'pest_alerts',
      timestamp: DateTime.now(),
    );
    
    await showNotification(notification);
  }

  Future<void> showCommunityMentionNotification(String title, String content) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      category: 'community_mentions',
      timestamp: DateTime.now(),
    );
    
    await showNotification(notification);
  }

  Future<void> showGeneralNotification(String title, String content) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      category: 'general',
      timestamp: DateTime.now(),
    );
    
    await showNotification(notification);
  }

  // Dispose of the service
  void dispose() {
    _notificationController.close();
  }
}

class NotificationModel {
  final String id;
  final String title;
  final String content;
  final String category;
  final DateTime timestamp;

  NotificationModel({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.timestamp,
  });

  String toJson() {
    return '$id|$title|$content|$category|${timestamp.millisecondsSinceEpoch}';
  }

  factory NotificationModel.fromJson(String json) {
    final parts = json.split('|');
    return NotificationModel(
      id: parts[0],
      title: parts[1],
      content: parts[2],
      category: parts[3],
      timestamp: DateTime.fromMillisecondsSinceEpoch(int.parse(parts[4])),
    );
  }
}