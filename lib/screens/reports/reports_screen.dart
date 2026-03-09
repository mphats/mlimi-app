import 'package:flutter/material.dart';
import '../../core/utils/logger.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/report_service.dart';
import '../../core/services/api_service.dart';
import '../../models/report_model.dart';
import 'report_detail_screen.dart';
import 'create_report_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late ReportService _reportService;
  List<Report> _reports = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _reportService = ReportService();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Use ApiService to get the token properly
      final apiService = ApiService();
      final token = await apiService.getAccessToken();
      
      if (token == null) {
        throw Exception('User not authenticated');
      }
      
      final reports = await _reportService.getReports(
        authToken: token,
      );
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      Logger.error('Error loading reports: $e');
      Logger.error('Stack trace: $stackTrace');
      setState(() {
        _errorMessage = 'Failed to load reports: ${e.toString()}';
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading reports: $e')),
      );
    }
  }

  Future<void> _refreshReports() async {
    await _loadReports();
  }

  void _navigateToCreateReport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateReportScreen(),
      ),
    ).then((value) {
      if (value == true) {
        _loadReports(); // Refresh reports if a new one was created
      }
    });
  }

  void _navigateToReportDetail(Report report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportDetailScreen(report: report),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.reports),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshReports,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToCreateReport,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage),
                      ElevatedButton(
                        onPressed: _loadReports,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _reports.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.description_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No reports available',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Create your first report to get started',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _navigateToCreateReport,
                            child: const Text('Create Report'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _refreshReports,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _reports.length,
                        itemBuilder: (context, index) {
                          final report = _reports[index];
                          return _buildReportCard(report);
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateReport,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildReportCard(Report report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _navigateToReportDetail(report),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      report.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      report.getReportTypeDisplay(),
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                report.description,
                style: const TextStyle(
                  color: Colors.grey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${report.generatedBy.firstName} ${report.generatedBy.lastName}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    '${report.generatedAt.day}/${report.generatedAt.month}/${report.generatedAt.year}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}