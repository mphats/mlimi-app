import '../constants/app_constants.dart';
import '../models/market_price_model.dart';
import 'api_service.dart';

class MarketPriceService {
  final ApiService _apiService = ApiService();

  // Get market prices with filtering and pagination
  Future<MarketPriceResult> getMarketPrices({
    String? category,
    String? location,
    String? search,
    int page = 1,
    int pageSize = 20,
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
      if (location != null && location.isNotEmpty) {
        queryParameters['location'] = location;
      }
      if (search != null && search.isNotEmpty) {
        queryParameters['search'] = search;
      }

      final response = await _apiService.get(
        AppConstants.marketPrices,
        queryParameters: queryParameters,
        useCache: useCache,
        cacheExpirySeconds: 300, // Cache for 5 minutes
      );

      if (response.statusCode == 200) {
        List<MarketPriceModel> prices = [];
        int totalCount = 0;
        bool hasNext = false;
        bool hasPrevious = false;

        // Handle both paginated and non-paginated responses
        if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          // Paginated format
          if (data['results'] is List) {
            prices = (data['results'] as List)
                .map(
                  (json) => MarketPriceModel.fromJson(
                      json as Map<String, dynamic>),
                )
                .toList();
          }
          totalCount = data['count'] is int ? data['count'] as int : 0;
          hasNext = data['next'] != null;
          hasPrevious = data['previous'] != null;
        } else if (response.data is List) {
          // Non-paginated format - direct list of market prices
          prices = (response.data as List)
              .map(
                (json) =>
                    MarketPriceModel.fromJson(json as Map<String, dynamic>),
              )
              .toList();
          totalCount = prices.length;
        }

        return MarketPriceResult.success(
          prices: prices,
          totalCount: totalCount,
          hasNext: hasNext,
          hasPrevious: hasPrevious,
        );
      }

      return MarketPriceResult.failure('Failed to fetch market prices');
    } on ApiException catch (e) {
      return MarketPriceResult.failure(
        'Failed to fetch market prices: ${e.message}',
      );
    } catch (e) {
      return MarketPriceResult.failure(
        'Failed to fetch market prices: ${e.toString()}',
      );
    }
  }

  // Get trending market prices
  Future<MarketPriceResult> getTrendingPrices({
    int limit = 10,
    bool useCache = true,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'limit': limit,
        'ordering': '-view_count',
      };

      final response = await _apiService.get(
        AppConstants.marketPrices,
        queryParameters: queryParameters,
        useCache: useCache,
        cacheExpirySeconds: 600, // Cache for 10 minutes
      );

      if (response.statusCode == 200) {
        List<MarketPriceModel> prices = [];

        // Handle both paginated and non-paginated responses
        if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          // Paginated format
          if (data['results'] is List) {
            prices = (data['results'] as List)
                .map(
                  (json) => MarketPriceModel.fromJson(
                      json as Map<String, dynamic>),
                )
                .toList();
          }
        } else if (response.data is List) {
          // Non-paginated format - direct list of market prices
          prices = (response.data as List)
              .map(
                (json) =>
                    MarketPriceModel.fromJson(json as Map<String, dynamic>),
              )
              .toList();
        }

        return MarketPriceResult.success(prices: prices);
      }

      return MarketPriceResult.failure('Failed to fetch trending prices');
    } on ApiException catch (e) {
      return MarketPriceResult.failure(
        'Failed to fetch trending prices: ${e.message}',
      );
    } catch (e) {
      return MarketPriceResult.failure(
        'Failed to fetch trending prices: ${e.toString()}',
      );
    }
  }

  // Create new market price entry
  Future<MarketPriceResult> createMarketPrice(
    MarketPriceCreateRequest request,
  ) async {
    try {
      final response = await _apiService.post(
        AppConstants.marketPrices,
        data: request.toJson(),
      );

      if (response.statusCode == 201) {
        // Check if response.data is a Map before casting
        if (response.data is Map<String, dynamic>) {
          final price = MarketPriceModel.fromJson(
            response.data as Map<String, dynamic>,
          );
          return MarketPriceResult.success(
            prices: [price],
            message: 'Market price created successfully',
          );
        } else if (response.data is List) {
          // If we get a list, it's unexpected - return an error
          return MarketPriceResult.failure(
            'Invalid response format: Expected a single market price object but received a list',
          );
        } else {
          // If we get something else, it's also unexpected
          return MarketPriceResult.failure(
            'Invalid response format: Expected a single market price object',
          );
        }
      }

      return MarketPriceResult.failure('Failed to create market price');
    } on ValidationException catch (e) {
      return MarketPriceResult.failure('Validation error: ${e.message}');
    } on ApiException catch (e) {
      return MarketPriceResult.failure(
        'Failed to create market price: ${e.message}',
      );
    } catch (e) {
      return MarketPriceResult.failure(
        'Failed to create market price: ${e.toString()}',
      );
    }
  }
}

// Market price service result wrapper
class MarketPriceResult {
  final bool isSuccess;
  final String message;
  final List<MarketPriceModel> prices;
  final int totalCount;
  final bool hasNext;
  final bool hasPrevious;

  MarketPriceResult._({
    required this.isSuccess,
    required this.message,
    required this.prices,
    this.totalCount = 0,
    this.hasNext = false,
    this.hasPrevious = false,
  });

  factory MarketPriceResult.success({
    required List<MarketPriceModel> prices,
    String message = 'Success',
    int totalCount = 0,
    bool hasNext = false,
    bool hasPrevious = false,
  }) {
    return MarketPriceResult._(
      isSuccess: true,
      message: message,
      prices: prices,
      totalCount: totalCount,
      hasNext: hasNext,
      hasPrevious: hasPrevious,
    );
  }

  factory MarketPriceResult.failure(String message) {
    return MarketPriceResult._(isSuccess: false, message: message, prices: []);
  }

  bool get isFailure => !isSuccess;
  bool get hasPrices => prices.isNotEmpty;
  MarketPriceModel? get firstPrice => prices.isNotEmpty ? prices.first : null;

  @override
  String toString() {
    return 'MarketPriceResult(isSuccess: $isSuccess, message: $message, priceCount: ${prices.length})';
  }
}
