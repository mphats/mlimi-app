
class AppConstants {
  static String get baseUrl => 'https://mlimi.cloud';

  static String get apiV1 => '$baseUrl/api/v1';
  static String get apiAuth => '$apiV1/auth';
  static String get apiUsers => '$apiV1/users';

  // WebSocket URL
  static String get wsUrl => 'wss://mlimi.cloud';

  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';

  // Shared preferences keys
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language_code';
  static const String onboardingKey = 'onboarding_completed';

  // API endpoints
  static const String healthCheck = '/health';
  static const String setLanguage = '/set-language'; // Added language endpoint
  static const String login = '/auth/token/';
  static const String register = '/auth/register'; // Fixed: Removed trailing slash
  static const String refreshToken = '/auth/token/refresh/';
  static const String userProfile = '/auth/me'; // Fixed: Removed trailing slash
  static const String changePassword = '/auth/change-password'; // Added change password endpoint
  static const String magicLinkRequest = '/auth/magic-link-request';
  static const String magicLinkVerify = '/auth/magic-link-verify';
  static const String passwordReset = '/auth/password-reset';
  static const String passwordResetConfirm = '/auth/password-reset-confirm';
  static const String emailVerify = '/auth/verify-email';
  static const String otpVerify = '/auth/verify-otp'; // Added OTP verification endpoint
  static const String otpResend = '/auth/resend-otp'; // Added OTP resend endpoint
  // Updated endpoints with correct paths
  static const String profileImageUpload = '/auth/profile/image/';
  static const String coverImageUpload = '/auth/profile/cover/';
  static const String profileImages = '/auth/profile/images/';

  // Product endpoints
  static const String products = '/products';
  static const String productImages = '/products/{id}/images';

  // Market prices
  static const String marketPrices = '/market-prices';
  static const String marketPricesCreate = '/market-prices/create';

  // Weather
  static const String weather = '/weather';
  static const String weatherForecast = '/weather/forecast';

  // Community
  static const String communityPosts = '/community/posts';
  static const String communityReplies = '/community/posts/{id}/replies';
  static const String postLike = '/community/posts/{id}/like';
  static const String postShare = '/community/posts/{id}/share';
  static const String postView = '/community/posts/{id}/view';
  static const String replyLike = '/community/replies/{id}/like';
  static const String markSolution = '/community/replies/{id}/solution';

  // Newsletters
  static const String newsletters = '/newsletters';
  static const String newsletterSubscriptions = '/newsletter-subscriptions';

  // AI Diagnosis
  static const String pestDiagnosis = '/pest-diagnosis';
  static const String asyncPestDiagnosis = '/pest-diagnosis/async';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Image settings
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = [
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
  ];

  // Categories
  static const List<String> productCategories = [
    'GRAINS',
    'VEGETABLES',
    'FRUITS',
    'LIVESTOCK',
    'DAIRY',
    'OTHER',
  ];

  static const List<String> communityCategories = [
    'question',
    'advice',
    'discussion',
    'experience',
    'problem',
    'solution',
    'general',
  ];

  static const List<String> userRoles = [
    'FARMER',
    'TRADER',
    'AGRONOMIST',
    'ADMIN',
  ];

  static const List<String> newsletterCategories = [
    'tips',
    'market_trends',
    'seasonal_advice',
    'pest_control',
    'weather',
    'technology',
    'success_stories',
  ];
}