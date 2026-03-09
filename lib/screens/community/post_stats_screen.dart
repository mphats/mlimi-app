import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/community_model.dart';

class PostStatsScreen extends StatelessWidget {
  final CommunityPostModel post;

  const PostStatsScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Analytics'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post Info
            _buildPostInfo(),
            const SizedBox(height: 24),

            // Engagement Stats
            _buildEngagementStats(),
            const SizedBox(height: 24),

            // Engagement Chart
            _buildEngagementChart(),
            const SizedBox(height: 24),

            // Replies Section
            _buildRepliesSection(),
            const SizedBox(height: 24),

            // Top Interactions
            _buildTopInteractions(),
          ],
        ),
      ),
    );
  }

  Widget _buildPostInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            post.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            post.content,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary,
                child: Text(
                  post.author.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                post.author.displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                post.timeAgo,
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Engagement Statistics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildStatCard(
              'Views',
              post.viewCount.isFinite ? post.viewCount.toString() : '0',
              Icons.visibility,
              AppColors.primary,
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              'Likes',
              post.likeCount.isFinite ? post.likeCount.toString() : '0',
              Icons.favorite,
              AppColors.error,
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              'Replies',
              post.replyCount.isFinite ? post.replyCount.toString() : '0',
              Icons.chat_bubble,
              AppColors.info,
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              'Shares',
              post.shareCount.isFinite ? post.shareCount.toString() : '0',
              Icons.share,
              AppColors.secondary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Engagement Over Time',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              _sampleData(),
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _sampleData() {
    return LineChartData(
      gridData: FlGridData(show: true),
      titlesData: FlTitlesData(show: true),
      borderData: FlBorderData(show: true),
      minX: 0,
      maxX: 7,
      minY: 0,
      maxY: 20,
      lineBarsData: [
        LineChartBarData(
          spots: [
            const FlSpot(0, 3),
            const FlSpot(1, 5),
            const FlSpot(2, 8),
            const FlSpot(3, 12),
            const FlSpot(4, 15),
            const FlSpot(5, 18),
            const FlSpot(6, 16),
            const FlSpot(7, 14),
          ],
          isCurved: true,
          color: AppColors.primary,
          barWidth: 3,
          belowBarData: BarAreaData(show: true, color: AppColors.primary.withValues(alpha: 0.3)),
        ),
      ],
    );
  }

  Widget _buildRepliesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Replies',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Replies',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    post.replyCount.isFinite ? post.replyCount.toString() : '0',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const LinearProgressIndicator(
                value: 0.7,
                backgroundColor: AppColors.inputBackground,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.info),
              ),
              const SizedBox(height: 8),
              const Text(
                '70% of replies are helpful',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopInteractions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Interactions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Column(
            children: [
              _buildInteractionItem(
                'Most Liked Reply',
                'John Farmer',
                24,
                Icons.favorite,
                AppColors.error,
              ),
              const SizedBox(height: 16),
              _buildInteractionItem(
                'Most Helpful Reply',
                'Agronomist Mary',
                18,
                Icons.check_circle,
                AppColors.success,
              ),
              const SizedBox(height: 16),
              _buildInteractionItem(
                'Most Active User',
                'Tom Trader',
                15,
                Icons.person,
                AppColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInteractionItem(
    String label,
    String user,
    int count,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                user,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}