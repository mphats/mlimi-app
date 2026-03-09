import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/community_model.dart';
import '../models/weather_model.dart';
import '../models/market_price_model.dart';
import '../models/newsletter_model.dart';
import '../models/pest_diagnosis_model.dart';
import '../services/analytics_service.dart';
import '../utils/error_handler.dart';
import 'product_service.dart';
import 'community_service.dart';
import 'weather_service.dart';
import 'market_price_service.dart';
import 'newsletter_service.dart';
import 'pest_diagnosis_service.dart';

class ServiceManager with ChangeNotifier {
  final ProductService _productService = ProductService();
  final CommunityService _communityService = CommunityService();
  final WeatherService _weatherService = WeatherService();
  final MarketPriceService _marketPriceService = MarketPriceService();
  final NewsletterService _newsletterService = NewsletterService();
  final PestDiagnosisService _pestDiagnosisService = PestDiagnosisService();
  final AnalyticsService _analyticsService = AnalyticsService();

  // Data caches
  List<ProductModel> _products = [];
  List<CommunityPostModel> _posts = [];
  WeatherModel? _weather;
  List<MarketPriceModel> _marketPrices = [];
  List<NewsletterModel> _newsletters = [];
  List<NewsletterSubscriptionModel> _subscriptions = [];
  List<PestDiagnosisModel> _diagnoses = [];

  // Loading states
  bool _isLoadingProducts = false;
  bool _isLoadingPosts = false;
  bool _isLoadingWeather = false;
  bool _isLoadingMarketPrices = false;
  bool _isLoadingNewsletters = false;
  bool _isLoadingSubscriptions = false;
  bool _isLoadingDiagnoses = false;

  // Getters
  List<ProductModel> get products => _products;
  List<CommunityPostModel> get posts => _posts;
  WeatherModel? get weather => _weather;
  List<MarketPriceModel> get marketPrices => _marketPrices;
  List<NewsletterModel> get newsletters => _newsletters;
  List<NewsletterSubscriptionModel> get subscriptions => _subscriptions;
  List<PestDiagnosisModel> get diagnoses => _diagnoses;

  bool get isLoadingProducts => _isLoadingProducts;
  bool get isLoadingPosts => _isLoadingPosts;
  bool get isLoadingWeather => _isLoadingWeather;
  bool get isLoadingMarketPrices => _isLoadingMarketPrices;
  bool get isLoadingNewsletters => _isLoadingNewsletters;
  bool get isLoadingSubscriptions => _isLoadingSubscriptions;
  bool get isLoadingDiagnoses => _isLoadingDiagnoses;

  // Load all dashboard data with caching
  Future<void> loadDashboardData() async {
    // Load data in parallel for better performance
    await Future.wait([
      loadProducts(),
      loadCommunityPosts(),
      loadWeather(),
      loadMarketPrices(),
      loadNewsletters(),
      loadSubscriptions(),
      loadDiagnoses(),
    ]);
    
    // Track user activity
    await _analyticsService.trackUserActivity('dashboard_view', DateTime.now());
  }

  // Load products with caching
  Future<void> loadProducts() async {
    if (_isLoadingProducts) return;

    _isLoadingProducts = true;
    notifyListeners();

    try {
      final result = await _productService.getProducts(
        page: 1,
        pageSize: 10,
        useCache: true,
      );

      if (result.isSuccess && result.hasProducts) {
        _products = result.products;
      } else {
        debugPrint('Error loading products: ${result.message}');
      }
    } catch (e) {
      debugPrint('Error loading products: ${ErrorHandler.handleException(e)}');
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  // Load community posts with caching
  Future<void> loadCommunityPosts() async {
    if (_isLoadingPosts) return;

    _isLoadingPosts = true;
    notifyListeners();

    try {
      final result = await _communityService.getPosts(
        page: 1,
        pageSize: 10,
        useCache: true,
      );

      if (result.isSuccess && result.hasPosts) {
        _posts = result.posts;
      } else {
        debugPrint('Error loading posts: ${result.message}');
      }
    } catch (e) {
      debugPrint('Error loading posts: ${ErrorHandler.handleException(e)}');
    } finally {
      _isLoadingPosts = false;
      notifyListeners();
    }
  }

  // Load weather data with caching
  Future<void> loadWeather() async {
    if (_isLoadingWeather) return;

    _isLoadingWeather = true;
    notifyListeners();

    try {
      final result = await _weatherService.getCurrentWeather(useCache: true);

      if (result.isSuccess && result.hasWeather) {
        _weather = result.weather;
      } else {
        debugPrint('Error loading weather: ${result.message}');
      }
    } catch (e) {
      debugPrint('Error loading weather: ${ErrorHandler.handleException(e)}');
    } finally {
      _isLoadingWeather = false;
      notifyListeners();
    }
  }

  // Load market prices with caching
  Future<void> loadMarketPrices() async {
    if (_isLoadingMarketPrices) return;

    _isLoadingMarketPrices = true;
    notifyListeners();

    try {
      final result = await _marketPriceService.getMarketPrices(
        page: 1,
        pageSize: 10,
        useCache: true,
      );

      if (result.isSuccess && result.hasPrices) {
        _marketPrices = result.prices;
        
        // Track market data for analytics
        for (final price in result.prices) {
          await _analyticsService.addMarketPriceData(
            price.productCategory,
            price.marketName,
            price.pricePerUnit,
            DateTime.now(),
          );
        }
      } else {
        debugPrint('Error loading market prices: ${result.message}');
      }
    } catch (e) {
      debugPrint('Error loading market prices: ${ErrorHandler.handleException(e)}');
    } finally {
      _isLoadingMarketPrices = false;
      notifyListeners();
    }
  }

  // Load newsletters with caching
  Future<void> loadNewsletters() async {
    if (_isLoadingNewsletters) return;

    _isLoadingNewsletters = true;
    notifyListeners();

    try {
      final result = await _newsletterService.getNewsletters(
        page: 1,
        pageSize: 5,
        useCache: true,
      );

      if (result.isSuccess && result.hasData) {
        _newsletters = result.data;
      } else {
        debugPrint('Error loading newsletters: ${result.message}');
      }
    } catch (e) {
      debugPrint('Error loading newsletters: ${ErrorHandler.handleException(e)}');
    } finally {
      _isLoadingNewsletters = false;
      notifyListeners();
    }
  }
  
  // Load newsletter subscriptions
  Future<void> loadSubscriptions() async {
    if (_isLoadingSubscriptions) return;

    _isLoadingSubscriptions = true;
    notifyListeners();

    try {
      final result = await _newsletterService.getSubscriptions();

      if (result.isSuccess && result.hasSubscriptions) {
        _subscriptions = result.subscriptions;
      } else {
        debugPrint('Error loading subscriptions: ${result.message}');
      }
    } catch (e) {
      debugPrint('Error loading subscriptions: ${ErrorHandler.handleException(e)}');
    } finally {
      _isLoadingSubscriptions = false;
      notifyListeners();
    }
  }

  // Load diagnoses with caching
  Future<void> loadDiagnoses() async {
    if (_isLoadingDiagnoses) return;

    _isLoadingDiagnoses = true;
    notifyListeners();

    try {
      final result = await _pestDiagnosisService.getDiagnosisHistory(
        page: 1,
        pageSize: 5,
        useCache: true,
      );

      if (result.isSuccess && result.hasDiagnoses) {
        _diagnoses = result.diagnoses;
        
        // Track pest diagnoses for analytics
        for (final diagnosis in result.diagnoses) {
          await _analyticsService.trackPestDiagnosis(
            diagnosis.cropType,
            diagnosis.diagnosis,
            diagnosis.confidenceScore,
            diagnosis.createdAt,
          );
        }
      } else {
        debugPrint('Error loading diagnoses: ${result.message}');
      }
    } catch (e) {
      debugPrint('Error loading diagnoses: ${ErrorHandler.handleException(e)}');
    } finally {
      _isLoadingDiagnoses = false;
      notifyListeners();
    }
  }

  // Clear all cached data
  Future<void> clearAllData() async {
    _products = [];
    _posts = [];
    _weather = null;
    _marketPrices = [];
    _newsletters = [];
    _subscriptions = [];
    _diagnoses = [];

    notifyListeners();
  }

  // Refresh all data (bypass cache)
  Future<void> refreshAllData() async {
    // Load data in parallel for better performance
    await Future.wait([
      _loadProductsNoCache(),
      _loadCommunityPostsNoCache(),
      _loadWeatherNoCache(),
      _loadMarketPricesNoCache(),
      _loadNewslettersNoCache(),
      _loadSubscriptionsNoCache(),
      _loadDiagnosesNoCache(),
    ]);
    
    // Track user activity
    await _analyticsService.trackUserActivity('data_refresh', DateTime.now());
  }

  // Load products without cache
  Future<void> _loadProductsNoCache() async {
    _isLoadingProducts = true;
    notifyListeners();

    try {
      final result = await _productService.getProducts(
        page: 1,
        pageSize: 10,
        useCache: false,
      );

      if (result.isSuccess && result.hasProducts) {
        _products = result.products;
      } else {
        debugPrint('Error loading products: ${result.message}');
      }
    } catch (e) {
      debugPrint('Error loading products: ${ErrorHandler.handleException(e)}');
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  // Load community posts without cache
  Future<void> _loadCommunityPostsNoCache() async {
    _isLoadingPosts = true;
    notifyListeners();

    try {
      final result = await _communityService.getPosts(
        page: 1,
        pageSize: 10,
        useCache: false,
      );

      if (result.isSuccess && result.hasPosts) {
        _posts = result.posts;
      } else {
        debugPrint('Error loading posts: ${result.message}');
      }
    } catch (e) {
      debugPrint('Error loading posts: ${ErrorHandler.handleException(e)}');
    } finally {
      _isLoadingPosts = false;
      notifyListeners();
    }
  }

  // Load weather data without cache
  Future<void> _loadWeatherNoCache() async {
    _isLoadingWeather = true;
    notifyListeners();

    try {
      final result = await _weatherService.getCurrentWeather(useCache: false);

      if (result.isSuccess && result.hasWeather) {
        _weather = result.weather;
      } else {
        debugPrint('Error loading weather: ${result.message}');
      }
    } catch (e) {
      debugPrint('Error loading weather: ${ErrorHandler.handleException(e)}');
    } finally {
      _isLoadingWeather = false;
      notifyListeners();
    }
  }

  // Load market prices without cache
  Future<void> _loadMarketPricesNoCache() async {
    _isLoadingMarketPrices = true;
    notifyListeners();

    try {
      final result = await _marketPriceService.getMarketPrices(
        page: 1,
        pageSize: 10,
        useCache: false,
      );

      if (result.isSuccess && result.hasPrices) {
        _marketPrices = result.prices;
        
        // Track market data for analytics
        for (final price in result.prices) {
          await _analyticsService.addMarketPriceData(
            price.productCategory,
            price.marketName,
            price.pricePerUnit,
            DateTime.now(),
          );
        }
      } else {
        debugPrint('Error loading market prices: ${result.message}');
      }
    } catch (e) {
      debugPrint('Error loading market prices: ${ErrorHandler.handleException(e)}');
    } finally {
      _isLoadingMarketPrices = false;
      notifyListeners();
    }
  }

  // Load newsletters without cache
  Future<void> _loadNewslettersNoCache() async {
    _isLoadingNewsletters = true;
    notifyListeners();

    try {
      final result = await _newsletterService.getNewsletters(
        page: 1,
        pageSize: 5,
        useCache: false,
      );

      if (result.isSuccess && result.hasData) {
        _newsletters = result.data;
      } else {
        debugPrint('Error loading newsletters: ${result.message}');
      }
    } catch (e) {
      debugPrint('Error loading newsletters: ${ErrorHandler.handleException(e)}');
    } finally {
      _isLoadingNewsletters = false;
      notifyListeners();
    }
  }
  
  // Load subscriptions without cache
  Future<void> _loadSubscriptionsNoCache() async {
    _isLoadingSubscriptions = true;
    notifyListeners();

    try {
      final result = await _newsletterService.getSubscriptions();

      if (result.isSuccess && result.hasSubscriptions) {
        _subscriptions = result.subscriptions;
      } else {
        debugPrint('Error loading subscriptions: ${result.message}');
      }
    } catch (e) {
      debugPrint('Error loading subscriptions: ${ErrorHandler.handleException(e)}');
    } finally {
      _isLoadingSubscriptions = false;
      notifyListeners();
    }
  }

  // Load diagnoses without cache
  Future<void> _loadDiagnosesNoCache() async {
    _isLoadingDiagnoses = true;
    notifyListeners();

    try {
      final result = await _pestDiagnosisService.getDiagnosisHistory(
        page: 1,
        pageSize: 5,
        useCache: false,
      );

      if (result.isSuccess && result.hasDiagnoses) {
        _diagnoses = result.diagnoses;
        
        // Track pest diagnoses for analytics
        for (final diagnosis in result.diagnoses) {
          await _analyticsService.trackPestDiagnosis(
            diagnosis.cropType,
            diagnosis.diagnosis,
            diagnosis.confidenceScore,
            diagnosis.createdAt,
          );
        }
      } else {
        debugPrint('Error loading diagnoses: ${result.message}');
      }
    } catch (e) {
      debugPrint('Error loading diagnoses: ${ErrorHandler.handleException(e)}');
    } finally {
      _isLoadingDiagnoses = false;
      notifyListeners();
    }
  }
}