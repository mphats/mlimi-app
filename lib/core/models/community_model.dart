import 'user_model.dart';

class CommunityPostModel {
  final int id;
  final UserModel author;
  final String title;
  final String content;
  final String category;
  final bool isQuestion;
  final bool isResolved;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likeCount;
  final int viewCount;
  final int shareCount;
  final int replyCount;
  final bool isLikedByUser;
  final List<CommunityReplyModel> replies;

  CommunityPostModel({
    required this.id,
    required this.author,
    required this.title,
    required this.content,
    required this.category,
    this.isQuestion = false,
    this.isResolved = false,
    required this.createdAt,
    required this.updatedAt,
    this.likeCount = 0,
    this.viewCount = 0,
    this.shareCount = 0,
    this.replyCount = 0,
    this.isLikedByUser = false,
    this.replies = const [],
  });

  factory CommunityPostModel.fromJson(Map<String, dynamic> json) {
    try {
      // Ensure replies is properly handled
      List<CommunityReplyModel> repliesList = [];
      if (json['replies'] is List) {
        repliesList = (json['replies'] as List)
            .map(
              (reply) => reply is Map<String, dynamic>
                  ? CommunityReplyModel.fromJson(reply)
                  : CommunityReplyModel.fromJson({}),
            )
            .toList();
      }

      // Safely parse all integer values
      final idValue = json['id'];
      final id = idValue is int
          ? idValue
          : (idValue is String ? int.parse(idValue) : 0);

      final likeCountValue = json['like_count'];
      final likeCount = likeCountValue is int
          ? likeCountValue
          : (likeCountValue is String ? int.tryParse(likeCountValue) ?? 0 : 0);

      final viewCountValue = json['view_count'];
      final viewCount = viewCountValue is int
          ? viewCountValue
          : (viewCountValue is String ? int.tryParse(viewCountValue) ?? 0 : 0);

      final shareCountValue = json['share_count'];
      final shareCount = shareCountValue is int
          ? shareCountValue
          : (shareCountValue is String
                ? int.tryParse(shareCountValue) ?? 0
                : 0);

      final replyCountValue = json['reply_count'];
      final replyCount = replyCountValue is int
          ? replyCountValue
          : (replyCountValue is String
                ? int.tryParse(replyCountValue) ?? 0
                : 0);

      // Handle author data with better fallback
      UserModel author;
      if (json['author'] is Map<String, dynamic>) {
        author = UserModel.fromJson(json['author'] as Map<String, dynamic>);
      } else {
        // Create a default user with meaningful values
        author = UserModel(
          id: 0,
          username: 'unknown_author',
          email: '',
          role: 'FARMER',
          isActive: true,
        );
      }

      return CommunityPostModel(
        id: id,
        author: author,
        title: json['title'] is String ? json['title'] : 'Untitled Post',
        content: json['content'] is String
            ? json['content']
            : 'No content available',
        category: json['category'] is String ? json['category'] : 'general',
        isQuestion: json['is_question'] is bool ? json['is_question'] : false,
        isResolved: json['is_resolved'] is bool ? json['is_resolved'] : false,
        createdAt: json['created_at'] is String
            ? DateTime.parse(json['created_at'])
            : DateTime.now(),
        updatedAt: json['updated_at'] is String
            ? DateTime.parse(json['updated_at'])
            : DateTime.now(),
        likeCount: likeCount,
        viewCount: viewCount,
        shareCount: shareCount,
        replyCount: replyCount,
        isLikedByUser: json['is_liked_by_user'] is bool
            ? json['is_liked_by_user']
            : false,
        replies: repliesList,
      );
    } catch (e) {
      // Return a default CommunityPostModel if parsing fails
      return CommunityPostModel(
        id: 0,
        author: UserModel(
          id: 0,
          username: 'unknown_author',
          email: '',
          role: 'FARMER',
          isActive: false,
        ),
        title: 'Failed to Load Post',
        content: 'Failed to load post details',
        category: 'general',
        isQuestion: false,
        isResolved: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        likeCount: 0,
        viewCount: 0,
        shareCount: 0,
        replyCount: 0,
        isLikedByUser: false,
        replies: [],
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author': author.toJson(),
      'title': title,
      'content': content,
      'category': category,
      'is_question': isQuestion,
      'is_resolved': isResolved,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'like_count': likeCount,
      'view_count': viewCount,
      'share_count': shareCount,
      'reply_count': replyCount,
      'is_liked_by_user': isLikedByUser,
      'replies': replies.map((reply) => reply.toJson()).toList(),
    };
  }

  String get categoryDisplayName {
    switch (category) {
      case 'question':
        return 'Question';
      case 'advice':
        return 'Advice';
      case 'discussion':
        return 'Discussion';
      case 'experience':
        return 'Experience';
      case 'problem':
        return 'Problem';
      case 'solution':
        return 'Solution';
      case 'general':
        return 'General';
      default:
        return category;
    }
  }

  String get statusText {
    if (isQuestion) {
      return isResolved ? 'Resolved' : 'Unresolved';
    }
    return '';
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  bool get hasReplies {
    return replies.isNotEmpty || replyCount > 0;
  }

  List<CommunityReplyModel> get solutionReplies {
    return replies.where((reply) => reply.isSolution).toList();
  }

  CommunityPostModel copyWith({
    int? id,
    UserModel? author,
    String? title,
    String? content,
    String? category,
    bool? isQuestion,
    bool? isResolved,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likeCount,
    int? viewCount,
    int? shareCount,
    int? replyCount,
    bool? isLikedByUser,
    List<CommunityReplyModel>? replies,
  }) {
    return CommunityPostModel(
      id: id ?? this.id,
      author: author ?? this.author,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      isQuestion: isQuestion ?? this.isQuestion,
      isResolved: isResolved ?? this.isResolved,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likeCount: likeCount ?? this.likeCount,
      viewCount: viewCount ?? this.viewCount,
      shareCount: shareCount ?? this.shareCount,
      replyCount: replyCount ?? this.replyCount,
      isLikedByUser: isLikedByUser ?? this.isLikedByUser,
      replies: replies ?? this.replies,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommunityPostModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CommunityPostModel(id: $id, title: $title, category: $category, author: ${author.username})';
  }
}

class CommunityReplyModel {
  final int id;
  final UserModel author;
  final String content;
  final bool isSolution;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likeCount;
  final bool isLikedByUser;

  CommunityReplyModel({
    required this.id,
    required this.author,
    required this.content,
    this.isSolution = false,
    required this.createdAt,
    required this.updatedAt,
    this.likeCount = 0,
    this.isLikedByUser = false,
  });

  factory CommunityReplyModel.fromJson(Map<String, dynamic> json) {
    try {
      // Safely parse all integer values
      final idValue = json['id'];
      final id = idValue is int
          ? idValue
          : (idValue is String ? int.parse(idValue) : 0);

      final likeCountValue = json['like_count'];
      final likeCount = likeCountValue is int
          ? likeCountValue
          : (likeCountValue is String ? int.tryParse(likeCountValue) ?? 0 : 0);

      // Handle author data with better fallback
      UserModel author;
      if (json['author'] is Map<String, dynamic>) {
        author = UserModel.fromJson(json['author'] as Map<String, dynamic>);
      } else {
        // Create a default user with meaningful values
        author = UserModel(
          id: 0,
          username: 'unknown_author',
          email: '',
          role: 'FARMER',
          isActive: true,
        );
      }

      return CommunityReplyModel(
        id: id,
        author: author,
        content: json['content'] is String
            ? json['content']
            : 'No content available',
        isSolution: json['is_solution'] is bool ? json['is_solution'] : false,
        createdAt: json['created_at'] is String
            ? DateTime.parse(json['created_at'])
            : DateTime.now(),
        updatedAt: json['updated_at'] is String
            ? DateTime.parse(json['updated_at'])
            : DateTime.now(),
        likeCount: likeCount,
        isLikedByUser: json['is_liked_by_user'] is bool
            ? json['is_liked_by_user']
            : false,
      );
    } catch (e) {
      // Return a default CommunityReplyModel if parsing fails
      return CommunityReplyModel(
        id: 0,
        author: UserModel(
          id: 0,
          username: 'unknown_author',
          email: '',
          role: 'FARMER',
          isActive: false,
        ),
        content: 'Failed to load reply',
        isSolution: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        likeCount: 0,
        isLikedByUser: false,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author': author.toJson(),
      'content': content,
      'is_solution': isSolution,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'like_count': likeCount,
      'is_liked_by_user': isLikedByUser,
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  CommunityReplyModel copyWith({
    int? id,
    UserModel? author,
    String? content,
    bool? isSolution,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likeCount,
    bool? isLikedByUser,
  }) {
    return CommunityReplyModel(
      id: id ?? this.id,
      author: author ?? this.author,
      content: content ?? this.content,
      isSolution: isSolution ?? this.isSolution,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likeCount: likeCount ?? this.likeCount,
      isLikedByUser: isLikedByUser ?? this.isLikedByUser,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommunityReplyModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CommunityReplyModel(id: $id, author: ${author.username}, isSolution: $isSolution)';
  }
}

// Community post creation request model
class CommunityPostCreateRequest {
  final String title;
  final String content;
  final String category;
  final bool isQuestion;

  CommunityPostCreateRequest({
    required this.title,
    required this.content,
    required this.category,
    this.isQuestion = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'category': category,
      'is_question': isQuestion,
    };
  }
}

// Community reply creation request model
class CommunityReplyCreateRequest {
  final String content;
  final int postId;

  CommunityReplyCreateRequest({required this.content, required this.postId});

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'post': postId, // This should be 'post' to match the API expectation
    };
  }
}
