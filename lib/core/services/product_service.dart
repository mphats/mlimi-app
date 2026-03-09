import 'dart:io';
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../models/product_model.dart';
import 'api_service.dart';
import '../utils/logger.dart'; // Add logger import

class ProductService {
  final ApiService _apiService = ApiService();

  // Get products with filtering and pagination
  Future<ProductResult> getProducts({
    String? category,
    String? location,
    String? search,
    int page = 1,
    int pageSize = 20,
    bool useCache = true, // Enable caching by default
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
        AppConstants.products,
        queryParameters: queryParameters,
        useCache: useCache,
        cacheExpirySeconds: 300, // Cache for 5 minutes
      );

      if (response.statusCode == 200) {
        List<ProductModel> products = [];
        int totalCount = 0;
        bool hasNext = false;
        bool hasPrevious = false;

        // Handle both paginated and non-paginated responses
        if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          // Paginated format
          if (data['results'] is List) {
            products = (data['results'] as List)
                .map(
                  (json) =>
                      ProductModel.fromJson(json as Map<String, dynamic>),
                )
                .toList();
          }
          totalCount = data['count'] is int ? data['count'] as int : 0;
          hasNext = data['next'] != null;
          hasPrevious = data['previous'] != null;
        } else if (response.data is List) {
          // Non-paginated format - direct list of products
          products = (response.data as List)
              .map(
                (json) =>
                    ProductModel.fromJson(json as Map<String, dynamic>),
              )
              .toList();
          totalCount = products.length;
        }

        return ProductResult.success(
          products: products,
          totalCount: totalCount,
          hasNext: hasNext,
          hasPrevious: hasPrevious,
        );
      }

      return ProductResult.failure('Failed to fetch products');
    } on ApiException catch (e) {
      return ProductResult.failure('Failed to fetch products: ${e.message}');
    } catch (e) {
      return ProductResult.failure('Failed to fetch products: ${e.toString()}');
    }
  }

  // Get product by ID
  Future<ProductResult> getProduct(
    int productId, {
    bool useCache = true,
  }) async {
    try {
      final response = await _apiService.get(
        '${AppConstants.products}/$productId',
        useCache: useCache,
        cacheExpirySeconds: 600, // Cache for 10 minutes
      );

      if (response.statusCode == 200) {
        // Check if response.data is a Map before casting
        if (response.data is Map<String, dynamic>) {
          final product = ProductModel.fromJson(
            response.data as Map<String, dynamic>,
          );
          return ProductResult.success(products: [product]);
        } else if (response.data is List) {
          // If we get a list, it's unexpected - return an error
          return ProductResult.failure(
            'Invalid response format: Expected a single product object but received a list',
          );
        } else {
          // If we get something else, it's also unexpected
          return ProductResult.failure(
            'Invalid response format: Expected a single product object',
          );
        }
      }

      return ProductResult.failure('Product not found');
    } on ApiException catch (e) {
      return ProductResult.failure('Failed to fetch product: ${e.message}');
    } catch (e) {
      return ProductResult.failure('Failed to fetch product: ${e.toString()}');
    }
  }

  // Create new product
  Future<ProductResult> createProduct(ProductCreateRequest request) async {
    try {
      final response = await _apiService.post(
        AppConstants.products,
        data: request.toJson(),
      );

      if (response.statusCode == 201) {
        final product = ProductModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return ProductResult.success(
          products: [product],
          message: 'Product created successfully',
        );
      }

      return ProductResult.failure('Failed to create product');
    } on ValidationException catch (e) {
      return ProductResult.failure('Validation error: ${e.message}');
    } on ApiException catch (e) {
      return ProductResult.failure('Failed to create product: ${e.message}');
    } catch (e) {
      return ProductResult.failure('Failed to create product: ${e.toString()}');
    }
  }

  // Update product
  Future<ProductResult> updateProduct(
    int productId,
    ProductCreateRequest request,
  ) async {
    try {
      final response = await _apiService.put(
        '${AppConstants.products}/$productId',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        // Check if response.data is a Map before casting
        if (response.data is Map<String, dynamic>) {
          final product = ProductModel.fromJson(
            response.data as Map<String, dynamic>,
          );
          return ProductResult.success(
            products: [product],
            message: 'Product updated successfully',
          );
        } else {
          return ProductResult.failure(
            'Invalid response format: Expected a single product object',
          );
        }
      }

      return ProductResult.failure('Failed to update product');
    } on ValidationException catch (e) {
      return ProductResult.failure('Validation error: ${e.message}');
    } on ApiException catch (e) {
      return ProductResult.failure('Failed to update product: ${e.message}');
    } catch (e) {
      return ProductResult.failure('Failed to update product: ${e.toString()}');
    }
  }

  // Delete product
  Future<ProductResult> deleteProduct(int productId) async {
    try {
      final response = await _apiService.delete(
        '${AppConstants.products}/$productId',
      );

      if (response.statusCode == 204) {
        return ProductResult.success(
          products: [],
          message: 'Product deleted successfully',
        );
      }

      return ProductResult.failure('Failed to delete product');
    } on ApiException catch (e) {
      return ProductResult.failure('Failed to delete product: ${e.message}');
    } catch (e) {
      return ProductResult.failure('Failed to delete product: ${e.toString()}');
    }
  }

  // Upload product images
  Future<ProductResult> uploadProductImages(
    int productId,
    List<File> images,
  ) async {
    try {
      Logger.debug('Starting to upload ${images.length} images for product ID: $productId');
      
      // Upload images one by one to match backend expectation
      List<String> uploadedImages = [];
      String errorMessage = '';
      
      for (int i = 0; i < images.length; i++) {
        final File imageFile = images[i];
        Logger.debug('Uploading image ${i + 1} of ${images.length}: ${imageFile.path}');
        
        // Check if file exists and is readable
        if (!await imageFile.exists()) {
          errorMessage = 'Image file does not exist: ${imageFile.path}';
          Logger.error(errorMessage);
          break;
        }
        
        final formData = FormData();
        formData.files.add(
          MapEntry(
            'image', // Changed from 'images' to 'image' to match backend expectation
            await MultipartFile.fromFile(
              imageFile.path,
              filename: 'product_image_$i.jpg',
            ),
          ),
        );

        final endpoint = AppConstants.productImages.replaceAll(
          '{id}',
          productId.toString(),
        );
        Logger.debug('Uploading to endpoint: $endpoint');
        
        try {
          final response = await _apiService.postMultipart(endpoint, formData);
          Logger.debug('Image upload response status: ${response.statusCode}');
          
          if (response.statusCode == 201) {
            uploadedImages.add('product_image_$i.jpg');
            Logger.debug('Successfully uploaded image ${i + 1}');
          } else {
            errorMessage = 'Failed to upload image ${i + 1} - Status: ${response.statusCode}, Response: ${response.data}';
            Logger.error(errorMessage);
            break; // Stop on first failure
          }
        } catch (e) {
          errorMessage = 'Error uploading image ${i + 1}: ${e.toString()}';
          Logger.error(errorMessage);
          break; // Stop on first failure
        }
      }
      
      // Check if all images were uploaded successfully
      if (uploadedImages.length == images.length) {
        Logger.debug('Successfully uploaded all ${uploadedImages.length} images');
        return ProductResult.success(
          products: [],
          message: 'All images uploaded successfully ($uploadedImages.length images)',
        );
      } else {
        Logger.error('Failed to upload all images. Uploaded ${uploadedImages.length} of ${images.length} images. Error: $errorMessage');
        return ProductResult.failure('Failed to upload images: $errorMessage. Uploaded ${uploadedImages.length} of ${images.length} images.');
      }
    } on ApiException catch (e) {
      Logger.error('API Exception during image upload: ${e.message}');
      return ProductResult.failure('Failed to upload images: ${e.message}');
    } catch (e) {
      Logger.error('Exception during image upload: ${e.toString()}');
      return ProductResult.failure('Failed to upload images: ${e.toString()}');
    }
  }

  // Get user's products
  Future<ProductResult> getUserProducts({
    int page = 1,
    int pageSize = 20,
    bool useCache = false, // Don't cache user-specific data by default
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
        'user_products': true, // Filter for current user's products
      };

      final response = await _apiService.get(
        AppConstants.products,
        queryParameters: queryParameters,
        useCache: useCache,
      );

      if (response.statusCode == 200) {
        List<ProductModel> products = [];
        int totalCount = 0;
        bool hasNext = false;
        bool hasPrevious = false;

        // Handle both paginated and non-paginated responses
        if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          // Paginated format
          if (data['results'] is List) {
            products = (data['results'] as List)
                .map(
                  (json) =>
                      ProductModel.fromJson(json as Map<String, dynamic>),
                )
                .toList();
          }
          totalCount = data['count'] is int ? data['count'] as int : 0;
          hasNext = data['next'] != null;
          hasPrevious = data['previous'] != null;
        } else if (response.data is List) {
          // Non-paginated format - direct list of products
          products = (response.data as List)
              .map(
                (json) =>
                    ProductModel.fromJson(json as Map<String, dynamic>),
              )
              .toList();
          totalCount = products.length;
        }

        return ProductResult.success(
          products: products,
          totalCount: totalCount,
          hasNext: hasNext,
          hasPrevious: hasPrevious,
        );
      }

      return ProductResult.failure('Failed to fetch user products');
    } on ApiException catch (e) {
      return ProductResult.failure(
        'Failed to fetch user products: ${e.message}',
      );
    } catch (e) {
      return ProductResult.failure(
        'Failed to fetch user products: ${e.toString()}',
      );
    }
  }

  // Toggle product active status
  Future<ProductResult> toggleProductStatus(
    int productId,
    bool isActive,
  ) async {
    try {
      final response = await _apiService.patch(
        '${AppConstants.products}/$productId',
        data: {'is_active': isActive},
      );

      if (response.statusCode == 200) {
        final product = ProductModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return ProductResult.success(
          products: [product],
          message: isActive ? 'Product activated' : 'Product deactivated',
        );
      }

      return ProductResult.failure('Failed to update product status');
    } on ApiException catch (e) {
      return ProductResult.failure(
        'Failed to update product status: ${e.message}',
      );
    } catch (e) {
      return ProductResult.failure(
        'Failed to update product status: ${e.toString()}',
      );
    }
  }
}

// Product service result wrapper
class ProductResult {
  final bool isSuccess;
  final String message;
  final List<ProductModel> products;
  final int totalCount;
  final bool hasNext;
  final bool hasPrevious;

  ProductResult._({
    required this.isSuccess,
    required this.message,
    required this.products,
    this.totalCount = 0,
    this.hasNext = false,
    this.hasPrevious = false,
  });

  factory ProductResult.success({
    required List<ProductModel> products,
    String message = 'Success',
    int totalCount = 0,
    bool hasNext = false,
    bool hasPrevious = false,
  }) {
    return ProductResult._(
      isSuccess: true,
      message: message,
      products: products,
      totalCount: totalCount,
      hasNext: hasNext,
      hasPrevious: hasPrevious,
    );
  }

  factory ProductResult.failure(String message) {
    return ProductResult._(isSuccess: false, message: message, products: []);
  }

  bool get isFailure => !isSuccess;
  bool get hasProducts => products.isNotEmpty;
  ProductModel? get firstProduct => products.isNotEmpty ? products.first : null;

  @override
  String toString() {
    return 'ProductResult(isSuccess: $isSuccess, message: $message, productCount: ${products.length})';
  }
}
