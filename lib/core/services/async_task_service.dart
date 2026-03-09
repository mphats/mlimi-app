import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/async_task_model.dart';

class AsyncTaskService {
  static final AsyncTaskService _instance = AsyncTaskService._internal();
  factory AsyncTaskService() => _instance;
  AsyncTaskService._internal();

  late SharedPreferences _prefs;
  final Map<String, Function(AsyncTaskModel)> _taskListeners = {};
  final Map<String, Timer?> _pollingTimers = {};

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Register a task listener for status updates
  void addTaskListener(String taskId, Function(AsyncTaskModel) listener) {
    _taskListeners[taskId] = listener;
  }

  // Remove a task listener
  void removeTaskListener(String taskId) {
    _taskListeners.remove(taskId);
  }

  // Create a new async task
  Future<AsyncTaskModel> createTask({
    required String taskType,
    String? description,
  }) async {
    final task = AsyncTaskModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      taskType: taskType,
      status: 'PENDING',
      description: description,
      createdAt: DateTime.now(),
      progress: 0.0,
    );

    await _saveTask(task);
    return task;
  }

  // Update task status
  Future<AsyncTaskModel> updateTaskStatus({
    required String taskId,
    required String status,
    double? progress,
    String? resultData,
    String? errorMessage,
    DateTime? completedAt,
  }) async {
    final task = await getTask(taskId);
    if (task == null) {
      throw Exception('Task not found: $taskId');
    }

    final updatedTask = task.copyWith(
      status: status,
      progress: progress ?? task.progress,
      resultData: resultData,
      errorMessage: errorMessage,
      completedAt: completedAt,
    );

    await _saveTask(updatedTask);

    // Notify listeners
    if (_taskListeners.containsKey(taskId)) {
      _taskListeners[taskId]!(updatedTask);
    }

    return updatedTask;
  }

  // Get a specific task
  Future<AsyncTaskModel?> getTask(String taskId) async {
    final key = 'async_task_$taskId';
    final jsonString = _prefs.getString(key);
    if (jsonString == null) return null;

    try {
      final json = Map<String, dynamic>.from(
          jsonDecode(jsonString) as Map<String, dynamic>);
      return AsyncTaskModel.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  // Get all tasks
  Future<List<AsyncTaskModel>> getAllTasks() async {
    final tasks = <AsyncTaskModel>[];
    final keys = _prefs.getKeys();

    for (final key in keys) {
      if (key.startsWith('async_task_')) {
        final jsonString = _prefs.getString(key);
        if (jsonString != null) {
          try {
            final json = Map<String, dynamic>.from(
                jsonDecode(jsonString) as Map<String, dynamic>);
            tasks.add(AsyncTaskModel.fromJson(json));
          } catch (e) {
            // Skip invalid task data
          }
        }
      }
    }

    // Sort by creation date (newest first)
    tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return tasks;
  }

  // Get tasks by type
  Future<List<AsyncTaskModel>> getTasksByType(String taskType) async {
    final allTasks = await getAllTasks();
    return allTasks.where((task) => task.taskType == taskType).toList();
  }

  // Get recent tasks (last 24 hours)
  Future<List<AsyncTaskModel>> getRecentTasks() async {
    final allTasks = await getAllTasks();
    final oneDayAgo = DateTime.now().subtract(const Duration(days: 1));
    return allTasks.where((task) => task.createdAt.isAfter(oneDayAgo)).toList();
  }

  // Delete a task
  Future<void> deleteTask(String taskId) async {
    final key = 'async_task_$taskId';
    await _prefs.remove(key);
    
    // Stop polling if active
    _stopPolling(taskId);
    
    // Remove listener
    removeTaskListener(taskId);
  }

  // Clear all completed tasks
  Future<void> clearCompletedTasks() async {
    final tasks = await getAllTasks();
    for (final task in tasks) {
      if (task.isCompleted || task.isFailed) {
        await deleteTask(task.id);
      }
    }
  }

  // Start polling for task status updates
  void startPollingTask(String taskId, Future<AsyncTaskModel?> Function(String) fetchTask, {int intervalSeconds = 5}) {
    // Stop any existing polling for this task
    _stopPolling(taskId);
    
    // Start new polling timer
    _pollingTimers[taskId] = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (timer) async {
        try {
          final updatedTask = await fetchTask(taskId);
          if (updatedTask != null) {
            await _saveTask(updatedTask);
            
            // Notify listeners
            if (_taskListeners.containsKey(taskId)) {
              _taskListeners[taskId]!(updatedTask);
            }
            
            // Stop polling if task is completed or failed
            if (updatedTask.isCompleted || updatedTask.isFailed) {
              _stopPolling(taskId);
            }
          }
        } catch (e) {
          // Continue polling even if one request fails
          debugPrint('Error polling task $taskId: $e');
        }
      },
    );
  }

  // Stop polling for a task
  void _stopPolling(String taskId) {
    final timer = _pollingTimers[taskId];
    if (timer != null && timer.isActive) {
      timer.cancel();
      _pollingTimers.remove(taskId);
    }
  }

  // Save task to storage
  Future<void> _saveTask(AsyncTaskModel task) async {
    final key = 'async_task_${task.id}';
    final jsonString = jsonEncode(task.toJson());
    await _prefs.setString(key, jsonString);
  }

  // Clean up resources
  void dispose() {
    // Cancel all active timers
    for (final timer in _pollingTimers.values) {
      timer?.cancel();
    }
    _pollingTimers.clear();
    _taskListeners.clear();
  }
}