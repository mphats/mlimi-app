import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/report_model.dart';
import '../constants/api_constants.dart';
import '../utils/logger.dart';

class ReportService {
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal();

  /// Get all reports for the current user
  Future<List<Report>> getReports({String? authToken}) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.reports}');
      final headers = {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

      Logger.info('Fetching reports from: $url');

      final response = await http.get(url, headers: headers);

      Logger.info('Reports API response status: ${response.statusCode}');
      Logger.info('Reports API response body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        
        // Handle both array and object responses
        List<dynamic> reportsData;
        if (data is List) {
          reportsData = data;
        } else if (data is Map && data.containsKey('results')) {
          // Handle paginated response
          reportsData = data['results'] as List;
        } else if (data is Map) {
          // Handle single object response
          reportsData = [data];
        } else {
          throw Exception('Unexpected response format');
        }

        Logger.info('Parsing ${reportsData.length} reports');
        return reportsData.map((json) => Report.fromJson(json)).toList();
      } else {
        Logger.error('Failed to load reports: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load reports: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      Logger.error('Error fetching reports: $e');
      Logger.error('Stack trace: $stackTrace');
      throw Exception('Error fetching reports: $e');
    }
  }

  /// Get a specific report by ID
  Future<Report> getReport(int id, {String? authToken}) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.reports}/$id');
      final headers = {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Report.fromJson(data);
      } else {
        Logger.error('Failed to load report: ${response.statusCode}');
        throw Exception('Failed to load report');
      }
    } catch (e) {
      Logger.error('Error fetching report: $e');
      throw Exception('Error fetching report: $e');
    }
  }

  /// Create a new report
  Future<Report> createReport({
    required String title,
    required String description,
    required String reportType,
    required String format,
    required bool isPublic,
    required Map<String, dynamic> filters,
    String? authToken,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.reports}');
      final headers = {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

      final body = json.encode({
        'title': title,
        'description': description,
        'report_type': reportType,
        'format': format,
        'is_public': isPublic,
        'filters': filters,
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Report.fromJson(data);
      } else {
        Logger.error('Failed to create report: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to create report: ${response.body}');
      }
    } catch (e) {
      Logger.error('Error creating report: $e');
      throw Exception('Error creating report: $e');
    }
  }

  /// Update an existing report
  Future<Report> updateReport({
    required int id,
    String? title,
    String? description,
    String? reportType,
    String? format,
    bool? isPublic,
    Map<String, dynamic>? filters,
    String? authToken,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.reports}/$id');
      final headers = {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

      final Map<String, dynamic> updateData = {};
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (reportType != null) updateData['report_type'] = reportType;
      if (format != null) updateData['format'] = format;
      if (isPublic != null) updateData['is_public'] = isPublic;
      if (filters != null) updateData['filters'] = filters;

      final body = json.encode(updateData);

      final response = await http.put(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Report.fromJson(data);
      } else {
        Logger.error('Failed to update report: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to update report: ${response.body}');
      }
    } catch (e) {
      Logger.error('Error updating report: $e');
      throw Exception('Error updating report: $e');
    }
  }

  /// Delete a report
  Future<void> deleteReport(int id, {String? authToken}) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.reports}/$id');
      final headers = {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

      final response = await http.delete(url, headers: headers);

      if (response.statusCode != 204) {
        Logger.error('Failed to delete report: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to delete report: ${response.body}');
      }
    } catch (e) {
      Logger.error('Error deleting report: $e');
      throw Exception('Error deleting report: $e');
    }
  }

  /// Get all report subscriptions for the current user
  Future<List<ReportSubscription>> getReportSubscriptions({String? authToken}) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.reportSubscriptions}');
      final headers = {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        
        // Handle both array and object responses
        List<dynamic> subscriptionsData;
        if (data is List) {
          subscriptionsData = data;
        } else if (data is Map && data.containsKey('results')) {
          // Handle paginated response
          subscriptionsData = data['results'] as List;
        } else if (data is Map) {
          // Handle single object response
          subscriptionsData = [data];
        } else {
          throw Exception('Unexpected response format');
        }

        return subscriptionsData.map((json) => ReportSubscription.fromJson(json)).toList();
      } else {
        Logger.error('Failed to load report subscriptions: ${response.statusCode}');
        throw Exception('Failed to load report subscriptions');
      }
    } catch (e) {
      Logger.error('Error fetching report subscriptions: $e');
      throw Exception('Error fetching report subscriptions: $e');
    }
  }

  /// Create a new report subscription
  Future<ReportSubscription> createReportSubscription({
    required String reportType,
    required String frequency,
    required bool isActive,
    required Map<String, dynamic> filters,
    String? authToken,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.reportSubscriptions}');
      final headers = {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

      final body = json.encode({
        'report_type': reportType,
        'frequency': frequency,
        'is_active': isActive,
        'filters': filters,
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return ReportSubscription.fromJson(data);
      } else {
        Logger.error('Failed to create report subscription: ${response.statusCode}');
        throw Exception('Failed to create report subscription');
      }
    } catch (e) {
      Logger.error('Error creating report subscription: $e');
      throw Exception('Error creating report subscription: $e');
    }
  }

  /// Update an existing report subscription
  Future<ReportSubscription> updateReportSubscription({
    required int id,
    String? reportType,
    String? frequency,
    bool? isActive,
    Map<String, dynamic>? filters,
    String? authToken,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.reportSubscriptions}/$id');
      final headers = {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

      final Map<String, dynamic> updateData = {};
      if (reportType != null) updateData['report_type'] = reportType;
      if (frequency != null) updateData['frequency'] = frequency;
      if (isActive != null) updateData['is_active'] = isActive;
      if (filters != null) updateData['filters'] = filters;

      final body = json.encode(updateData);

      final response = await http.put(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return ReportSubscription.fromJson(data);
      } else {
        Logger.error('Failed to update report subscription: ${response.statusCode}');
        throw Exception('Failed to update report subscription');
      }
    } catch (e) {
      Logger.error('Error updating report subscription: $e');
      throw Exception('Error updating report subscription: $e');
    }
  }

  /// Delete a report subscription
  Future<void> deleteReportSubscription(int id, {String? authToken}) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.reportSubscriptions}/$id');
      final headers = {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

      final response = await http.delete(url, headers: headers);

      if (response.statusCode != 204) {
        Logger.error('Failed to delete report subscription: ${response.statusCode}');
        throw Exception('Failed to delete report subscription');
      }
    } catch (e) {
      Logger.error('Error deleting report subscription: $e');
      throw Exception('Error deleting report subscription: $e');
    }
  }
}