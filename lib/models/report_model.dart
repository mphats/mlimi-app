import 'dart:convert';
import '../core/utils/logger.dart';

class Report {
  final int id;
  final String title;
  final String description;
  final String reportType;
  final String format;
  final String? file;
  final User generatedBy;
  final DateTime generatedAt;
  final bool isPublic;
  final Map<String, dynamic> filters;
  final Map<String, dynamic> dataSummary;

  Report({
    required this.id,
    required this.title,
    required this.description,
    required this.reportType,
    required this.format,
    this.file,
    required this.generatedBy,
    required this.generatedAt,
    required this.isPublic,
    required this.filters,
    required this.dataSummary,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    try {
      // Print the JSON for debugging
      Logger.info('Report JSON: $json');
      
      return Report(
        id: json['id'] as int,
        title: json['title'] as String,
        description: json['description'] as String,
        reportType: json['report_type'] as String,
        format: json['format'] as String,
        file: json['file'] as String?,
        generatedBy: json['generated_by'] != null 
            ? User.fromJson(json['generated_by'] as Map<String, dynamic>) 
            : User(id: 0, username: 'Unknown', email: '', firstName: 'Unknown', lastName: 'User'),
        generatedAt: json['generated_at'] != null 
            ? DateTime.parse(json['generated_at'] as String) 
            : DateTime.now(),
        isPublic: json['is_public'] as bool? ?? false,
        filters: _parseJsonField(json['filters']),
        dataSummary: _parseJsonField(json['data_summary']),
      );
    } catch (e, stackTrace) {
      Logger.error('Error parsing Report from JSON: $e');
      Logger.error('Stack trace: $stackTrace');
      Logger.info('JSON data: $json');
      rethrow;
    }
  }

  static Map<String, dynamic> _parseJsonField(dynamic field) {
    try {
      if (field is Map<String, dynamic>) {
        return field;
      } else if (field is String) {
        return Map<String, dynamic>.from(jsonDecode(field));
      } else if (field == null) {
        return {};
      } else {
        return {};
      }
    } catch (e) {
      Logger.error('Error parsing JSON field: $e');
      return {};
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'report_type': reportType,
      'format': format,
      'file': file,
      'generated_by': generatedBy.toJson(),
      'generated_at': generatedAt.toIso8601String(),
      'is_public': isPublic,
      'filters': jsonEncode(filters),
      'data_summary': jsonEncode(dataSummary),
    };
  }

  String getReportTypeDisplay() {
    switch (reportType) {
      case 'MARKET_ANALYSIS':
        return 'Market Analysis';
      case 'CROP_PERFORMANCE':
        return 'Crop Performance';
      case 'WEATHER_IMPACT':
        return 'Weather Impact';
      case 'PEST_DISEASE':
        return 'Pest & Disease';
      case 'FINANCIAL':
        return 'Financial Analysis';
      case 'GENERAL':
        return 'General Report';
      default:
        return reportType;
    }
  }
}

class ReportSubscription {
  final int id;
  final User user;
  final String reportType;
  final String frequency;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastSent;
  final Map<String, dynamic> filters;

  ReportSubscription({
    required this.id,
    required this.user,
    required this.reportType,
    required this.frequency,
    required this.isActive,
    required this.createdAt,
    this.lastSent,
    required this.filters,
  });

  factory ReportSubscription.fromJson(Map<String, dynamic> json) {
    try {
      return ReportSubscription(
        id: json['id'] as int,
        user: json['user'] != null 
            ? User.fromJson(json['user'] as Map<String, dynamic>) 
            : User(id: 0, username: 'Unknown', email: '', firstName: 'Unknown', lastName: 'User'),
        reportType: json['report_type'] as String,
        frequency: json['frequency'] as String,
        isActive: json['is_active'] as bool? ?? false,
        createdAt: json['created_at'] != null 
            ? DateTime.parse(json['created_at'] as String) 
            : DateTime.now(),
        lastSent: json['last_sent'] != null
            ? DateTime.parse(json['last_sent'] as String)
            : null,
        filters: Report._parseJsonField(json['filters']),
      );
    } catch (e, stackTrace) {
      Logger.error('Error parsing ReportSubscription from JSON: $e');
      Logger.error('Stack trace: $stackTrace');
      Logger.info('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user.toJson(),
      'report_type': reportType,
      'frequency': frequency,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'last_sent': lastSent?.toIso8601String(),
      'filters': jsonEncode(filters),
    };
  }

  String getReportTypeDisplay() {
    switch (reportType) {
      case 'MARKET_ANALYSIS':
        return 'Market Analysis';
      case 'CROP_PERFORMANCE':
        return 'Crop Performance';
      case 'WEATHER_IMPACT':
        return 'Weather Impact';
      case 'PEST_DISEASE':
        return 'Pest & Disease';
      case 'FINANCIAL':
        return 'Financial Analysis';
      case 'GENERAL':
        return 'General Report';
      default:
        return reportType;
    }
  }

  String getFrequencyDisplay() {
    switch (frequency) {
      case 'DAILY':
        return 'Daily';
      case 'WEEKLY':
        return 'Weekly';
      case 'MONTHLY':
        return 'Monthly';
      case 'QUARTERLY':
        return 'Quarterly';
      default:
        return frequency;
    }
  }
}

class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    try {
      return User(
        id: json['id'] as int? ?? 0,
        username: json['username'] as String? ?? '',
        email: json['email'] as String? ?? '',
        firstName: json['first_name'] as String? ?? '',
        lastName: json['last_name'] as String? ?? '',
      );
    } catch (e, stackTrace) {
      Logger.error('Error parsing User from JSON: $e');
      Logger.error('Stack trace: $stackTrace');
      Logger.info('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
    };
  }
}