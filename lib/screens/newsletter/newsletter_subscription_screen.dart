import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/newsletter_service.dart';
import '../../core/models/newsletter_model.dart';
import '../../widgets/custom_text_field.dart';

class NewsletterSubscriptionScreen extends StatefulWidget {
  const NewsletterSubscriptionScreen({super.key});

  @override
  State<NewsletterSubscriptionScreen> createState() =>
      _NewsletterSubscriptionScreenState();
}

class _NewsletterSubscriptionScreenState
    extends State<NewsletterSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newsletterService = NewsletterService();
  final _emailController = TextEditingController();
  
  List<NewsletterSubscriptionModel> _subscriptions = [];
  String _userEmail = '';

  final List<Map<String, String>> _categories = [
    {'value': 'tips', 'label': 'Farming Tips'},
    {'value': 'market_trends', 'label': 'Market Trends'},
    {'value': 'seasonal_advice', 'label': 'Seasonal Advice'},
    {'value': 'pest_control', 'label': 'Pest Control'},
    {'value': 'weather', 'label': 'Weather Updates'},
    {'value': 'technology', 'label': 'Technology'},
    {'value': 'success_stories', 'label': 'Success Stories'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadSubscriptions() async {
    try {
      // In a real app, you would get the user's email from auth provider
      // For now, we'll use a placeholder
      _userEmail = 'user@example.com';
      _emailController.text = _userEmail;
      
      // Load existing subscriptions for the user
      final result = await _newsletterService.getUserSubscriptions(_userEmail);
      
      if (result.isSuccess) {
        setState(() {
          _subscriptions = result.subscriptions;
        });
      } else {
        setState(() {
          _subscriptions = [];
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load subscriptions: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      
      // Initialize with empty list on error
      setState(() {
        _subscriptions = [];
      });
    }
  }

  Future<void> _subscribeToNewsletter(String category) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final result = await _newsletterService.subscribeToNewsletter(
        _emailController.text.trim(),
        category,
      );

      if (result.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: AppColors.success,
            ),
          );
          
          // Refresh subscriptions
          _loadSubscriptions();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to subscribe: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          // removed _isLoading
        });
      }
    }
  }

  Future<void> _unsubscribeFromNewsletter(String category) async {
    try {
      final result = await _newsletterService.unsubscribeFromNewsletter(
        _emailController.text.trim(),
        category,
      );

      if (result.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: AppColors.success,
            ),
          );
          
          // Refresh subscriptions
          _loadSubscriptions();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to unsubscribe: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          // removed _isLoading
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Newsletter Subscriptions'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
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
                    'Newsletter Subscriptions',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage your newsletter subscriptions and preferences',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Email Input
            Form(
              key: _formKey,
              child: CustomTextField(
                controller: _emailController,
                label: 'Email Address',
                hint: 'Enter your email address',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email address';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 24),

            // Subscription Categories
            Text(
              'Subscription Categories',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return _buildCategoryCard(category);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, String> category) {
    final isSubscribed = _subscriptions.any(
        (sub) => sub.category == category['value'] && sub.isActive == true);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSubscribed ? AppColors.primary : AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          if (isSubscribed) {
            _unsubscribeFromNewsletter(category['value']!);
          } else {
            _subscribeToNewsletter(category['value']!);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isSubscribed ? AppColors.success : AppColors.border,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category['label']!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight:
                            isSubscribed ? FontWeight.bold : FontWeight.normal,
                      ),
                ),
              ),
              Icon(
                isSubscribed ? Icons.notifications_active : Icons.notifications,
                color: isSubscribed ? AppColors.primary : AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}