import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'core/providers/auth_provider.dart';
import 'core/services/api_service.dart';
import 'core/services/cache_service.dart';
import 'core/services/service_manager.dart';
import 'core/services/sync_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/services/notification_service.dart';
import 'core/services/analytics_service.dart';
import 'core/services/localization_service.dart';
import 'core/services/camera_service.dart';
import 'core/utils/logger.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart'; // Added import for register screen
import 'screens/home/home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/newsletter/newsletter_subscription_screen.dart';
import 'screens/analytics/analytics_dashboard_screen.dart';
import 'screens/analytics/market_trends_screen.dart';
import 'screens/cache/cache_stats_screen.dart';
import 'screens/notifications/notification_preferences_screen.dart';
import 'screens/notifications/notification_history_screen.dart';
import 'screens/sync/offline_data_screen.dart';
import 'screens/consultation/consultation_list_screen.dart';
import 'screens/settings/language_selection_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/edit_profile_screen.dart'; // Added import
import 'screens/settings/change_password_screen.dart'; // Added import
import 'screens/settings/privacy_settings_screen.dart'; // Added import
// Added imports for profile-related screens
import 'screens/products/my_products_screen.dart';
import 'screens/community/community_screen.dart';
import 'screens/ai_diagnosis/pest_diagnosis_history_screen.dart';
// Added import for profile screen
import 'screens/profile/profile_screen.dart';
// Added import for notification demo screen
import 'screens/notifications/notification_demo_screen.dart';
// Added import for camera test screen
import 'screens/camera/camera_test_screen.dart';

void main() async {
  
  // Ensure widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with error handling
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    Logger.error('Firebase initialization error: $e');
    // Continue without Firebase if initialization fails
  }

  // Initialize API service
  ApiService().initialize();

  // Initialize Cache service
  await CacheService().init();

  // Initialize services with error handling
  try {
    // Initialize Notification service
    await NotificationService().init();
  } catch (e) {
    Logger.error('Notification service initialization error: $e');
  }

  try {
    // Initialize Camera service
    await CameraService().initialize();
  } catch (e) {
    Logger.error('Camera service initialization error: $e');
  }

  try {
    // Initialize Analytics service
    await AnalyticsService().init();
  } catch (e) {
    Logger.error('Analytics service initialization error: $e');
  }

  // Initialize Localization service
  await LocalizationService().init();

  // Initialize Sync service
  SyncService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ServiceManager()),
        ChangeNotifierProvider(create: (_) => LocalizationService()),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(), // Added register route
          '/home': (context) => const HomeScreen(),
          '/newsletter-subscription': (context) => const NewsletterSubscriptionScreen(),
          '/analytics-dashboard': (context) => const AnalyticsDashboardScreen(),
          '/market-trends': (context) => const MarketTrendsScreen(),
          '/cache-stats': (context) => const CacheStatsScreen(),
          '/notification-preferences': (context) => const NotificationPreferencesScreen(),
          '/notification-history': (context) => const NotificationHistoryScreen(),
          '/offline-data': (context) => const OfflineDataScreen(),
          '/consultations': (context) => const ConsultationListScreen(),
          '/language-selection': (context) => const LanguageSelectionScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/edit-profile': (context) => const EditProfileScreen(), // Added route
          '/change-password': (context) => const ChangePasswordScreen(), // Added route
          '/privacy-settings': (context) => const PrivacySettingsScreen(), // Added route
          // Added routes for profile-related screens
          '/my-products': (context) => const MyProductsScreen(),
          '/my-community-posts': (context) => const CommunityScreen(),
          '/pest-disease-diagnosis-history': (context) => const PestDiagnosisHistoryScreen(),
          // Added profile route
          '/profile': (context) => const ProfileScreen(),
          // Notification demo route
          '/notification-demo': (context) => const NotificationDemoScreen(),
          // Camera test route
          '/camera-test': (context) => const CameraTestScreen(),
          // Additional routes that could be implemented
          // '/user-guide': (context) => const UserGuideScreen(),
          // '/contact': (context) => const ContactSupportScreen(),
          // '/report-issue': (context) => const ReportIssueScreen(),
        },
      ),
    );
  }
}

// Function to register FCM token with backend - REMOVED for Windows build
/*
Future<void> registerFcmToken() async {
  try {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await ApiService().registerFcmToken(token);
      print('FCM token registered successfully');
    }
  } catch (e) {
    print('Failed to register FCM token: $e');
  }
}
*/