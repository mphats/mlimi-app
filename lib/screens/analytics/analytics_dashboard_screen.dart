import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/localization_service.dart';
import 'package:provider/provider.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  bool _isLoading = true;
  UserActivityStats? _activityStats;
  List<PestDiagnosisRecord> _commonPests = [];

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final activityStats = await _analyticsService.getUserActivityStats();
      final commonPests = await _analyticsService.getCommonPestDiagnoses('maize');
      
      setState(() {
        _activityStats = activityStats;
        _commonPests = commonPests;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading analytics: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localization.getString('analyticsDashboard')),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalyticsData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(localization),
                  const SizedBox(height: 24),
                  _buildActivitySummary(localization),
                  const SizedBox(height: 24),
                  _buildPestAnalytics(localization),
                  const SizedBox(height: 24),
                  _buildMarketTrends(localization),
                  const SizedBox(height: 24),
                  _buildCropPerformance(localization),
                  const SizedBox(height: 24),
                  _buildFinancialAnalytics(localization),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(LocalizationService localization) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localization.getString('farmingInsights'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localization.getString('yourAgriculturalAnalyticsDashboard'),
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySummary(LocalizationService localization) {
    if (_activityStats == null) {
      return const SizedBox();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localization.getString('userActivity'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard(
                  localization.getString('totalActivities'),
                  _activityStats!.totalActivities.toString(),
                  Icons.bar_chart,
                  localization,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  localization.getString('dailyAverage'),
                  _activityStats!.dailyAverage.isFinite ? _activityStats!.dailyAverage.toStringAsFixed(1) : '0.0',
                  Icons.timeline,
                  localization,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_activityStats!.mostActiveDay.isNotEmpty)
              Text(
                '${localization.getString('mostActive')}: ${_activityStats!.mostActiveDay}',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, LocalizationService localization) {
    return Expanded(
      child: Card(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: Theme.of(context).primaryColor),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPestAnalytics(LocalizationService localization) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localization.getString('pestDiagnoses'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_commonPests.isEmpty)
              Text(localization.getString('noPestDiagnosesRecordedYet'))
            else
              SizedBox(
                height: _commonPests.length * 70.0, // Approximate height per item
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _commonPests.length,
                  itemBuilder: (context, index) {
                    final pest = _commonPests[index];
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.bug_report,
                          color: Colors.red,
                        ),
                      ),
                      title: Text(pest.diagnosis),
                      subtitle: Text('${pest.cropType} • ${(pest.confidence.isFinite ? pest.confidence * 100 : 0).toStringAsFixed(1)}% ${localization.getString('confidence')}'),
                      trailing: Text(
                        '${DateTime.now().difference(pest.timestamp).inDays} ${localization.getString('daysAgo')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketTrends(LocalizationService localization) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localization.getString('marketTrends'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(show: true),
                  borderData: FlBorderData(show: true),
                  minX: 0,
                  maxX: 6,
                  minY: 0,
                  maxY: 800,
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        const FlSpot(0, 300),
                        const FlSpot(1, 450),
                        const FlSpot(2, 500),
                        const FlSpot(3, 600),
                        const FlSpot(4, 550),
                        const FlSpot(5, 700),
                        const FlSpot(6, 750),
                      ],
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      barWidth: 3,
                      belowBarData: BarAreaData(show: true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Maize prices have increased by 25% over the last month',
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropPerformance(LocalizationService localization) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localization.getString('cropPerformance'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (!value.isFinite) return const Text('');
                          switch (value.toInt()) {
                            case 0:
                              return const Text('Maize');
                            case 1:
                              return const Text('Beans');
                            case 2:
                              return const Text('Rice');
                            default:
                              return const Text('');
                          }
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: 85,
                          color: Theme.of(context).primaryColor,
                          width: 20,
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: 75,
                          color: Colors.green,
                          width: 20,
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(
                          toY: 65,
                          color: Colors.orange,
                          width: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Maize shows the highest yield performance at 85%',
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialAnalytics(LocalizationService localization) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localization.getString('financialAnalytics'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildFinancialStatCard(localization.getString('revenue'), 'MWK 45,000', Icons.attach_money, localization),
                const SizedBox(width: 16),
                _buildFinancialStatCard(localization.getString('expenses'), 'MWK 25,000', Icons.money_off, localization),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildFinancialStatCard(localization.getString('profit'), 'MWK 20,000', Icons.trending_up, localization),
                const SizedBox(width: 16),
                _buildFinancialStatCard(localization.getString('roi'), '80%', Icons.percent, localization),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: 40,
                      title: 'Seeds',
                      color: Colors.blue,
                      radius: 50,
                    ),
                    PieChartSectionData(
                      value: 25,
                      title: 'Fertilizer',
                      color: Colors.green,
                      radius: 50,
                    ),
                    PieChartSectionData(
                      value: 20,
                      title: 'Labor',
                      color: Colors.orange,
                      radius: 50,
                    ),
                    PieChartSectionData(
                      value: 15,
                      title: 'Other',
                      color: Colors.grey,
                      radius: 50,
                    ),
                  ],
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialStatCard(String title, String value, IconData icon, LocalizationService localization) {
    return Expanded(
      child: Card(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 24, color: Theme.of(context).primaryColor),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}