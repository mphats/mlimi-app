import '../constants/app_constants.dart';
import '../utils/logger.dart';
import '../models/community_model.dart';
import '../utils/error_handler.dart';
import 'api_service.dart';

class CommunityService {
  final ApiService _apiService = ApiService();

  // Get community posts with filtering and pagination
  Future<CommunityResult> getPosts({
    String? category,
    String? search,
    bool? isQuestion,
    bool? isResolved,
    int page = 1,
    int pageSize = 20,
    String orderBy = '-created_at',
    bool useCache = true, // Enable caching by default
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
        'ordering': orderBy,
      };

      if (category != null && category.isNotEmpty) {
        queryParameters['category'] = category;
      }
      if (search != null && search.isNotEmpty) {
        queryParameters['search'] = search;
      }
      if (isQuestion != null) {
        queryParameters['is_question'] = isQuestion;
      }
      if (isResolved != null) {
        queryParameters['is_resolved'] = isResolved;
      }

      final response = await _apiService.get(
        AppConstants.communityPosts,
        queryParameters: queryParameters,
        useCache: useCache,
        cacheExpirySeconds: 300, // Cache for 5 minutes
      );

      if (response.statusCode == 200) {
        List<CommunityPostModel> posts = [];
        int totalCount = 0;
        bool hasNext = false;
        bool hasPrevious = false;

        // Handle both paginated and non-paginated responses
        if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          // Paginated format
          if (data['results'] is List) {
            posts = (data['results'] as List)
                .map(
                  (json) =>
                      CommunityPostModel.fromJson(json as Map<String, dynamic>),
                )
                .toList();
          }
          totalCount = data['count'] is int ? data['count'] as int : 0;
          hasNext = data['next'] != null;
          hasPrevious = data['previous'] != null;
        } else if (response.data is List) {
          // Non-paginated format - direct list of posts
          posts = (response.data as List)
              .map(
                (json) =>
                    CommunityPostModel.fromJson(json as Map<String, dynamic>),
              )
              .toList();
          totalCount = posts.length;
        }

        return CommunityResult.success(
          posts: posts,
          totalCount: totalCount,
          hasNext: hasNext,
          hasPrevious: hasPrevious,
        );
      }

      return CommunityResult.failure(ErrorHandler.formatApiErrorMessage(response.data));
    } on ApiException catch (e) {
      return CommunityResult.failure('Failed to fetch posts: ${ErrorHandler.formatApiErrorMessage(e.message)}');
    } catch (e) {
      return CommunityResult.failure(ErrorHandler.handleException(e));
    }
  }

  // Get post by ID with replies
  Future<CommunityResult> getPost(int postId, {bool useCache = true}) async {
    try {
      final response = await _apiService.get(
        '${AppConstants.communityPosts}/$postId',
        useCache: useCache,
        cacheExpirySeconds: 600, // Cache for 10 minutes
      );

      if (response.statusCode == 200) {
        // Check if response.data is a Map before casting
        if (response.data is Map<String, dynamic>) {
          final post = CommunityPostModel.fromJson(
            response.data as Map<String, dynamic>,
          );
          return CommunityResult.success(posts: [post]);
        } else if (response.data is List) {
          // If we get a list, it's unexpected - return an error
          return CommunityResult.failure(
            'Invalid response format: Expected a single post object but received a list',
          );
        } else {
          // If we get something else, it's also unexpected
          return CommunityResult.failure(
            'Invalid response format: Expected a single post object',
          );
        }
      }

      return CommunityResult.failure(ErrorHandler.formatApiErrorMessage(response.data));
    } on ApiException catch (e) {
      return CommunityResult.failure('Failed to fetch post: ${ErrorHandler.formatApiErrorMessage(e.message)}');
    } catch (e) {
      return CommunityResult.failure(ErrorHandler.handleException(e));
    }
  }

  // Create new post
  Future<CommunityResult> createPost(CommunityPostCreateRequest request) async {
    try {
      final response = await _apiService.post(
        AppConstants.communityPosts,
        data: request.toJson(),
      );

      if (response.statusCode == 201) {
        final post = CommunityPostModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return CommunityResult.success(
          posts: [post],
          message: 'Post created successfully',
        );
      }

      return CommunityResult.failure(ErrorHandler.formatApiErrorMessage(response.data));
    } on ValidationException catch (e) {
      return CommunityResult.failure('Validation error: ${ErrorHandler.formatApiErrorMessage(e.message)}');
    } on ApiException catch (e) {
      return CommunityResult.failure('Failed to create post: ${ErrorHandler.formatApiErrorMessage(e.message)}');
    } catch (e) {
      return CommunityResult.failure(ErrorHandler.handleException(e));
    }
  }

  // Update post
  Future<CommunityResult> updatePost(
    int postId,
    CommunityPostCreateRequest request,
  ) async {
    try {
      final response = await _apiService.put(
        '${AppConstants.communityPosts}/$postId',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final post = CommunityPostModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return CommunityResult.success(
          posts: [post],
          message: 'Post updated successfully',
        );
      }

      return CommunityResult.failure(ErrorHandler.formatApiErrorMessage(response.data));
    } on ValidationException catch (e) {
      return CommunityResult.failure('Validation error: ${ErrorHandler.formatApiErrorMessage(e.message)}');
    } on ApiException catch (e) {
      return CommunityResult.failure('Failed to update post: ${ErrorHandler.formatApiErrorMessage(e.message)}');
    } catch (e) {
      return CommunityResult.failure(ErrorHandler.handleException(e));
    }
  }

  // Delete post
  Future<CommunityResult> deletePost(int postId) async {
    try {
      final response = await _apiService.delete(
        '${AppConstants.communityPosts}/$postId',
      );

      if (response.statusCode == 204) {
        return CommunityResult.success(
          posts: [],
          message: 'Post deleted successfully',
        );
      }

      return CommunityResult.failure(ErrorHandler.formatApiErrorMessage(response.data));
    } on ApiException catch (e) {
      return CommunityResult.failure('Failed to delete post: ${ErrorHandler.formatApiErrorMessage(e.message)}');
    } catch (e) {
      return CommunityResult.failure(ErrorHandler.handleException(e));
    }
  }

  // Add reply to post
  Future<CommunityResult> addReply(
    int postId,
    CommunityReplyCreateRequest request,
  ) async {
    try {
      // Fix the endpoint construction - replace {id} with the actual post ID
      final endpoint = AppConstants.communityReplies.replaceAll(
        '{id}',
        postId.toString(),
      );

      // Log the request for debugging
      assert(() {
        Logger.info('🟢 API Request: POST http://127.0.0.1:8000/api/v1$endpoint');
        Logger.info('📤 Request Data: ${request.toJson()}');
        return true;
      }());

      final response = await _apiService.post(endpoint, data: request.toJson());

      if (response.statusCode == 201) {
        // Check if response.data is a Map before casting
        if (response.data is Map<String, dynamic>) {
          final reply = CommunityReplyModel.fromJson(
            response.data as Map<String, dynamic>,
          );
          return CommunityResult.success(
            replies: [reply],
            message: 'Reply added successfully',
          );
        } else {
          return CommunityResult.failure(
            'Invalid response format: Expected a single reply object',
          );
        }
      }

      // Handle validation errors specifically
      if (response.statusCode == 400) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          // Extract error messages
          final errorMessages = <String>[];
          data.forEach((key, value) {
            if (value is List) {
              errorMessages.add('$key: ${value.join(', ')}');
            } else {
              errorMessages.add('$key: $value');
            }
          });
          return CommunityResult.failure(
            'Validation error: ${errorMessages.join('; ')}',
          );
        }
      }

      return CommunityResult.failure(ErrorHandler.formatApiErrorMessage(response.data));
    } on ValidationException catch (e) {
      return CommunityResult.failure('Validation error: ${ErrorHandler.formatApiErrorMessage(e.message)}');
    } on ApiException catch (e) {
      return CommunityResult.failure('Failed to add reply: ${ErrorHandler.formatApiErrorMessage(e.message)}');
    } catch (e) {
      return CommunityResult.failure(ErrorHandler.handleException(e));
    }
  }

  // Like/unlike post
  Future<CommunityResult> togglePostLike(int postId) async {
    try {
      final endpoint = AppConstants.postLike.replaceAll(
        '{id}',
        postId.toString(),
      );
      final response = await _apiService.post(endpoint);

      if (response.statusCode == 200) {
        final data = response.data;
        final isLiked = data['liked'] ?? false;
        final likeCount = data['like_count'] ?? 0;

        return CommunityResult.success(
          posts: [],
          message: isLiked ? 'Post liked' : 'Post unliked',
          extraData: {'is_liked': isLiked, 'like_count': likeCount},
        );
      }

      return CommunityResult.failure(ErrorHandler.formatApiErrorMessage(response.data));
    } on ApiException catch (e) {
      return CommunityResult.failure('Failed to toggle like: ${ErrorHandler.formatApiErrorMessage(e.message)}');
    } catch (e) {
      return CommunityResult.failure(ErrorHandler.handleException(e));
    }
  }

  // Like/unlike reply
  Future<CommunityResult> toggleReplyLike(int replyId) async {
    try {
      final endpoint = AppConstants.replyLike.replaceAll(
        '{id}',
        replyId.toString(),
      );
      final response = await _apiService.post(endpoint);

      if (response.statusCode == 200) {
        final data = response.data;
        final isLiked = data['liked'] ?? false;
        final likeCount = data['like_count'] ?? 0;

        return CommunityResult.success(
          replies: [],
          message: isLiked ? 'Reply liked' : 'Reply unliked',
          extraData: {'is_liked': isLiked, 'like_count': likeCount},
        );
      }

      return CommunityResult.failure(ErrorHandler.formatApiErrorMessage(response.data));
    } on ApiException catch (e) {
      return CommunityResult.failure('Failed to toggle reply like: ${ErrorHandler.formatApiErrorMessage(e.message)}');
    } catch (e) {
      return CommunityResult.failure(ErrorHandler.handleException(e));
    }
  }

  // Share post
  Future<CommunityResult> sharePost(int postId, String method) async {
    try {
      final endpoint = AppConstants.postShare.replaceAll(
        '{id}',
        postId.toString(),
      );
      final response = await _apiService.post(
        endpoint,
        data: {'method': method},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final shareCount = data['share_count'] ?? 0;

        return CommunityResult.success(
          posts: [],
          message: 'Post shared successfully',
          extraData: {'share_count': shareCount},
        );
      }

      return CommunityResult.failure(ErrorHandler.formatApiErrorMessage(response.data));
    } on ApiException catch (e) {
      return CommunityResult.failure('Failed to share post: ${ErrorHandler.formatApiErrorMessage(e.message)}');
    } catch (e) {
      return CommunityResult.failure(ErrorHandler.handleException(e));
    }
  }

  // Track post view
  Future<CommunityResult> trackPostView(int postId) async {
    try {
      final endpoint = AppConstants.postView.replaceAll(
        '{id}',
        postId.toString(),
      );
      final response = await _apiService.post(endpoint);

      if (response.statusCode == 200) {
        final data = response.data;
        final viewCount = data['view_count'] ?? 0;

        return CommunityResult.success(
          posts: [],
          message: 'Post view tracked',
          extraData: {'view_count': viewCount},
        );
      }

      return CommunityResult.failure(ErrorHandler.formatApiErrorMessage(response.data));
    } on ApiException catch (e) {
      return CommunityResult.failure('Failed to track post view: ${ErrorHandler.formatApiErrorMessage(e.message)}');
    } catch (e) {
      return CommunityResult.failure(ErrorHandler.handleException(e));
    }
  }

  // Mark reply as solution
  Future<CommunityResult> markReplyAsSolution(int replyId) async {
    try {
      final endpoint = AppConstants.markSolution.replaceAll(
        '{id}',
        replyId.toString(),
      );
      final response = await _apiService.post(endpoint);

      if (response.statusCode == 200) {
        // Check if response.data is a Map before casting
        if (response.data is Map<String, dynamic>) {
          final reply = CommunityReplyModel.fromJson(
            response.data as Map<String, dynamic>,
          );
          return CommunityResult.success(
            replies: [reply],
            message: 'Reply marked as solution',
          );
        } else {
          return CommunityResult.failure(
            'Invalid response format: Expected a single reply object',
          );
        }
      }

      return CommunityResult.failure(ErrorHandler.formatApiErrorMessage(response.data));
    } on ApiException catch (e) {
      return CommunityResult.failure('Failed to mark reply as solution: ${ErrorHandler.formatApiErrorMessage(e.message)}');
    } catch (e) {
      return CommunityResult.failure(ErrorHandler.handleException(e));
    }
  }

  // Get user's posts
  Future<CommunityResult> getUserPosts({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
        'user_posts': true, // Filter for current user's posts
        'ordering': '-created_at',
      };

      final response = await _apiService.get(
        AppConstants.communityPosts,
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        List<CommunityPostModel> posts = [];
        int totalCount = 0;
        bool hasNext = false;
        bool hasPrevious = false;

        // Handle both paginated and non-paginated responses
        if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          // Paginated format
          if (data['results'] is List) {
            posts = (data['results'] as List)
                .map(
                  (json) =>
                      CommunityPostModel.fromJson(json as Map<String, dynamic>),
                )
                .toList();
          }
          totalCount = data['count'] is int ? data['count'] as int : 0;
          hasNext = data['next'] != null;
          hasPrevious = data['previous'] != null;
        } else if (response.data is List) {
          // Non-paginated format - direct list of posts
          posts = (response.data as List)
              .map(
                (json) =>
                    CommunityPostModel.fromJson(json as Map<String, dynamic>),
              )
              .toList();
          totalCount = posts.length;
        }

        return CommunityResult.success(
          posts: posts,
          totalCount: totalCount,
          hasNext: hasNext,
          hasPrevious: hasPrevious,
        );
      }

      return CommunityResult.failure(ErrorHandler.formatApiErrorMessage(response.data));
    } on ApiException catch (e) {
      return CommunityResult.failure('Failed to fetch user posts: ${ErrorHandler.formatApiErrorMessage(e.message)}');
    } catch (e) {
      return CommunityResult.failure(ErrorHandler.handleException(e));
    }
  }
}

// Community service result wrapper
class CommunityResult {
  final bool isSuccess;
  final String message;
  final List<CommunityPostModel> posts;
  final List<CommunityReplyModel> replies;
  final int totalCount;
  final bool hasNext;
  final bool hasPrevious;
  final Map<String, dynamic>? extraData;

  CommunityResult._({
    required this.isSuccess,
    required this.message,
    required this.posts,
    required this.replies,
    this.totalCount = 0,
    this.hasNext = false,
    this.hasPrevious = false,
    this.extraData,
  });

  factory CommunityResult.success({
    List<CommunityPostModel> posts = const [],
    List<CommunityReplyModel> replies = const [],
    String message = 'Success',
    int totalCount = 0,
    bool hasNext = false,
    bool hasPrevious = false,
    Map<String, dynamic>? extraData,
  }) {
    return CommunityResult._(
      isSuccess: true,
      message: message,
      posts: posts,
      replies: replies,
      totalCount: totalCount,
      hasNext: hasNext,
      hasPrevious: hasPrevious,
      extraData: extraData,
    );
  }

  factory CommunityResult.failure(String message) {
    return CommunityResult._(
      isSuccess: false,
      message: message,
      posts: [],
      replies: [],
    );
  }

  bool get isFailure => !isSuccess;
  bool get hasPosts => posts.isNotEmpty;
  bool get hasReplies => replies.isNotEmpty;
  CommunityPostModel? get firstPost => posts.isNotEmpty ? posts.first : null;
  CommunityReplyModel? get firstReply =>
      replies.isNotEmpty ? replies.first : null;

  @override
  String toString() {
    return 'CommunityResult(isSuccess: $isSuccess, message: $message, postCount: ${posts.length}, replyCount: ${replies.length})';
  }
}
