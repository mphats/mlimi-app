import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/notification_service.dart';
import '../../screens/consultation/consultation_list_screen.dart';

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notifications =
          await _notificationService.getNotificationHistory();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading notifications: $e')),
      );
    }
  }

  Future<void> _clearHistory() async {
    await _notificationService.clearNotificationHistory();
    if (!mounted) return;
    setState(() {
      _notifications = [];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification history cleared')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.notificationHistory),
        elevation: 0,
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear History'),
                    content: const Text(
                        'Are you sure you want to clear all notifications?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _clearHistory();
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return _buildNotificationItem(notification);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your notifications will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    final categoryIcon = _getCategoryIcon(notification.category);
    final categoryColor = _getCategoryColor(notification.category);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: categoryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            categoryIcon,
            color: categoryColor,
          ),
        ),
        title: Text(
          notification.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.content),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(notification.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        onTap: () {
          // Handle notification tap based on category
          _handleNotificationTap(notification);
        },
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Handle consultation update notifications by navigating to consultations
    if (notification.category == 'consultation_update') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ConsultationListScreen(),
        ),
      );
    }
    // Add other category handling as needed
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'newsletters':
        return Icons.newspaper;
      case 'market_updates':
        return Icons.trending_up;
      case 'weather_alerts':
        return Icons.wb_sunny;
      case 'pest_alerts':
        return Icons.bug_report;
      case 'community_mentions':
        return Icons.people;
      case 'consultation_update':
        return Icons.question_answer;
      default:
        return Icons.notifications;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'newsletters':
        return Colors.blue;
      case 'market_updates':
        return Colors.green;
      case 'weather_alerts':
        return Colors.orange;
      case 'pest_alerts':
        return Colors.red;
      case 'community_mentions':
        return Colors.purple;
      case 'consultation_update':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}