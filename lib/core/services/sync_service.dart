import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'api_service.dart';
import '../utils/logger.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final ApiService _apiService = ApiService();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;

  // Initialize the sync service
  void initialize() {
    // Listen for connectivity changes
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen(_onConnectivityChanged);
  }

  // Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) async {
    // Check if any of the results indicate connectivity
    bool isConnected = results.any((result) => result != ConnectivityResult.none);
    
    if (isConnected) {
      // We're back online, sync offline data
      await syncOfflineData();
    }
  }

  // Synchronize offline data
  Future<void> syncOfflineData() async {
    if (_isSyncing) return;
    
    _isSyncing = true;
    
    try {
      await _apiService.syncOfflineData();
    } catch (e) {
      Logger.error('Error during sync: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // Dispose of the service
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}