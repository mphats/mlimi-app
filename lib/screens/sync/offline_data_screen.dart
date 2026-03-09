import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/cache_service.dart';
import '../../core/services/sync_service.dart';

class OfflineDataScreen extends StatefulWidget {
  const OfflineDataScreen({super.key});

  @override
  State<OfflineDataScreen> createState() => _OfflineDataScreenState();
}

class _OfflineDataScreenState extends State<OfflineDataScreen> {
  List<Map<String, dynamic>> _offlineData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOfflineData();
  }

  Future<void> _loadOfflineData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cacheService = CacheService();
      final data = await cacheService.getAllOfflineData();
      
      if (mounted) {
        setState(() {
          _offlineData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading offline data: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _syncData() async {
    try {
      final syncService = SyncService();
      await syncService.syncOfflineData();
      
      if (mounted) {
        await _loadOfflineData();
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync completed successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during sync: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Data'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Header with sync button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Offline Data',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_offlineData.length} items pending sync',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _syncData,
                  icon: const Icon(Icons.sync),
                  label: const Text('Sync Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // Offline data list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _offlineData.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _offlineData.length,
                        itemBuilder: (context, index) {
                          final item = _offlineData[index];
                          return _buildOfflineDataItem(item);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_done_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          const Text(
            'No offline data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'All your data is synced with the server',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineDataItem(Map<String, dynamic> item) {
    final method = item['method'] as String? ?? 'Unknown';
    final path = item['path'] as String? ?? 'Unknown path';
    final timestamp = item['timestamp'] as int? ?? 0;
    final synced = item['synced'] as bool? ?? false;
    final retryCount = item['retryCount'] as int? ?? 0;
    
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final formattedTime = '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          '$method $path',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Saved at $formattedTime',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            if (retryCount > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Retries: $retryCount',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.warning,
                ),
              ),
            ],
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: synced ? AppColors.success : AppColors.warning,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            synced ? 'Synced' : 'Pending',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}