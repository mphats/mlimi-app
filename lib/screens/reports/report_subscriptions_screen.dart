import 'package:flutter/material.dart';
import 'package:mulimi/core/services/api_service.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/report_service.dart';
import '../../models/report_model.dart';

class ReportSubscriptionsScreen extends StatefulWidget {
  const ReportSubscriptionsScreen({super.key});

  @override
  State<ReportSubscriptionsScreen> createState() =>
      _ReportSubscriptionsScreenState();
}

class _ReportSubscriptionsScreenState extends State<ReportSubscriptionsScreen> {
  late ReportService _reportService;
  List<ReportSubscription> _subscriptions = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _reportService = ReportService();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await ApiService().getAccessToken();
      final subscriptions = await _reportService.getReportSubscriptions(
        authToken: token,
      );
      setState(() {
        _subscriptions = subscriptions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load subscriptions: $e';
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading subscriptions: $e')),
        );
      }
    }
  }

  Future<void> _refreshSubscriptions() async {
    await _loadSubscriptions();
  }

  Future<void> _toggleSubscription(
      ReportSubscription subscription) async {
    try {
      final token = await ApiService().getAccessToken();
      final updatedSubscription = await _reportService.updateReportSubscription(
        id: subscription.id,
        isActive: !subscription.isActive,
        authToken: token,
      );

      // Update the local list
      final index = _subscriptions
          .indexWhere((element) => element.id == subscription.id);
      if (index != -1) {
        setState(() {
          _subscriptions[index] = updatedSubscription;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updatedSubscription.isActive
                  ? 'Subscription activated'
                  : 'Subscription deactivated',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating subscription: $e')),
        );
      }
    }
  }

  Future<void> _deleteSubscription(
      ReportSubscription subscription) async {
    final bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Subscription'),
            content: const Text(
                'Are you sure you want to delete this subscription?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      try {
        final token = await ApiService().getAccessToken();
        await _reportService.deleteReportSubscription(
          subscription.id,
          authToken: token,
        );

        // Remove from the local list
        setState(() {
          _subscriptions
              .removeWhere((element) => element.id == subscription.id);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subscription deleted'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting subscription: $e')),
          );
        }
      }
    }
  }

  void _navigateToCreateSubscription() {
    showDialog(
      context: context,
      builder: (context) => const _CreateSubscriptionDialog(),
    ).then((value) {
      if (value == true) {
        _loadSubscriptions(); // Refresh subscriptions if a new one was created
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.reportSubscriptions),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshSubscriptions,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToCreateSubscription,
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
                        onPressed: _loadSubscriptions,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _subscriptions.isEmpty
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
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _navigateToCreateSubscription,
                            child: const Text('Create Subscription'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _refreshSubscriptions,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _subscriptions.length,
                        itemBuilder: (context, index) {
                          final subscription = _subscriptions[index];
                          return _buildSubscriptionCard(subscription);
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateSubscription,
        child: const Icon(Icons.add),
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
                  onChanged: (value) => _toggleSubscription(subscription),
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
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteSubscription(subscription),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateSubscriptionDialog extends StatefulWidget {
  const _CreateSubscriptionDialog();

  @override
  State<_CreateSubscriptionDialog> createState() =>
      _CreateSubscriptionDialogState();
}

class _CreateSubscriptionDialogState extends State<_CreateSubscriptionDialog> {
  final _formKey = GlobalKey<FormState>();
  late ReportService _reportService;

  String _reportType = 'MARKET_ANALYSIS';
  String _frequency = 'WEEKLY';
  bool _isActive = true;

  // Filter fields
  final _categoryController = TextEditingController();
  final _locationController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _reportService = ReportService();
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _createSubscription() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await ApiService().getAccessToken();

      // Build filters map
      final Map<String, dynamic> filters = {};
      if (_categoryController.text.isNotEmpty) {
        filters['category'] = _categoryController.text;
      }
      if (_locationController.text.isNotEmpty) {
        filters['location'] = _locationController.text;
      }

      await _reportService.createReportSubscription(
        reportType: _reportType,
        frequency: _frequency,
        isActive: _isActive,
        filters: filters,
        authToken: token,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription created successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Return true to indicate successful creation
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create subscription: $e';
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating subscription: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Subscription'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _reportType,
                  decoration: const InputDecoration(
                    labelText: 'Report Type',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'MARKET_ANALYSIS',
                      child: Text('Market Analysis'),
                    ),
                    DropdownMenuItem(
                      value: 'CROP_PERFORMANCE',
                      child: Text('Crop Performance'),
                    ),
                    DropdownMenuItem(
                      value: 'WEATHER_IMPACT',
                      child: Text('Weather Impact'),
                    ),
                    DropdownMenuItem(
                      value: 'PEST_DISEASE',
                      child: Text('Pest & Disease'),
                    ),
                    DropdownMenuItem(
                      value: 'FINANCIAL',
                      child: Text('Financial Analysis'),
                    ),
                    DropdownMenuItem(
                      value: 'GENERAL',
                      child: Text('General Report'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _reportType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _frequency,
                  decoration: const InputDecoration(
                    labelText: 'Frequency',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'DAILY',
                      child: Text('Daily'),
                    ),
                    DropdownMenuItem(
                      value: 'WEEKLY',
                      child: Text('Weekly'),
                    ),
                    DropdownMenuItem(
                      value: 'MONTHLY',
                      child: Text('Monthly'),
                    ),
                    DropdownMenuItem(
                      value: 'QUARTERLY',
                      child: Text('Quarterly'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _frequency = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category (Optional)',
                    hintText: 'e.g., Maize, Beans, etc.',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location (Optional)',
                    hintText: 'e.g., Blantyre, Lilongwe, etc.',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Active:'),
                    const SizedBox(width: 16),
                    Switch(
                      value: _isActive,
                      onChanged: (value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                    ),
                  ],
                ),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createSubscription,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}