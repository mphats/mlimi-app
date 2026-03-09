import '../constants/app_constants.dart';
import '../models/newsletter_model.dart';
import 'api_service.dart';

class NewsletterService {
  final ApiService _apiService = ApiService();

  // Get newsletters with optional filtering
  Future<NewsletterResult> getNewsletters({
    String? category,
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
    bool useCache = true,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };

      if (category != null && category.isNotEmpty) {
        queryParameters['category'] = category;
      }

      final response = await _apiService.get(
        AppConstants.newsletters,
        queryParameters: queryParameters,
        useCache: useCache,
        cacheExpirySeconds: 3600, // Cache for 1 hour
      );

      if (response.statusCode == 200) {
        List<NewsletterModel> newsletters = [];
        bool hasNext = false;
        bool hasPrevious = false;

        // Handle paginated response
        if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          if (data['results'] is List) {
            newsletters = (data['results'] as List)
                .map((json) => NewsletterModel.fromJson(json))
                .toList();
          }
          hasNext = data['next'] != null;
          hasPrevious = data['previous'] != null;
        } else if (response.data is List) {
          newsletters = (response.data as List)
              .map((json) => NewsletterModel.fromJson(json))
              .toList();
        }

        return NewsletterResult.success(
          newsletters: newsletters,
          hasNext: hasNext,
          hasPrevious: hasPrevious,
        );
      }

      return NewsletterResult.failure('Failed to fetch newsletters');
    } on ApiException catch (e) {
      return NewsletterResult.failure('Failed to fetch newsletters: ${e.message}');
    } catch (e) {
      return NewsletterResult.failure('Failed to fetch newsletters: ${e.toString()}');
    }
  }

  // Get newsletter by ID
  Future<NewsletterResult> getNewsletter(int id, {bool useCache = true}) async {
    try {
      final response = await _apiService.get(
        '${AppConstants.newsletters}/$id',
        useCache: useCache,
        cacheExpirySeconds: 3600, // Cache for 1 hour
      );

      if (response.statusCode == 200) {
        final newsletter = NewsletterModel.fromJson(response.data);
        return NewsletterResult.success(newsletters: [newsletter]);
      }

      return NewsletterResult.failure('Failed to fetch newsletter');
    } on ApiException catch (e) {
      return NewsletterResult.failure('Failed to fetch newsletter: ${e.message}');
    } catch (e) {
      return NewsletterResult.failure('Failed to fetch newsletter: ${e.toString()}');
    }
  }

  // Get user's newsletter subscriptions
  Future<NewsletterResult> getUserSubscriptions(String email) async {
    try {
      final response = await _apiService.get(
        AppConstants.newsletterSubscriptions,
        queryParameters: {
          'email': email,
        },
        useCache: false, // Don't cache user-specific data
      );

      if (response.statusCode == 200) {
        List<NewsletterSubscriptionModel> subscriptions = [];
        
        if (response.data is List) {
          subscriptions = (response.data as List)
              .map((json) => NewsletterSubscriptionModel.fromJson(json))
              .toList();
        }

        return NewsletterResult.success(
          message: 'Subscriptions retrieved successfully',
          newsletters: [], // Not used for subscriptions
          subscriptions: subscriptions,
        );
      }

      return NewsletterResult.failure('Failed to fetch subscriptions');
    } on ApiException catch (e) {
      return NewsletterResult.failure('Failed to fetch subscriptions: ${e.message}');
    } catch (e) {
      return NewsletterResult.failure('Failed to fetch subscriptions: ${e.toString()}');
    }
  }
  
  // Get all subscriptions (alias for getUserSubscriptions with current user)
  Future<NewsletterResult> getSubscriptions() async {
    // In a real implementation, you would get the current user's email
    // For now, we'll return an empty list
    return NewsletterResult.success(
      message: 'Subscriptions retrieved successfully',
      subscriptions: [],
    );
  }

  // Subscribe to newsletters
  Future<NewsletterResult> subscribeToNewsletter(String email, String category) async {
    try {
      final response = await _apiService.post(
        AppConstants.newsletterSubscriptions,
        data: {
          'email': email,
          'category': category,
        },
      );

      if (response.statusCode == 201) {
        return NewsletterResult.success(
          message: 'Successfully subscribed to $category newsletters',
        );
      }

      return NewsletterResult.failure('Failed to subscribe to newsletters');
    } on ApiException catch (e) {
      return NewsletterResult.failure('Failed to subscribe: ${e.message}');
    } catch (e) {
      return NewsletterResult.failure('Failed to subscribe: ${e.toString()}');
    }
  }

  // Unsubscribe from newsletters
  Future<NewsletterResult> unsubscribeFromNewsletter(String email, String category) async {
    try {
      // First, we need to find the subscription ID
      final subscriptionsResponse = await _apiService.get(
        AppConstants.newsletterSubscriptions,
        queryParameters: {
          'email': email,
          'category': category,
        },
      );

      if (subscriptionsResponse.statusCode == 200) {
        final subscriptions = (subscriptionsResponse.data as List)
            .map((json) => NewsletterSubscriptionModel.fromJson(json))
            .toList();

        if (subscriptions.isNotEmpty) {
          final subscriptionId = subscriptions.first.id;
          final response = await _apiService.delete(
            '${AppConstants.newsletterSubscriptions}/$subscriptionId',
          );

          if (response.statusCode == 204) {
            return NewsletterResult.success(
              message: 'Successfully unsubscribed from $category newsletters',
            );
          }
        }
      }

      return NewsletterResult.failure('Failed to unsubscribe from newsletters');
    } on ApiException catch (e) {
      return NewsletterResult.failure('Failed to unsubscribe: ${e.message}');
    } catch (e) {
      return NewsletterResult.failure('Failed to unsubscribe: ${e.toString()}');
    }
  }
}

// Newsletter service result wrapper
class NewsletterResult {
  final bool isSuccess;
  final String message;
  final List<NewsletterModel> newsletters;
  final List<NewsletterSubscriptionModel> subscriptions;
  final bool hasNext;
  final bool hasPrevious;

  NewsletterResult._({
    required this.isSuccess,
    required this.message,
    List<NewsletterModel>? newsletters,
    List<NewsletterSubscriptionModel>? subscriptions,
    this.hasNext = false,
    this.hasPrevious = false,
  })  : newsletters = newsletters ?? [],
        subscriptions = subscriptions ?? [];

  factory NewsletterResult.success({
    List<NewsletterModel>? newsletters,
    List<NewsletterSubscriptionModel>? subscriptions,
    String message = 'Success',
    bool hasNext = false,
    bool hasPrevious = false,
  }) {
    return NewsletterResult._(
      isSuccess: true,
      message: message,
      newsletters: newsletters,
      subscriptions: subscriptions,
      hasNext: hasNext,
      hasPrevious: hasPrevious,
    );
  }

  factory NewsletterResult.failure(String message) {
    return NewsletterResult._(isSuccess: false, message: message);
  }

  bool get isFailure => !isSuccess;
  bool get hasNewsletters => newsletters.isNotEmpty;
  bool get hasSubscriptions => subscriptions.isNotEmpty;
  bool get hasData => hasNewsletters || hasSubscriptions;
  List<NewsletterModel> get data => newsletters;
  
  NewsletterModel? get firstNewsletter =>
      newsletters.isNotEmpty ? newsletters.first : null;

  @override
  String toString() {
    return 'NewsletterResult(isSuccess: $isSuccess, message: $message, newslettersCount: ${newsletters.length}, subscriptionsCount: ${subscriptions.length})';
  }
}