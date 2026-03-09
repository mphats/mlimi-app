import '../core/models/user_model.dart';

class ConsultationMessageModel {
  final int id;
  final UserModel sender;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  ConsultationMessageModel({
    required this.id,
    required this.sender,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory ConsultationMessageModel.fromJson(Map<String, dynamic> json) {
    return ConsultationMessageModel(
      id: json['id'],
      sender: UserModel.fromJson(json['sender']),
      message: json['message'],
      isRead: json['is_read'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender.toJson(),
      'message': message,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}