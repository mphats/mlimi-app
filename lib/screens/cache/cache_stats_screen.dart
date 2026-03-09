import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/cache_service.dart';
import '../../widgets/cache_manager_widget.dart';

class CacheStatsScreen extends StatefulWidget {
  const CacheStatsScreen({super.key});

  @override
  State<CacheStatsScreen> createState() => _CacheStatsScreenState();
}

class _CacheStatsScreenState extends State<CacheStatsScreen> {
  int _cacheEntryCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCacheStats();
  }

  Future<void> _loadCacheStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // In a real implementation, you might want to calculate actual cache size
      // For now, we'll just show a placeholder
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _cacheEntryCount = 15; // Placeholder value
      });
    } catch (e) {
      debugPrint('Error loading cache stats: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearAllCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Cache'),
        content: const Text(
          'Are you sure you want to clear all cached data? This will remove all offline data and may increase loading times temporarily.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await CacheService().clearAllCache();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All cache cleared successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          _loadCacheStats();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to clear cache'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CacheManagerWidget(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cache Statistics'),
          backgroundColor: AppColors.surface,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: _clearAllCache,
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear All Cache',
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: AppColors.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cache Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildStatRow(
                          'Cache Entries',
                          _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(),
                                )
                              : Text('$_cacheEntryCount entries'),
                        ),
                        const SizedBox(height: 8),
                        _buildStatRow(
                          'Cache Strategy',
                          const Text('Automatic expiration (5-15 min)'),
                        ),
                        const SizedBox(height: 8),
                        _buildStatRow(
                          'Storage Location',
                          const Text('SharedPreferences'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Cache Benefits',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Card(
                  color: AppColors.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildBenefitItem(
                          Icons.flash_on,
                          'Faster Loading',
                          'Cached data loads instantly',
                        ),
                        const SizedBox(height: 12),
                        _buildBenefitItem(
                          Icons.offline_pin,
                          'Offline Access',
                          'Access recent data without internet',
                        ),
                        const SizedBox(height: 12),
                        _buildBenefitItem(
                          Icons.data_usage,
                          'Reduced Data Usage',
                          'Less network requests means less data',
                        ),
                        const SizedBox(height: 12),
                        _buildBenefitItem(
                          Icons.battery_charging_full,
                          'Battery Savings',
                          'Fewer network requests save battery',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Cache Management',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Card(
                  color: AppColors.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildManagementItem(
                          Icons.autorenew,
                          'Automatic Refresh',
                          'Data automatically refreshes when stale',
                        ),
                        const SizedBox(height: 12),
                        _buildManagementItem(
                          Icons.delete,
                          'Manual Clear',
                          'Clear cache when needed via settings',
                        ),
                        const SizedBox(height: 12),
                        _buildManagementItem(
                          Icons.security,
                          'Secure Storage',
                          'Sensitive data is securely stored',
                        ),
                        const SizedBox(height: 16), // Add some bottom padding
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20), // Add extra space at the bottom
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, Widget value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          flex: 1,
          child: Align(
            alignment: Alignment.centerRight,
            child: value,
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
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

  Widget _buildManagementItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.success),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
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
}