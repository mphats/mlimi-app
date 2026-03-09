import '../core/models/user_model.dart';

class ConsultationModel {
  final int id;
  final UserModel? farmer;
  final UserModel? expert;
  final String title;
  final String description;
  final String category;
  final String status;
  final int priority;
  final bool isPremium;
  final double? price;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;

  ConsultationModel({
    required this.id,
    this.farmer,
    this.expert,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.priority,
    required this.isPremium,
    this.price,
    required this.createdAt,
    this.updatedAt,
    this.acceptedAt,
    this.completedAt,
  });

  factory ConsultationModel.fromJson(Map<String, dynamic> json) {
    return ConsultationModel(
      id: json['id'],
      farmer: json['farmer'] != null ? UserModel.fromJson(json['farmer']) : null,
      expert: json['expert'] != null ? UserModel.fromJson(json['expert']) : null,
      title: json['title'],
      description: json['description'],
      category: json['category'],
      status: json['status'],
      priority: json['priority'],
      isPremium: json['is_premium'],
      price: json['price']?.toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmer': farmer?.toJson(),
      'expert': expert?.toJson(),
      'title': title,
      'description': description,
      'category': category,
      'status': status,
      'priority': priority,
      'is_premium': isPremium,
      'price': price,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }
  
  ConsultationModel copyWith({
    int? id,
    UserModel? farmer,
    UserModel? expert,
    String? title,
    String? description,
    String? category,
    String? status,
    int? priority,
    bool? isPremium,
    double? price,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? acceptedAt,
    DateTime? completedAt,
  }) {
    return ConsultationModel(
      id: id ?? this.id,
      farmer: farmer ?? this.farmer,
      expert: expert ?? this.expert,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      isPremium: isPremium ?? this.isPremium,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}