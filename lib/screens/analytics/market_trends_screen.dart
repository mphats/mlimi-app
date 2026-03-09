import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_strings.dart';

class MarketTrendsScreen extends StatefulWidget {
  const MarketTrendsScreen({super.key});

  @override
  State<MarketTrendsScreen> createState() => _MarketTrendsScreenState();
}

class _MarketTrendsScreenState extends State<MarketTrendsScreen> {
  String _selectedCrop = 'Maize';
  String _selectedMarket = 'Lilongwe Market';
  String _selectedTimeRange = '30d';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.marketTrends),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilters(),
            const SizedBox(height: 24),
            _buildPriceChart(),
            const SizedBox(height: 24),
            _buildPriceStatistics(),
            const SizedBox(height: 24),
            _buildMarketComparison(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCrop,
                    decoration: const InputDecoration(
                      labelText: 'Crop',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Maize', child: Text('Maize')),
                      DropdownMenuItem(value: 'Rice', child: Text('Rice')),
                      DropdownMenuItem(value: 'Beans', child: Text('Beans')),
                      DropdownMenuItem(value: 'Potatoes', child: Text('Potatoes')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCrop = value;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedMarket,
                    decoration: const InputDecoration(
                      labelText: 'Market',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'Lilongwe Market', child: Text('Lilongwe Market')),
                      DropdownMenuItem(
                          value: 'Blantyre Market', child: Text('Blantyre Market')),
                      DropdownMenuItem(
                          value: 'Mzuzu Market', child: Text('Mzuzu Market')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedMarket = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedTimeRange,
              decoration: const InputDecoration(
                labelText: 'Time Range',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              items: const [
                DropdownMenuItem(value: '7d', child: Text('Last 7 Days')),
                DropdownMenuItem(value: '30d', child: Text('Last 30 Days')),
                DropdownMenuItem(value: '90d', child: Text('Last 90 Days')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedTimeRange = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Price Trend',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          // Ensure value is finite before converting to int
                          if (!value.isFinite) return const Text('');
                          switch (value.toInt()) {
                            case 0:
                              return const Text('Jan', softWrap: false, overflow: TextOverflow.ellipsis);
                            case 1:
                              return const Text('Feb', softWrap: false, overflow: TextOverflow.ellipsis);
                            case 2:
                              return const Text('Mar', softWrap: false, overflow: TextOverflow.ellipsis);
                            case 3:
                              return const Text('Apr', softWrap: false, overflow: TextOverflow.ellipsis);
                            case 4:
                              return const Text('May', softWrap: false, overflow: TextOverflow.ellipsis);
                            case 5:
                              return const Text('Jun', softWrap: false, overflow: TextOverflow.ellipsis);
                            default:
                              return const Text('', softWrap: false, overflow: TextOverflow.ellipsis);
                          }
                        },
                        reservedSize: 30, // Add reserved size to prevent overflow
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          // Ensure value is finite before converting to int
                          if (!value.isFinite) return const Text('');
                          // Format large numbers to prevent overflow
                          final intValue = value.toInt();
                          if (intValue.abs() > 9999) {
                            // Format large numbers
                            return Text('${(intValue / 1000).toStringAsFixed(1)}k', 
                              style: const TextStyle(fontSize: 12));
                          }
                          return Text('$intValue', style: const TextStyle(fontSize: 12));
                        },
                        reservedSize: 40, // Increase reserved size for formatted numbers
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  minX: 0,
                  maxX: 5,
                  minY: 200,
                  maxY: 1000,
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        const FlSpot(0, 300),
                        const FlSpot(1, 450),
                        const FlSpot(2, 500),
                        const FlSpot(3, 600),
                        const FlSpot(4, 550),
                        const FlSpot(5, 700),
                      ],
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                      ),
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceStatistics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard('Current Price', 'MWK 700/kg', Colors.green),
                const SizedBox(width: 16),
                _buildStatCard('Average Price', 'MWK 550/kg', Colors.blue),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard('Highest Price', 'MWK 750/kg', Colors.orange),
                const SizedBox(width: 16),
                _buildStatCard('Lowest Price', 'MWK 300/kg', Colors.red),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Trend: Increasing (+25% over 30 days)',
              style: TextStyle(
                fontSize: 16,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketComparison() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Market Comparison',
              style: TextStyle(
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
                          // Ensure value is finite before converting to int
                          if (!value.isFinite) return const Text('');
                          switch (value.toInt()) {
                            case 0:
                              return const Text('Lilongwe', softWrap: false, overflow: TextOverflow.ellipsis);
                            case 1:
                              return const Text('Blantyre', softWrap: false, overflow: TextOverflow.ellipsis);
                            case 2:
                              return const Text('Mzuzu', softWrap: false, overflow: TextOverflow.ellipsis);
                            default:
                              return const Text('', softWrap: false, overflow: TextOverflow.ellipsis);
                          }
                        },
                        reservedSize: 30, // Add reserved size to prevent overflow
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
                          toY: 700,
                          color: Theme.of(context).primaryColor,
                          width: 20,
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: 650,
                          color: Colors.green,
                          width: 20,
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(
                          toY: 550,
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
            const Text(
              'Lilongwe Market has the highest prices for Maize',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}