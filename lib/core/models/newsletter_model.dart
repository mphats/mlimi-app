class NewsletterModel {
  final int id;
  final String title;
  final String content;
  final String category;
  final String language;
  final bool isPublished;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  NewsletterModel({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.language,
    required this.isPublished,
    this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NewsletterModel.fromJson(Map<String, dynamic> json) {
    return NewsletterModel(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      category: json['category'],
      language: json['language'],
      isPublished: json['is_published'],
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'language': language,
      'is_published': isPublished,
      'published_at': publishedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get categoryDisplay {
    switch (category) {
      case 'tips':
        return 'Farming Tips';
      case 'market_trends':
        return 'Market Trends';
      case 'seasonal_advice':
        return 'Seasonal Advice';
      case 'pest_control':
        return 'Pest Control';
      case 'weather':
        return 'Weather Updates';
      case 'technology':
        return 'Technology';
      case 'success_stories':
        return 'Success Stories';
      default:
        return category;
    }
  }

  String get languageDisplay {
    switch (language) {
      case 'EN':
        return 'English';
      case 'CH':
        return 'Chichewa';
      default:
        return language;
    }
  }

  String get publishedAtDisplay {
    if (publishedAt == null) return 'Not published';
    final now = DateTime.now();
    final difference = now.difference(publishedAt!);

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

  String get contentPreview {
    if (content.length <= 100) return content;
    return '${content.substring(0, 100)}...';
  }

  NewsletterModel copyWith({
    int? id,
    String? title,
    String? content,
    String? category,
    String? language,
    bool? isPublished,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NewsletterModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      language: language ?? this.language,
      isPublished: isPublished ?? this.isPublished,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NewsletterModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'NewsletterModel(id: $id, title: $title, category: $category, language: $language)';
  }
}

class NewsletterSubscriptionModel {
  final int? id;
  final String email;
  final String category;
  final bool isActive;
  final DateTime? subscribedAt;
  final DateTime? updatedAt;

  NewsletterSubscriptionModel({
    this.id,
    required this.email,
    required this.category,
    this.isActive = true,
    this.subscribedAt,
    this.updatedAt,
  });

  factory NewsletterSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return NewsletterSubscriptionModel(
      id: json['id'] as int?,
      email: json['email'] as String,
      category: json['category'] as String,
      isActive: json['is_active'] as bool? ?? true,
      subscribedAt: json['subscribed_at'] != null
          ? DateTime.parse(json['subscribed_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'category': category,
      'is_active': isActive,
      'subscribed_at': subscribedAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  NewsletterSubscriptionModel copyWith({
    int? id,
    String? email,
    String? category,
    bool? isActive,
    DateTime? subscribedAt,
    DateTime? updatedAt,
  }) {
    return NewsletterSubscriptionModel(
      id: id ?? this.id,
      email: email ?? this.email,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      subscribedAt: subscribedAt ?? this.subscribedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get categoryDisplayName {
    switch (category) {
      case 'tips':
        return 'Farming Tips';
      case 'market_trends':
        return 'Market Trends';
      case 'seasonal_advice':
        return 'Seasonal Advice';
      case 'pest_control':
        return 'Pest Control';
      case 'weather':
        return 'Weather Updates';
      case 'technology':
        return 'Agricultural Technology';
      case 'success_stories':
        return 'Success Stories';
      default:
        return category;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NewsletterSubscriptionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'NewsletterSubscriptionModel(id: $id, email: $email, category: $category, isActive: $isActive)';
  }
}

// Newsletter subscription request model
class NewsletterSubscriptionRequest {
  final String email;
  final String category;

  NewsletterSubscriptionRequest({required this.email, required this.category});

  Map<String, dynamic> toJson() {
    return {'email': email, 'category': category};
  }
}
