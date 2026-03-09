import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/async_task_model.dart';
import '../../core/services/async_task_service.dart';
import '../../core/services/api_service.dart';

class AsyncTasksScreen extends StatefulWidget {
  const AsyncTasksScreen({super.key});

  @override
  State<AsyncTasksScreen> createState() => _AsyncTasksScreenState();
}

class _AsyncTasksScreenState extends State<AsyncTasksScreen> {
  final AsyncTaskService _taskService = AsyncTaskService();
  final ApiService _apiService = ApiService();
  List<AsyncTaskModel> _tasks = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // First try to load from backend API
      final response = await _apiService.get('/tasks');
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final tasksData = data['tasks'] as List;
        
        final tasks = tasksData.map((taskData) {
          return AsyncTaskModel(
            id: taskData['id'] as String,
            taskType: taskData['type'] as String,
            status: taskData['status'] as String,
            description: taskData['description'] as String,
            createdAt: DateTime.parse(taskData['created_at'] as String),
            completedAt: taskData['completed_at'] != null 
                ? DateTime.parse(taskData['completed_at'] as String) 
                : null,
            resultData: taskData['result_data'] as String?,
            errorMessage: taskData['error_message'] as String?,
            progress: (taskData['progress'] as num).toDouble(),
          );
        }).toList();
        
        setState(() {
          _tasks = tasks;
          _isLoading = false;
        });
      } else {
        // Fallback to local storage if API fails
        final localTasks = await _taskService.getAllTasks();
        setState(() {
          _tasks = localTasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Fallback to local storage if API fails
      try {
        final localTasks = await _taskService.getAllTasks();
        setState(() {
          _tasks = localTasks;
          _isLoading = false;
          _errorMessage = '';
        });
      } catch (localError) {
        setState(() {
          _errorMessage = 'Failed to load tasks: $e';
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading tasks: $e')),
          );
        }
      }
    }
  }

  Future<void> _refreshTasks() async {
    await _loadTasks();
  }

  Future<void> _clearCompletedTasks() async {
    final bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Clear Completed Tasks'),
            content: const Text(
                'Are you sure you want to clear all completed tasks?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Clear'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      try {
        await _taskService.clearCompletedTasks();
        await _loadTasks();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Completed tasks cleared'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error clearing tasks: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Async Task Monitoring'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshTasks,
          ),
          if (_tasks.any((task) => task.isCompleted || task.isFailed))
            IconButton(
              icon: const Icon(Icons.cleaning_services),
              onPressed: _clearCompletedTasks,
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
                        onPressed: _loadTasks,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _tasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.task_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No async tasks',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tasks will appear here when you perform async operations',
                            style: TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _refreshTasks,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _tasks.length,
                        itemBuilder: (context, index) {
                          final task = _tasks[index];
                          return _buildTaskCard(task);
                        },
                      ),
                    ),
    );
  }

  Widget _buildTaskCard(AsyncTaskModel task) {
    Color statusColor;
    switch (task.status) {
      case 'COMPLETED':
      case 'SUCCESS':
        statusColor = AppColors.success;
        break;
      case 'FAILED':
      case 'ERROR':
        statusColor = AppColors.error;
        break;
      case 'PROCESSING':
      case 'RUNNING':
        statusColor = AppColors.warning;
        break;
      default:
        statusColor = AppColors.primary;
    }

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
                    task.taskType,
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
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    task.statusDisplay,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (task.description != null) ...[
              const SizedBox(height: 8),
              Text(
                task.description!,
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Progress bar
            if (task.isProcessing) ...[
              LinearProgressIndicator(
                value: task.progress,
                backgroundColor: AppColors.backgroundLight,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
              const SizedBox(height: 4),
              Text(
                task.progressPercentage,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
            ],
            // Timestamps
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Created: ${_formatDateTime(task.createdAt)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                if (task.completedAt != null)
                  Text(
                    'Completed: ${_formatDateTime(task.completedAt!)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
            // Error message if failed
            if (task.isFailed && task.errorMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Text(
                  task.errorMessage!,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}