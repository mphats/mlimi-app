import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_strings.dart';
import '../constants/app_strings_chichewa.dart';
import 'api_service.dart';
import '../utils/logger.dart';

class LocalizationService extends ChangeNotifier {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  late SharedPreferences _prefs;
  String _currentLanguage = 'en'; // Default to English

  // Getters
  String get currentLanguage => _currentLanguage;
  bool get isChichewa => _currentLanguage == 'ch'; // Standardized to 'ch'

  // Initialize the service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _currentLanguage = _prefs.getString('language') ?? 'en';
    notifyListeners();
  }

  // Set language
  Future<void> setLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    await _prefs.setString('language', languageCode);
    
    // Sync with backend
    try {
      await ApiService().setLanguage(languageCode);
    } catch (e) {
      // Log error but don't fail the operation
      Logger.error('Failed to sync language with backend: $e');
    }
    
    notifyListeners();
  }

  // Get localized string
  String getString(String key) {
    if (_currentLanguage == 'ch') { // Changed from 'ny' to 'ch'
      // Return Chichewa translation
      return _getChichewaString(key);
    } else {
      // Return English (default)
      return _getEnglishString(key);
    }
  }

  // Get English string
  String _getEnglishString(String key) {
    switch (key) {
      // App General
      case 'appName': return AppStrings.appName;
      case 'appTagline': return AppStrings.appTagline;
      case 'appDescription': return AppStrings.appDescription;

      // Navigation
      case 'home': return AppStrings.home;
      case 'products': return AppStrings.products;
      case 'community': return AppStrings.community;
      case 'weather': return AppStrings.weather;
      case 'profile': return AppStrings.profile;
      case 'back': return AppStrings.back;
      case 'next': return AppStrings.next;
      case 'done': return AppStrings.done;
      case 'save': return AppStrings.save;
      case 'cancel': return AppStrings.cancel;
      case 'delete': return AppStrings.delete;
      case 'edit': return AppStrings.edit;
      case 'search': return AppStrings.search;
      case 'filter': return AppStrings.filter;
      case 'sort': return AppStrings.sort;
      case 'refresh': return AppStrings.refresh;
      case 'loading': return AppStrings.loading;
      case 'retry': return AppStrings.retry;

      // Authentication
      case 'login': return AppStrings.login;
      case 'register': return AppStrings.register;
      case 'logout': return AppStrings.logout;
      case 'forgotPassword': return AppStrings.forgotPassword;
      case 'resetPassword': return AppStrings.resetPassword;
      case 'createAccount': return AppStrings.createAccount;
      case 'alreadyHaveAccount': return AppStrings.alreadyHaveAccount;
      case 'dontHaveAccount': return AppStrings.dontHaveAccount;
      case 'username': return AppStrings.username;
      case 'email': return AppStrings.email;
      case 'password': return AppStrings.password;
      case 'confirmPassword': return AppStrings.confirmPassword;
      case 'role': return AppStrings.role;
      case 'magicLink': return AppStrings.magicLink;
      case 'sendMagicLink': return AppStrings.sendMagicLink;
      case 'checkEmail': return AppStrings.checkEmail;
      case 'emailVerification': return AppStrings.emailVerification;
      case 'verifyEmail': return AppStrings.verifyEmail;
      case 'resendVerification': return AppStrings.resendVerification;

      // User Roles
      case 'farmer': return AppStrings.farmer;
      case 'trader': return AppStrings.trader;
      case 'agronomist': return AppStrings.agronomist;
      case 'admin': return AppStrings.admin;

      // Product Categories
      case 'grains': return AppStrings.grains;
      case 'vegetables': return AppStrings.vegetables;
      case 'fruits': return AppStrings.fruits;
      case 'livestock': return AppStrings.livestock;
      case 'dairy': return AppStrings.dairy;
      case 'other': return AppStrings.other;

      // Products
      case 'myProducts': return AppStrings.myProducts;
      case 'addProduct': return AppStrings.addProduct;
      case 'editProduct': return AppStrings.editProduct;
      case 'productName': return AppStrings.productName;
      case 'productDescription': return AppStrings.productDescription;
      case 'productCategory': return AppStrings.productCategory;
      case 'quantity': return AppStrings.quantity;
      case 'unit': return AppStrings.unit;
      case 'pricePerUnit': return AppStrings.pricePerUnit;
      case 'harvestDate': return AppStrings.harvestDate;
      case 'location': return AppStrings.location;
      case 'contactPhone': return AppStrings.contactPhone;
      case 'addImages': return AppStrings.addImages;
      case 'selectCategory': return AppStrings.selectCategory;
      case 'selectDate': return AppStrings.selectDate;
      case 'availability': return AppStrings.availability;
      case 'available': return AppStrings.available;
      case 'sold': return AppStrings.sold;
      case 'seller': return AppStrings.seller;
      case 'contact': return AppStrings.contact;
      case 'viewDetails': return AppStrings.viewDetails;

      // Market Prices
      case 'marketPrices': return AppStrings.marketPrices;
      case 'currentPrices': return AppStrings.currentPrices;
      case 'priceHistory': return AppStrings.priceHistory;
      case 'marketName': return AppStrings.marketName;
      case 'priceAnalysis': return AppStrings.priceAnalysis;
      case 'buying': return AppStrings.buying;
      case 'selling': return AppStrings.selling;
      case 'currency': return AppStrings.currency;

      // Weather
      case 'weatherForecast': return AppStrings.weatherForecast;
      case 'currentWeather': return AppStrings.currentWeather;
      case 'temperature': return AppStrings.temperature;
      case 'humidity': return AppStrings.humidity;
      case 'precipitation': return AppStrings.precipitation;
      case 'windSpeed': return AppStrings.windSpeed;
      case 'weatherAlert': return AppStrings.weatherAlert;
      case 'getLocation': return AppStrings.getLocation;
      case 'locationPermission': return AppStrings.locationPermission;

      // Community
      case 'communityForum': return AppStrings.communityForum;
      case 'askQuestion': return AppStrings.askQuestion;
      case 'shareExperience': return AppStrings.shareExperience;
      case 'createPost': return AppStrings.createPost;
      case 'postTitle': return AppStrings.postTitle;
      case 'postContent': return AppStrings.postContent;
      case 'postCategory': return AppStrings.postCategory;
      case 'replies': return AppStrings.replies;
      case 'reply': return AppStrings.reply;
      case 'addReply': return AppStrings.addReply;
      case 'like': return AppStrings.like;
      case 'unlike': return AppStrings.unlike;
      case 'share': return AppStrings.share;
      case 'views': return AppStrings.views;
      case 'likes': return AppStrings.likes;
      case 'shares': return AppStrings.shares;
      case 'markAsSolution': return AppStrings.markAsSolution;
      case 'solution': return AppStrings.solution;
      case 'question': return AppStrings.question;
      case 'advice': return AppStrings.advice;
      case 'discussion': return AppStrings.discussion;
      case 'experience': return AppStrings.experience;
      case 'problem': return AppStrings.problem;
      case 'general': return AppStrings.general;
      case 'resolved': return AppStrings.resolved;
      case 'unresolved': return AppStrings.unresolved;

      // AI Pest Diagnosis
      case 'pestDiagnosis': return AppStrings.pestDiagnosis;
      case 'aiDiagnosis': return AppStrings.aiDiagnosis;
      case 'cropType': return AppStrings.cropType;
      case 'symptoms': return AppStrings.symptoms;
      case 'uploadImage': return AppStrings.uploadImage;
      case 'takePhoto': return AppStrings.takePhoto;
      case 'selectFromGallery': return AppStrings.selectFromGallery;
      case 'analyzeImage': return AppStrings.analyzeImage;
      case 'diagnosis': return AppStrings.diagnosis;
      case 'treatmentAdvice': return AppStrings.treatmentAdvice;
      case 'confidenceScore': return AppStrings.confidenceScore;
      case 'describeSymptoms': return AppStrings.describeSymptoms;
      case 'selectCropType': return AppStrings.selectCropType;
      case 'diagnosisHistory': return AppStrings.diagnosisHistory;

      // Newsletters
      case 'newsletters': return AppStrings.newsletters;
      case 'farmingTips': return AppStrings.farmingTips;
      case 'seasonalAdvice': return AppStrings.seasonalAdvice;
      case 'pestControl': return AppStrings.pestControl;
      case 'technology': return AppStrings.technology;
      case 'successStories': return AppStrings.successStories;
      case 'subscribe': return AppStrings.subscribe;
      case 'unsubscribe': return AppStrings.unsubscribe;
      case 'subscriptions': return AppStrings.subscriptions;
      case 'readMore': return AppStrings.readMore;
      case 'readLess': return AppStrings.readLess;

      // Profile
      case 'userProfile': return AppStrings.userProfile;
      case 'editProfile': return AppStrings.editProfile;
      case 'personalInfo': return AppStrings.personalInfo;
      case 'firstName': return AppStrings.firstName;
      case 'lastName': return AppStrings.lastName;
      case 'phoneNumber': return AppStrings.phoneNumber;
      case 'address': return AppStrings.address;
      case 'changePassword': return AppStrings.changePassword;
      case 'currentPassword': return AppStrings.currentPassword;
      case 'newPassword': return AppStrings.newPassword;
      case 'confirmNewPassword': return AppStrings.confirmNewPassword;
      case 'accountSettings': return AppStrings.accountSettings;
      case 'notifications': return AppStrings.notifications;
      case 'notificationPreferences': return AppStrings.notificationPreferences;
      case 'notificationHistory': return AppStrings.notificationHistory;
      case 'analyticsDashboard': return AppStrings.analyticsDashboard;
      case 'language': return AppStrings.language;
      case 'theme': return AppStrings.theme;
      case 'privacy': return AppStrings.privacy;
      case 'about': return AppStrings.about;
      case 'version': return AppStrings.version;
      case 'helpSupport': return AppStrings.helpSupport;

      // Settings
      case 'settings': return AppStrings.settings;
      case 'appSettings': return AppStrings.appSettings;
      case 'enableNotifications': return AppStrings.enableNotifications;
      case 'enableLocationServices': return AppStrings.enableLocationServices;
      case 'autoRefresh': return AppStrings.autoRefresh;
      case 'darkMode': return AppStrings.darkMode;
      case 'english': return AppStrings.english;
      case 'chichewa': return AppStrings.chichewa;

      // Error Messages
      case 'genericError': return AppStrings.genericError;
      case 'networkError': return AppStrings.networkError;
      case 'serverError': return AppStrings.serverError;
      case 'invalidCredentials': return AppStrings.invalidCredentials;
      case 'userNotFound': return AppStrings.userNotFound;
      case 'emailAlreadyExists': return AppStrings.emailAlreadyExists;
      case 'usernameAlreadyExists': return AppStrings.usernameAlreadyExists;
      case 'passwordTooShort': return AppStrings.passwordTooShort;
      case 'passwordMismatch': return AppStrings.passwordMismatch;
      case 'invalidEmail': return AppStrings.invalidEmail;
      case 'fieldRequired': return AppStrings.fieldRequired;
      case 'invalidPhoneNumber': return AppStrings.invalidPhoneNumber;
      case 'noDataFound': return AppStrings.noDataFound;
      case 'noInternetConnection': return AppStrings.noInternetConnection;
      case 'sessionExpired': return AppStrings.sessionExpired;
      case 'permissionDenied': return AppStrings.permissionDenied;
      case 'locationPermissionDenied': return AppStrings.locationPermissionDenied;
      case 'cameraPermissionDenied': return AppStrings.cameraPermissionDenied;
      case 'storagePermissionDenied': return AppStrings.storagePermissionDenied;
      case 'imageTooLarge': return AppStrings.imageTooLarge;
      case 'unsupportedImageFormat': return AppStrings.unsupportedImageFormat;

      // Success Messages
      case 'loginSuccessful': return AppStrings.loginSuccessful;
      case 'registrationSuccessful': return AppStrings.registrationSuccessful;
      case 'profileUpdated': return AppStrings.profileUpdated;
      case 'passwordChanged': return AppStrings.passwordChanged;
      case 'productAdded': return AppStrings.productAdded;
      case 'productUpdated': return AppStrings.productUpdated;
      case 'productDeleted': return AppStrings.productDeleted;
      case 'postCreated': return AppStrings.postCreated;
      case 'replyAdded': return AppStrings.replyAdded;
      case 'subscriptionUpdated': return AppStrings.subscriptionUpdated;
      case 'diagnosisCompleted': return AppStrings.diagnosisCompleted;
      case 'imageUploaded': return AppStrings.imageUploaded;
      case 'dataRefreshed': return AppStrings.dataRefreshed;

      // Confirmation Messages
      case 'confirmDelete': return AppStrings.confirmDelete;
      case 'confirmLogout': return AppStrings.confirmLogout;
      case 'confirmDiscard': return AppStrings.confirmDiscard;
      case 'deleteAccount': return AppStrings.deleteAccount;
      case 'confirmDeleteAccount': return AppStrings.confirmDeleteAccount;

      // Time and Date
      case 'today': return AppStrings.today;
      case 'yesterday': return AppStrings.yesterday;
      case 'tomorrow': return AppStrings.tomorrow;
      case 'thisWeek': return AppStrings.thisWeek;
      case 'lastWeek': return AppStrings.lastWeek;
      case 'thisMonth': return AppStrings.thisMonth;
      case 'lastMonth': return AppStrings.lastMonth;
      case 'daysAgo': return AppStrings.daysAgo;
      case 'hoursAgo': return AppStrings.hoursAgo;
      case 'minutesAgo': return AppStrings.minutesAgo;
      case 'justNow': return AppStrings.justNow;

      // Units
      case 'kg': return AppStrings.kg;
      case 'grams': return AppStrings.grams;
      case 'tonnes': return AppStrings.tonnes;
      case 'pieces': return AppStrings.pieces;
      case 'liters': return AppStrings.liters;
      case 'bags': return AppStrings.bags;
      case 'boxes': return AppStrings.boxes;
      case 'celsius': return AppStrings.celsius;
      case 'fahrenheit': return AppStrings.fahrenheit;
      case 'percentage': return AppStrings.percentage;
      case 'kilometers': return AppStrings.kilometers;
      case 'meters': return AppStrings.meters;
      case 'kmh': return AppStrings.kmh;
      case 'mph': return AppStrings.mph;

      // Onboarding
      case 'welcomeTitle': return AppStrings.welcomeTitle;
      case 'welcomeSubtitle': return AppStrings.welcomeSubtitle;
      case 'onboardingSkip': return AppStrings.onboardingSkip;
      case 'onboardingGetStarted': return AppStrings.onboardingGetStarted;
      case 'onboardingTitle1': return AppStrings.onboardingTitle1;
      case 'onboardingDescription1': return AppStrings.onboardingDescription1;
      case 'onboardingTitle2': return AppStrings.onboardingTitle2;
      case 'onboardingDescription2': return AppStrings.onboardingDescription2;
      case 'onboardingTitle3': return AppStrings.onboardingTitle3;
      case 'onboardingDescription3': return AppStrings.onboardingDescription3;
      case 'onboardingTitle4': return AppStrings.onboardingTitle4;
      case 'onboardingDescription4': return AppStrings.onboardingDescription4;

      // Reports
      case 'reports': return AppStrings.reports;
      case 'reportSubscriptions': return AppStrings.reportSubscriptions;
      case 'createReport': return AppStrings.createReport;
      case 'myReports': return AppStrings.myReports;
      case 'subscribeToReports': return AppStrings.subscribeToReports;

      // Analytics Dashboard - Additional strings for the enhanced dashboard
      case 'farmingInsights': return AppStrings.farmingInsights;
      case 'userActivity': return AppStrings.userActivity;
      case 'pestDiagnoses': return AppStrings.pestDiagnoses;
      case 'cropPerformance': return AppStrings.cropPerformance;
      case 'financialAnalytics': return AppStrings.financialAnalytics;
      case 'totalActivities': return AppStrings.totalActivities;
      case 'dailyAverage': return AppStrings.dailyAverage;
      case 'mostActive': return AppStrings.mostActive;
      case 'currentPrice': return AppStrings.currentPrice;
      case 'averagePrice': return AppStrings.averagePrice;
      case 'highestPrice': return AppStrings.highestPrice;
      case 'lowestPrice': return AppStrings.lowestPrice;
      case 'trend': return AppStrings.trend;
      case 'revenue': return AppStrings.revenue;
      case 'expenses': return AppStrings.expenses;
      case 'profit': return AppStrings.profit;
      case 'roi': return AppStrings.roi;
      case 'yield': return AppStrings.yieldTerm;
      case 'confidence': return AppStrings.confidence;
      case 'noPestDiagnosesRecordedYet': return AppStrings.noPestDiagnosesRecordedYet;
      case 'yourAgriculturalAnalyticsDashboard': return AppStrings.yourAgriculturalAnalyticsDashboard;
      case 'welcomeBack': return AppStrings.welcomeBack;
      case 'signInToContinue': return AppStrings.signInToContinue;
      case 'rememberMe': return AppStrings.rememberMe;
      case 'ok': return AppStrings.ok;
      case 'confirm': return AppStrings.confirm;
      case 'diagnosisDetails': return AppStrings.diagnosisDetails;
      case 'camera': return AppStrings.camera;
      case 'gallery': return AppStrings.gallery;
      case 'removeImage': return AppStrings.removeImage;
      case 'aiPestDiagnosis': return AppStrings.aiPestDiagnosis;
      case 'diagnosisInProgress': return AppStrings.diagnosisInProgress;
      case 'loadingDiagnosisHistory': return AppStrings.loadingDiagnosisHistory;
      case 'maize': return AppStrings.maize;
      case 'beans': return AppStrings.beans;
      case 'rice': return AppStrings.rice;
      case 'versionNumber': return AppStrings.versionNumber;
      
      // Translation keys from documentation
      case 'all': return AppStrings.all;
      case 'quickActions': return AppStrings.quickActions;
      case 'quickAction': return AppStrings.quickAction;
      case 'listProduce': return AppStrings.listProduce;
      case 'searchProducts': return AppStrings.searchProducts;
      case 'allProducts': return AppStrings.allProducts;
      case 'viewAll': return AppStrings.viewAll;
      case 'connectLearnGrow': return AppStrings.connectLearnGrow;
      case 'welcomeBackUser': return AppStrings.welcomeBackUser;
      case 'posts': return AppStrings.posts;
      
      // Add Product Screen
      case 'addProductTitle': return AppStrings.addProductTitle;
      case 'listYourAgriculturalProduct': return AppStrings.listYourAgriculturalProduct;
      case 'enterProductName': return AppStrings.enterProductName;
      case 'enterProductDescription': return AppStrings.enterProductDescription;
      case 'enterQuantity': return AppStrings.enterQuantity;
      case 'enterUnit': return AppStrings.enterUnit; // Added
      case 'enterPrice': return AppStrings.enterPrice;
      case 'enterLocation': return AppStrings.enterLocation;
      case 'enterPhoneNumber': return AppStrings.enterPhoneNumber;
      case 'productListedSuccessfully': return AppStrings.productListedSuccessfully;
      case 'failedToListProduct': return AppStrings.failedToListProduct;
      case 'failedToUploadImages': return AppStrings.failedToUploadImages; // Added
      case 'pleaseEnterProductName': return AppStrings.pleaseEnterProductName;
      case 'productNameMustBeAtLeast': return AppStrings.productNameMustBeAtLeast;
      case 'pleaseEnterQuantity': return AppStrings.pleaseEnterQuantity;
      case 'pleaseEnterUnit': return AppStrings.pleaseEnterUnit; // Added
      case 'pleaseEnterValidNumber': return AppStrings.pleaseEnterValidNumber;
      case 'quantityMustBeGreaterThan': return AppStrings.quantityMustBeGreaterThan;
      case 'pleaseEnterPrice': return AppStrings.pleaseEnterPrice;
      case 'priceMustBeGreaterThan': return AppStrings.priceMustBeGreaterThan;
      case 'pleaseEnterLocation': return AppStrings.pleaseEnterLocation;
      case 'pleaseEnterPhoneNumber': return AppStrings.pleaseEnterPhoneNumber;
      case 'pleaseEnterValidPhoneNumber': return AppStrings.pleaseEnterValidPhoneNumber;
      case 'kilograms': return AppStrings.kilograms;
      case 'bunches': return AppStrings.bunches;
      case 'otherCategory': return AppStrings.otherCategory;
      case 'productImages': return AppStrings.productImages; // Added
      case 'addProductImages': return AppStrings.addProductImages; // Added
      case 'imagesSelected': return AppStrings.imagesSelected; // Added

      default: 
        // Log missing translation for debugging
        Logger.warn('Missing English translation for key: $key');
        return key;
    }
  }

  // Get Chichewa string
  String _getChichewaString(String key) {
    switch (key) {
      // App General
      case 'appName': return AppStringsChichewa.appName;
      case 'appTagline': return AppStringsChichewa.appTagline;
      case 'appDescription': return AppStringsChichewa.appDescription;

      // Navigation
      case 'home': return AppStringsChichewa.home;
      case 'products': return AppStringsChichewa.products;
      case 'community': return AppStringsChichewa.community;
      case 'weather': return AppStringsChichewa.weather;
      case 'profile': return AppStringsChichewa.profile;
      case 'back': return AppStringsChichewa.back;
      case 'next': return AppStringsChichewa.next;
      case 'done': return AppStringsChichewa.done;
      case 'save': return AppStringsChichewa.save;
      case 'cancel': return AppStringsChichewa.cancel;
      case 'delete': return AppStringsChichewa.delete;
      case 'edit': return AppStringsChichewa.edit;
      case 'search': return AppStringsChichewa.search;
      case 'filter': return AppStringsChichewa.filter;
      case 'sort': return AppStringsChichewa.sort;
      case 'refresh': return AppStringsChichewa.refresh;
      case 'loading': return AppStringsChichewa.loading;
      case 'retry': return AppStringsChichewa.retry;

      // Authentication
      case 'login': return AppStringsChichewa.login;
      case 'register': return AppStringsChichewa.register;
      case 'logout': return AppStringsChichewa.logout;
      case 'forgotPassword': return AppStringsChichewa.forgotPassword;
      case 'resetPassword': return AppStringsChichewa.resetPassword;
      case 'createAccount': return AppStringsChichewa.createAccount;
      case 'alreadyHaveAccount': return AppStringsChichewa.alreadyHaveAccount;
      case 'dontHaveAccount': return AppStringsChichewa.dontHaveAccount;
      case 'username': return AppStringsChichewa.username;
      case 'email': return AppStringsChichewa.email;
      case 'password': return AppStringsChichewa.password;
      case 'confirmPassword': return AppStringsChichewa.confirmPassword;
      case 'role': return AppStringsChichewa.role;
      case 'magicLink': return AppStringsChichewa.magicLink;
      case 'sendMagicLink': return AppStringsChichewa.sendMagicLink;
      case 'checkEmail': return AppStringsChichewa.checkEmail;
      case 'emailVerification': return AppStringsChichewa.emailVerification;
      case 'verifyEmail': return AppStringsChichewa.verifyEmail;
      case 'resendVerification': return AppStringsChichewa.resendVerification;

      // User Roles
      case 'farmer': return AppStringsChichewa.farmer;
      case 'trader': return AppStringsChichewa.trader;
      case 'agronomist': return AppStringsChichewa.agronomist;
      case 'admin': return AppStringsChichewa.admin;

      // Product Categories
      case 'grains': return AppStringsChichewa.grains;
      case 'vegetables': return AppStringsChichewa.vegetables;
      case 'fruits': return AppStringsChichewa.fruits;
      case 'livestock': return AppStringsChichewa.livestock;
      case 'dairy': return AppStringsChichewa.dairy;
      case 'other': return AppStringsChichewa.other;

      // Products
      case 'myProducts': return AppStringsChichewa.myProducts;
      case 'addProduct': return AppStringsChichewa.addProduct;
      case 'editProduct': return AppStringsChichewa.editProduct;
      case 'productName': return AppStringsChichewa.productName;
      case 'productDescription': return AppStringsChichewa.productDescription;
      case 'productCategory': return AppStringsChichewa.productCategory;
      case 'quantity': return AppStringsChichewa.quantity;
      case 'unit': return AppStringsChichewa.unit;
      case 'pricePerUnit': return AppStringsChichewa.pricePerUnit;
      case 'harvestDate': return AppStringsChichewa.harvestDate;
      case 'location': return AppStringsChichewa.location;
      case 'contactPhone': return AppStringsChichewa.contactPhone;
      case 'addImages': return AppStringsChichewa.addImages;
      case 'selectCategory': return AppStringsChichewa.selectCategory;
      case 'selectDate': return AppStringsChichewa.selectDate;
      case 'availability': return AppStringsChichewa.availability;
      case 'available': return AppStringsChichewa.available;
      case 'sold': return AppStringsChichewa.sold;
      case 'seller': return AppStringsChichewa.seller;
      case 'contact': return AppStringsChichewa.contact;
      case 'viewDetails': return AppStringsChichewa.viewDetails;

      // Market Prices
      case 'marketPrices': return AppStringsChichewa.marketPrices;
      case 'currentPrices': return AppStringsChichewa.currentPrices;
      case 'priceHistory': return AppStringsChichewa.priceHistory;
      case 'marketName': return AppStringsChichewa.marketName;
      case 'priceAnalysis': return AppStringsChichewa.priceAnalysis;
      case 'buying': return AppStringsChichewa.buying;
      case 'selling': return AppStringsChichewa.selling;
      case 'currency': return AppStringsChichewa.currency;

      // Weather
      case 'weatherForecast': return AppStringsChichewa.weatherForecast;
      case 'currentWeather': return AppStringsChichewa.currentWeather;
      case 'temperature': return AppStringsChichewa.temperature;
      case 'humidity': return AppStringsChichewa.humidity;
      case 'precipitation': return AppStringsChichewa.precipitation;
      case 'windSpeed': return AppStringsChichewa.windSpeed;
      case 'weatherAlert': return AppStringsChichewa.weatherAlert;
      case 'getLocation': return AppStringsChichewa.getLocation;
      case 'locationPermission': return AppStringsChichewa.locationPermission;

      // Community
      case 'communityForum': return AppStringsChichewa.communityForum;
      case 'askQuestion': return AppStringsChichewa.askQuestion;
      case 'shareExperience': return AppStringsChichewa.shareExperience;
      case 'createPost': return AppStringsChichewa.createPost;
      case 'postTitle': return AppStringsChichewa.postTitle;
      case 'postContent': return AppStringsChichewa.postContent;
      case 'postCategory': return AppStringsChichewa.postCategory;
      case 'replies': return AppStringsChichewa.replies;
      case 'reply': return AppStringsChichewa.reply;
      case 'addReply': return AppStringsChichewa.addReply;
      case 'like': return AppStringsChichewa.like;
      case 'unlike': return AppStringsChichewa.unlike;
      case 'share': return AppStringsChichewa.share;
      case 'views': return AppStringsChichewa.views;
      case 'likes': return AppStringsChichewa.likes;
      case 'shares': return AppStringsChichewa.shares;
      case 'markAsSolution': return AppStringsChichewa.markAsSolution;
      case 'solution': return AppStringsChichewa.solution;
      case 'question': return AppStringsChichewa.question;
      case 'advice': return AppStringsChichewa.advice;
      case 'discussion': return AppStringsChichewa.discussion;
      case 'experience': return AppStringsChichewa.experience;
      case 'problem': return AppStringsChichewa.problem;
      case 'general': return AppStringsChichewa.general;
      case 'resolved': return AppStringsChichewa.resolved;
      case 'unresolved': return AppStringsChichewa.unresolved;

      // AI Pest Diagnosis
      case 'pestDiagnosis': return AppStringsChichewa.pestDiagnosis;
      case 'aiDiagnosis': return AppStringsChichewa.aiDiagnosis;
      case 'cropType': return AppStringsChichewa.cropType;
      case 'symptoms': return AppStringsChichewa.symptoms;
      case 'uploadImage': return AppStringsChichewa.uploadImage;
      case 'takePhoto': return AppStringsChichewa.takePhoto;
      case 'selectFromGallery': return AppStringsChichewa.selectFromGallery;
      case 'analyzeImage': return AppStringsChichewa.analyzeImage;
      case 'diagnosis': return AppStringsChichewa.diagnosis;
      case 'treatmentAdvice': return AppStringsChichewa.treatmentAdvice;
      case 'confidenceScore': return AppStringsChichewa.confidenceScore;
      case 'describeSymptoms': return AppStringsChichewa.describeSymptoms;
      case 'selectCropType': return AppStringsChichewa.selectCropType;
      case 'diagnosisHistory': return AppStringsChichewa.diagnosisHistory;

      // Newsletters
      case 'newsletters': return AppStringsChichewa.newsletters;
      case 'farmingTips': return AppStringsChichewa.farmingTips;
      case 'seasonalAdvice': return AppStringsChichewa.seasonalAdvice;
      case 'pestControl': return AppStringsChichewa.pestControl;
      case 'technology': return AppStringsChichewa.technology;
      case 'successStories': return AppStringsChichewa.successStories;
      case 'subscribe': return AppStringsChichewa.subscribe;
      case 'unsubscribe': return AppStringsChichewa.unsubscribe;
      case 'subscriptions': return AppStringsChichewa.subscriptions;
      case 'readMore': return AppStringsChichewa.readMore;
      case 'readLess': return AppStringsChichewa.readLess;

      // Profile
      case 'userProfile': return AppStringsChichewa.userProfile;
      case 'editProfile': return AppStringsChichewa.editProfile;
      case 'personalInfo': return AppStringsChichewa.personalInfo;
      case 'firstName': return AppStringsChichewa.firstName;
      case 'lastName': return AppStringsChichewa.lastName;
      case 'phoneNumber': return AppStringsChichewa.phoneNumber;
      case 'address': return AppStringsChichewa.address;
      case 'changePassword': return AppStringsChichewa.changePassword;
      case 'currentPassword': return AppStringsChichewa.currentPassword;
      case 'newPassword': return AppStringsChichewa.newPassword;
      case 'confirmNewPassword': return AppStringsChichewa.confirmNewPassword;
      case 'accountSettings': return AppStringsChichewa.accountSettings;
      case 'notifications': return AppStringsChichewa.notifications;
      case 'notificationPreferences': return AppStringsChichewa.notificationPreferences;
      case 'notificationHistory': return AppStringsChichewa.notificationHistory;
      case 'analyticsDashboard': return AppStringsChichewa.analyticsDashboard;
      case 'language': return AppStringsChichewa.language;
      case 'theme': return AppStringsChichewa.theme;
      case 'privacy': return AppStringsChichewa.privacy;
      case 'about': return AppStringsChichewa.about;
      case 'version': return AppStringsChichewa.version;
      case 'helpSupport': return AppStringsChichewa.helpSupport;

      // Settings
      case 'settings': return AppStringsChichewa.settings;
      case 'appSettings': return AppStringsChichewa.appSettings;
      case 'enableNotifications': return AppStringsChichewa.enableNotifications;
      case 'enableLocationServices': return AppStringsChichewa.enableLocationServices;
      case 'autoRefresh': return AppStringsChichewa.autoRefresh;
      case 'darkMode': return AppStringsChichewa.darkMode;
      case 'english': return AppStringsChichewa.english;
      case 'chichewa': return AppStringsChichewa.chichewa;

      // Error Messages
      case 'genericError': return AppStringsChichewa.genericError;
      case 'networkError': return AppStringsChichewa.networkError;
      case 'serverError': return AppStringsChichewa.serverError;
      case 'invalidCredentials': return AppStringsChichewa.invalidCredentials;
      case 'userNotFound': return AppStringsChichewa.userNotFound;
      case 'emailAlreadyExists': return AppStringsChichewa.emailAlreadyExists;
      case 'usernameAlreadyExists': return AppStringsChichewa.usernameAlreadyExists;
      case 'passwordTooShort': return AppStringsChichewa.passwordTooShort;
      case 'passwordMismatch': return AppStringsChichewa.passwordMismatch;
      case 'invalidEmail': return AppStringsChichewa.invalidEmail;
      case 'fieldRequired': return AppStringsChichewa.fieldRequired;
      case 'invalidPhoneNumber': return AppStringsChichewa.invalidPhoneNumber;
      case 'noDataFound': return AppStringsChichewa.noDataFound;
      case 'noInternetConnection': return AppStringsChichewa.noInternetConnection;
      case 'sessionExpired': return AppStringsChichewa.sessionExpired;
      case 'permissionDenied': return AppStringsChichewa.permissionDenied;
      case 'locationPermissionDenied': return AppStringsChichewa.locationPermissionDenied;
      case 'cameraPermissionDenied': return AppStringsChichewa.cameraPermissionDenied;
      case 'storagePermissionDenied': return AppStringsChichewa.storagePermissionDenied;
      case 'imageTooLarge': return AppStringsChichewa.imageTooLarge;
      case 'unsupportedImageFormat': return AppStringsChichewa.unsupportedImageFormat;

      // Success Messages
      case 'loginSuccessful': return AppStringsChichewa.loginSuccessful;
      case 'registrationSuccessful': return AppStringsChichewa.registrationSuccessful;
      case 'profileUpdated': return AppStringsChichewa.profileUpdated;
      case 'passwordChanged': return AppStringsChichewa.passwordChanged;
      case 'productAdded': return AppStringsChichewa.productAdded;
      case 'productUpdated': return AppStringsChichewa.productUpdated;
      case 'productDeleted': return AppStringsChichewa.productDeleted;
      case 'postCreated': return AppStringsChichewa.postCreated;
      case 'replyAdded': return AppStringsChichewa.replyAdded;
      case 'subscriptionUpdated': return AppStringsChichewa.subscriptionUpdated;
      case 'diagnosisCompleted': return AppStringsChichewa.diagnosisCompleted;
      case 'imageUploaded': return AppStringsChichewa.imageUploaded;
      case 'dataRefreshed': return AppStringsChichewa.dataRefreshed;

      // Confirmation Messages
      case 'confirmDelete': return AppStringsChichewa.confirmDelete;
      case 'confirmLogout': return AppStringsChichewa.confirmLogout;
      case 'confirmDiscard': return AppStringsChichewa.confirmDiscard;
      case 'deleteAccount': return AppStringsChichewa.deleteAccount;
      case 'confirmDeleteAccount': return AppStringsChichewa.confirmDeleteAccount;

      // Time and Date
      case 'today': return AppStringsChichewa.today;
      case 'yesterday': return AppStringsChichewa.yesterday;
      case 'tomorrow': return AppStringsChichewa.tomorrow;
      case 'thisWeek': return AppStringsChichewa.thisWeek;
      case 'lastWeek': return AppStringsChichewa.lastWeek;
      case 'thisMonth': return AppStringsChichewa.thisMonth;
      case 'lastMonth': return AppStringsChichewa.lastMonth;
      case 'daysAgo': return AppStringsChichewa.daysAgo;
      case 'hoursAgo': return AppStringsChichewa.hoursAgo;
      case 'minutesAgo': return AppStringsChichewa.minutesAgo;
      case 'justNow': return AppStringsChichewa.justNow;

      // Units
      case 'kg': return AppStringsChichewa.kg;
      case 'grams': return AppStringsChichewa.grams;
      case 'tonnes': return AppStringsChichewa.tonnes;
      case 'pieces': return AppStringsChichewa.pieces;
      case 'liters': return AppStringsChichewa.liters;
      case 'bags': return AppStringsChichewa.bags;
      case 'boxes': return AppStringsChichewa.boxes;
      case 'celsius': return AppStringsChichewa.celsius;
      case 'fahrenheit': return AppStringsChichewa.fahrenheit;
      case 'percentage': return AppStringsChichewa.percentage;
      case 'kilometers': return AppStringsChichewa.kilometers;
      case 'meters': return AppStringsChichewa.meters;
      case 'kmh': return AppStringsChichewa.kmh;
      case 'mph': return AppStringsChichewa.mph;

      // Onboarding
      case 'welcomeTitle': return AppStringsChichewa.welcomeTitle;
      case 'welcomeSubtitle': return AppStringsChichewa.welcomeSubtitle;
      case 'onboardingSkip': return AppStringsChichewa.onboardingSkip;
      case 'onboardingGetStarted': return AppStringsChichewa.onboardingGetStarted;
      case 'onboardingTitle1': return AppStringsChichewa.onboardingTitle1;
      case 'onboardingDescription1': return AppStringsChichewa.onboardingDescription1;
      case 'onboardingTitle2': return AppStringsChichewa.onboardingTitle2;
      case 'onboardingDescription2': return AppStringsChichewa.onboardingDescription2;
      case 'onboardingTitle3': return AppStringsChichewa.onboardingTitle3;
      case 'onboardingDescription3': return AppStringsChichewa.onboardingDescription3;
      case 'onboardingTitle4': return AppStringsChichewa.onboardingTitle4;
      case 'onboardingDescription4': return AppStringsChichewa.onboardingDescription4;

      // Reports
      case 'reports': return AppStringsChichewa.reports;
      case 'reportSubscriptions': return AppStringsChichewa.reportSubscriptions;
      case 'createReport': return AppStringsChichewa.createReport;
      case 'myReports': return AppStringsChichewa.myReports;
      case 'subscribeToReports': return AppStringsChichewa.subscribeToReports;

      // Analytics Dashboard - Additional strings for the enhanced dashboard
      case 'farmingInsights': return AppStringsChichewa.farmingInsights;
      case 'userActivity': return AppStringsChichewa.userActivity;
      case 'pestDiagnoses': return AppStringsChichewa.pestDiagnoses;
      case 'cropPerformance': return AppStringsChichewa.cropPerformance;
      case 'financialAnalytics': return AppStringsChichewa.financialAnalytics;
      case 'totalActivities': return AppStringsChichewa.totalActivities;
      case 'dailyAverage': return AppStringsChichewa.dailyAverage;
      case 'mostActive': return AppStringsChichewa.mostActive;
      case 'currentPrice': return AppStringsChichewa.currentPrice;
      case 'averagePrice': return AppStringsChichewa.averagePrice;
      case 'highestPrice': return AppStringsChichewa.highestPrice;
      case 'lowestPrice': return AppStringsChichewa.lowestPrice;
      case 'trend': return AppStringsChichewa.trend;
      case 'revenue': return AppStringsChichewa.revenue;
      case 'expenses': return AppStringsChichewa.expenses;
      case 'profit': return AppStringsChichewa.profit;
      case 'roi': return AppStringsChichewa.roi;
      case 'yield': return AppStringsChichewa.yieldTerm;
      case 'confidence': return AppStringsChichewa.confidence;
      case 'noPestDiagnosesRecordedYet': return AppStringsChichewa.noPestDiagnosesRecordedYet;
      case 'yourAgriculturalAnalyticsDashboard': return AppStringsChichewa.yourAgriculturalAnalyticsDashboard;
      case 'welcomeBack': return AppStringsChichewa.welcomeBack;
      case 'signInToContinue': return AppStringsChichewa.signInToContinue;
      case 'rememberMe': return AppStringsChichewa.rememberMe;
      case 'ok': return AppStringsChichewa.ok;
      case 'confirm': return AppStringsChichewa.confirm;
      case 'diagnosisDetails': return AppStringsChichewa.diagnosisDetails;
      case 'camera': return AppStringsChichewa.camera;
      case 'gallery': return AppStringsChichewa.gallery;
      case 'removeImage': return AppStringsChichewa.removeImage;
      case 'aiPestDiagnosis': return AppStringsChichewa.aiPestDiagnosis;
      case 'diagnosisInProgress': return AppStringsChichewa.diagnosisInProgress;
      case 'loadingDiagnosisHistory': return AppStringsChichewa.loadingDiagnosisHistory;
      case 'maize': return AppStringsChichewa.maize;
      case 'beans': return AppStringsChichewa.beans;
      case 'rice': return AppStringsChichewa.rice;
      case 'versionNumber': return AppStringsChichewa.versionNumber;
      
      // Translation keys from documentation
      case 'all': return AppStringsChichewa.all;
      case 'quickActions': return AppStringsChichewa.quickActions;
      case 'quickAction': return AppStringsChichewa.quickAction;
      case 'listProduce': return AppStringsChichewa.listProduce;
      case 'searchProducts': return AppStringsChichewa.searchProducts;
      case 'allProducts': return AppStringsChichewa.allProducts;
      case 'viewAll': return AppStringsChichewa.viewAll;
      case 'connectLearnGrow': return AppStringsChichewa.connectLearnGrow;
      case 'welcomeBackUser': return AppStringsChichewa.welcomeBackUser;
      case 'posts': return AppStringsChichewa.posts;
      
      // Add Product Screen
      case 'addProductTitle': return AppStringsChichewa.addProductTitle;
      case 'listYourAgriculturalProduct': return AppStringsChichewa.listYourAgriculturalProduct;
      case 'enterProductName': return AppStringsChichewa.enterProductName;
      case 'enterProductDescription': return AppStringsChichewa.enterProductDescription;
      case 'enterQuantity': return AppStringsChichewa.enterQuantity;
      case 'enterPrice': return AppStringsChichewa.enterPrice;
      case 'enterLocation': return AppStringsChichewa.enterLocation;
      case 'enterPhoneNumber': return AppStringsChichewa.enterPhoneNumber;
      case 'productListedSuccessfully': return AppStringsChichewa.productListedSuccessfully;
      case 'failedToListProduct': return AppStringsChichewa.failedToListProduct;
      case 'pleaseEnterProductName': return AppStringsChichewa.pleaseEnterProductName;
      case 'productNameMustBeAtLeast': return AppStringsChichewa.productNameMustBeAtLeast;
      case 'pleaseEnterQuantity': return AppStringsChichewa.pleaseEnterQuantity;
      case 'pleaseEnterValidNumber': return AppStringsChichewa.pleaseEnterValidNumber;
      case 'quantityMustBeGreaterThan': return AppStringsChichewa.quantityMustBeGreaterThan;
      case 'pleaseEnterPrice': return AppStringsChichewa.pleaseEnterPrice;
      case 'priceMustBeGreaterThan': return AppStringsChichewa.priceMustBeGreaterThan;
      case 'pleaseEnterLocation': return AppStringsChichewa.pleaseEnterLocation;
      case 'pleaseEnterPhoneNumber': return AppStringsChichewa.pleaseEnterPhoneNumber;
      case 'pleaseEnterValidPhoneNumber': return AppStringsChichewa.pleaseEnterValidPhoneNumber;
      case 'kilograms': return AppStringsChichewa.kilograms;
      case 'bunches': return AppStringsChichewa.bunches;
      case 'otherCategory': return AppStringsChichewa.otherCategory;
      case 'enterUnit': return AppStringsChichewa.enterUnit; // Added
      case 'pleaseEnterUnit': return AppStringsChichewa.pleaseEnterUnit; // Added
      case 'failedToUploadImages': return AppStringsChichewa.failedToUploadImages; // Added
      case 'productImages': return AppStringsChichewa.productImages; // Added
      case 'addProductImages': return AppStringsChichewa.addProductImages; // Added
      case 'imagesSelected': return AppStringsChichewa.imagesSelected; // Added

      default: 
        // Log missing translation for debugging
        Logger.warn('Missing Chichewa translation for key: $key');
        // Fallback to English translation
        return _getEnglishString(key);
    }
  }
}