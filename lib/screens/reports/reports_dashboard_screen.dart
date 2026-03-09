import 'package:flutter/material.dart';
import 'package:mulimi/core/services/api_service.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/report_service.dart';
import '../../models/report_model.dart';
import 'report_subscriptions_screen.dart';
import 'create_report_screen.dart';

class ReportsDashboardScreen extends StatefulWidget {
  const ReportsDashboardScreen({super.key});

  @override
  State<ReportsDashboardScreen> createState() => _ReportsDashboardScreenState();
}

class _ReportsDashboardScreenState extends State<ReportsDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ReportService _reportService;

  List<Report> _reports = [];
  List<ReportSubscription> _subscriptions = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _reportService = ReportService();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await ApiService().getAccessToken();
      
      // Load both reports and subscriptions concurrently
      final reportsFuture = _reportService.getReports(
        authToken: token,
      );
      
      final subscriptionsFuture = _reportService.getReportSubscriptions(
        authToken: token,
      );
      
      final results = await Future.wait([reportsFuture, subscriptionsFuture]);
      
      setState(() {
        _reports = results[0] as List<Report>;
        _subscriptions = results[1] as List<ReportSubscription>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  void _navigateToCreateReport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateReportScreen(),
      ),
    ).then((value) {
      if (value == true) {
        _loadData(); // Refresh data if a new report was created
      }
    });
  }

  void _navigateToSubscriptions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReportSubscriptionsScreen(),
      ),
    ).then((value) {
      if (value == true) {
        _loadData(); // Refresh data if subscriptions were modified
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.reports),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: AppStrings.myReports),
            Tab(text: AppStrings.reportSubscriptions),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
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
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildReportsTab(),
                    _buildSubscriptionsTab(),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateReport,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildReportsTab() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: _reports.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.description_outlined,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No reports available',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create your first report to get started',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _navigateToCreateReport,
                    child: const Text('Create Report'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _reports.length,
              itemBuilder: (context, index) {
                final report = _reports[index];
                return _buildReportCard(report);
              },
            ),
    );
  }

  Widget _buildSubscriptionsTab() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _navigateToSubscriptions,
              icon: const Icon(Icons.notifications_active),
              label: const Text(AppStrings.subscribeToReports),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
          Expanded(
            child: _subscriptions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.notifications_outlined,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No subscriptions yet',
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Create a subscription to receive regular reports',
                          style: TextStyle(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _subscriptions.length,
                    itemBuilder: (context, index) {
                      final subscription = _subscriptions[index];
                      return _buildSubscriptionCard(subscription);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(Report report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          // Navigate to report detail screen
          // You would implement this navigation in a real app
        },
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
                  color: AppColors.textSecondary,
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
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${report.generatedAt.day}/${report.generatedAt.month}/${report.generatedAt.year}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
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

  Widget _buildSubscriptionCard(ReportSubscription subscription) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
                    subscription.getReportTypeDisplay(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Switch(
                  value: subscription.isActive,
                  onChanged: (value) {
                    // Handle toggle in the full subscriptions screen
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
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
                    subscription.getFrequencyDisplay(),
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                if (subscription.lastSent != null)
                  Text(
                    'Last sent: ${subscription.lastSent!.day}/${subscription.lastSent!.month}/${subscription.lastSent!.year}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}