import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../constants/app_constants.dart';
import '../models/market_price_model.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _activityChannel;
  WebSocketChannel? _marketPricesChannel;
  
  bool _isActivityConnected = false;
  bool _isMarketPricesConnected = false;
  
  // Connection retry counters
  int _activityRetryCount = 0;
  int _marketPricesRetryCount = 0;
  
  // Maximum retry attempts
  static const int _maxReconnectAttempts = 5;
  
  // Exponential backoff parameters
  static const int _baseDelayMs = 1000; // 1 second
  static const int _maxDelayMs = 60000; // 60 seconds
  static const int _jitterMs = 1000; // 1 second
  
  // Connection state
  static const int _stateDisconnected = 0;
  static const int _stateConnecting = 1;
  static const int _stateConnected = 2;
  static const int _stateAuthenticating = 3;
  static const int _stateAuthenticated = 4;
  static const int _stateReconnecting = 5;
  static const int _stateFailed = 6;
  
  int _activityConnectionState = _stateDisconnected;
  int _marketPriceConnectionState = _stateDisconnected;
  
  // Listeners for activity updates
  final List<Function(dynamic)> _activityListeners = [];
  final List<Function(MarketPriceModel)> _marketPriceListeners = [];
  
  // Connection state listeners
  final List<Function(bool)> _activityConnectionListeners = [];
  final List<Function(bool)> _marketPriceConnectionListeners = [];
  
  // Auth token for reconnection
  String? _authToken;
  
  // Connectivity checker
  final Connectivity _connectivity = Connectivity();
  
  // Add activity listener
  void addActivityListener(Function(dynamic) listener) {
    _activityListeners.add(listener);
  }
  
  // Remove activity listener
  void removeActivityListener(Function(dynamic) listener) {
    _activityListeners.remove(listener);
  }
  
  // Add market price listener
  void addMarketPriceListener(Function(MarketPriceModel) listener) {
    _marketPriceListeners.add(listener);
  }
  
  // Remove market price listener
  void removeMarketPriceListener(Function(MarketPriceModel) listener) {
    _marketPriceListeners.remove(listener);
  }
  
  // Add connection state listener for activity
  void addActivityConnectionListener(Function(bool) listener) {
    _activityConnectionListeners.add(listener);
  }
  
  // Remove connection state listener for activity
  void removeActivityConnectionListener(Function(bool) listener) {
    _activityConnectionListeners.remove(listener);
  }
  
  // Add connection state listener for market prices
  void addMarketPriceConnectionListener(Function(bool) listener) {
    _marketPriceConnectionListeners.add(listener);
  }
  
  // Remove connection state listener for market prices
  void removeMarketPriceConnectionListener(Function(bool) listener) {
    _marketPriceConnectionListeners.remove(listener);
  }
  
  // Check network connectivity
  Future<bool> _isOnline() async {
    try {
      final result = await _connectivity.checkConnectivity();
      // In connectivity_plus v6+, checkConnectivity returns List<ConnectivityResult>
      return result.any((r) => r != ConnectivityResult.none);
    } catch (e) {
      // If we can't check connectivity, assume we're online
      return true;
    }
  }
  
  // Calculate exponential backoff delay with jitter
  int _calculateBackoffDelay(int attempt) {
    if (attempt >= _maxReconnectAttempts) {
      return _maxDelayMs;
    }
    
    final delay = min(
      _baseDelayMs * pow(2, attempt).toInt(),
      _maxDelayMs
    );
    
    // Add jitter (random value between 0 and _jitterMs)
    final jitter = Random().nextInt(_jitterMs);
    
    return delay + jitter;
  }
  
  // Connect to activity WebSocket
  Future<void> connectToActivityStream(String token) async {
    _authToken = token;
    _activityConnectionState = _stateConnecting;
    
    // Check network connectivity first
    final isOnline = await _isOnline();
    if (!isOnline) {
      debugPrint('Offline: Cannot connect to activity stream');
      _activityConnectionState = _stateDisconnected;
      return;
    }
    
    if (_isActivityConnected) return;
    
    // Check if we've exceeded max retry attempts
    if (_activityRetryCount >= _maxReconnectAttempts) {
      debugPrint('Max retry attempts reached for activity stream');
      _activityConnectionState = _stateFailed;
      return;
    }
    
    try {
      // Updated URL to match Django routing with platform-specific URL
      String baseUrl = AppConstants.wsUrl;
      if (!baseUrl.startsWith('ws://') && !baseUrl.startsWith('wss://')) {
        baseUrl = baseUrl.replaceFirst('http', 'ws');
      }
      final uri = Uri.parse('$baseUrl/activity/');
      _activityChannel = WebSocketChannel.connect(uri);
      
      _isActivityConnected = true;
      _activityConnectionState = _stateConnected;
      _activityRetryCount = 0; // Reset retry count on successful connection
      _notifyActivityConnectionState(true);
      
      // Authenticate after connection
      _activityConnectionState = _stateAuthenticating;
      _activityChannel?.sink.add(jsonEncode({
        'type': 'authenticate',
        'token': token,
      }));
      
      // Listen for messages
      _activityChannel?.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            // Check if this is an authentication success message
            if (data is Map<String, dynamic> && 
                data['type'] == 'success' && 
                data['message'] == 'Authentication successful') {
              _activityConnectionState = _stateAuthenticated;
              debugPrint('Activity stream authenticated successfully');
            } else if (data is Map<String, dynamic> && 
                      data['type'] == 'auth_error') {
              _activityConnectionState = _stateFailed;
              debugPrint('Activity stream authentication failed: ${data['message']}');
              _handleActivityDisconnect();
            }
            _notifyActivityListeners(data);
          } catch (e) {
            debugPrint('Error parsing activity message: $e');
          }
        },
        onError: (error) {
          debugPrint('Activity WebSocket error: $error');
          _handleActivityDisconnect();
        },
        onDone: () {
          debugPrint('Activity WebSocket connection closed');
          _handleActivityDisconnect();
        },
      );
    } catch (e) {
      debugPrint('Error connecting to activity stream: $e');
      _activityRetryCount++;
      _activityConnectionState = _stateFailed;
      _notifyActivityConnectionState(false);
      
      // Schedule reconnection with exponential backoff
      if (_activityRetryCount < _maxReconnectAttempts) {
        final delay = _calculateBackoffDelay(_activityRetryCount);
        debugPrint('Scheduling reconnection in ${delay}ms');
        Future.delayed(Duration(milliseconds: delay), () {
          if (_authToken != null) {
            connectToActivityStream(_authToken!);
          }
        });
      }
    }
  }
  
  // Connect to market prices WebSocket
  Future<void> connectToMarketPricesStream(String token) async {
    _authToken = token;
    _marketPriceConnectionState = _stateConnecting;
    
    // Check network connectivity first
    final isOnline = await _isOnline();
    if (!isOnline) {
      debugPrint('Offline: Cannot connect to market prices stream');
      _marketPriceConnectionState = _stateDisconnected;
      return;
    }
    
    if (_isMarketPricesConnected) return;
    
    // Check if we've exceeded max retry attempts
    if (_marketPricesRetryCount >= _maxReconnectAttempts) {
      debugPrint('Max retry attempts reached for market prices stream');
      _marketPriceConnectionState = _stateFailed;
      return;
    }
    
    try {
      // Updated URL to match Django routing with platform-specific URL
      String baseUrl = AppConstants.wsUrl;
      if (!baseUrl.startsWith('ws://') && !baseUrl.startsWith('wss://')) {
        baseUrl = baseUrl.replaceFirst('http', 'ws');
      }
      final uri = Uri.parse('$baseUrl/market-prices/');
      _marketPricesChannel = WebSocketChannel.connect(uri);
      
      _isMarketPricesConnected = true;
      _marketPriceConnectionState = _stateConnected;
      _marketPricesRetryCount = 0; // Reset retry count on successful connection
      _notifyMarketPriceConnectionState(true);
      
      // Authenticate after connection
      _marketPriceConnectionState = _stateAuthenticating;
      _marketPricesChannel?.sink.add(jsonEncode({
        'type': 'authenticate',
        'token': token,
      }));
      
      // Listen for messages
      _marketPricesChannel?.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            // Check if this is an authentication success message
            if (data is Map<String, dynamic> && 
                data['type'] == 'success' && 
                data['message'] == 'Authentication successful') {
              _marketPriceConnectionState = _stateAuthenticated;
              debugPrint('Market prices stream authenticated successfully');
            } else if (data is Map<String, dynamic> && 
                      data['type'] == 'auth_error') {
              _marketPriceConnectionState = _stateFailed;
              debugPrint('Market prices stream authentication failed: ${data['message']}');
              _handleMarketPriceDisconnect();
            } else if (data is Map<String, dynamic> && data['type'] == 'price_update') {
              final priceData = data['payload'] as Map<String, dynamic>;
              final marketPrice = MarketPriceModel.fromJson(priceData);
              _notifyMarketPriceListeners(marketPrice);
            }
            // For other messages, notify listeners
            if (data is Map<String, dynamic> && 
                data['type'] != 'success' && 
                data['type'] != 'auth_error' && 
                data['type'] != 'price_update') {
              _notifyActivityListeners(data);
            }
          } catch (e) {
            debugPrint('Error parsing market price message: $e');
          }
        },
        onError: (error) {
          debugPrint('Market Prices WebSocket error: $error');
          _handleMarketPriceDisconnect();
        },
        onDone: () {
          debugPrint('Market Prices WebSocket connection closed');
          _handleMarketPriceDisconnect();
        },
      );
    } catch (e) {
      debugPrint('Failed to connect to market prices stream: $e');
      _marketPricesRetryCount++;
      _marketPriceConnectionState = _stateFailed;
      _notifyMarketPriceConnectionState(false);
      
      // Schedule reconnection with exponential backoff
      if (_marketPricesRetryCount < _maxReconnectAttempts) {
        final delay = _calculateBackoffDelay(_marketPricesRetryCount);
        debugPrint('Scheduling reconnection in ${delay}ms');
        Future.delayed(Duration(milliseconds: delay), () {
          if (_authToken != null) {
            connectToMarketPricesStream(_authToken!);
          }
        });
      }
    }
  }
  
  // Disconnect from activity stream
  void disconnectFromActivityStream() {
    _activityChannel?.sink.close(status.goingAway);
    _isActivityConnected = false;
    _activityConnectionState = _stateDisconnected;
    _notifyActivityConnectionState(false);
  }
  
  // Disconnect from market prices stream
  void disconnectFromMarketPricesStream() {
    _marketPricesChannel?.sink.close(status.goingAway);
    _isMarketPricesConnected = false;
    _marketPriceConnectionState = _stateDisconnected;
    _notifyMarketPriceConnectionState(false);
  }
  
  // Handle activity disconnect with exponential backoff reconnection logic
  void _handleActivityDisconnect() {
    _isActivityConnected = false;
    _activityConnectionState = _stateDisconnected;
    _notifyActivityConnectionState(false);
    
    // Attempt to reconnect if we have an auth token and haven't exceeded retry limit
    if (_authToken != null && _activityRetryCount < _maxReconnectAttempts) {
      _activityRetryCount++;
      _activityConnectionState = _stateReconnecting;
      
      // Calculate backoff delay
      final delayMs = _calculateBackoffDelay(_activityRetryCount - 1);
      debugPrint('Attempting to reconnect to activity stream (attempt $_activityRetryCount) in ${delayMs}ms');
      
      // Schedule reconnection after exponential backoff delay
      Future.delayed(Duration(milliseconds: delayMs), () async {
        // Check connectivity before attempting to reconnect
        final isOnline = await _isOnline();
        if (isOnline) {
          connectToActivityStream(_authToken!);
        } else {
          // If offline, schedule another retry with the same delay
          debugPrint('Still offline, scheduling another retry');
          Future.delayed(Duration(milliseconds: delayMs), () {
            _handleActivityDisconnect(); // This will increment retry count and try again
          });
        }
      });
    } else if (_authToken != null) {
      // Max retries exceeded
      _activityConnectionState = _stateFailed;
      debugPrint('Max reconnection attempts reached for activity stream. Giving up.');
    }
  }
  
  // Handle market price disconnect with exponential backoff reconnection logic
  void _handleMarketPriceDisconnect() {
    _isMarketPricesConnected = false;
    _marketPriceConnectionState = _stateDisconnected;
    _notifyMarketPriceConnectionState(false);
    
    // Attempt to reconnect if we have an auth token and haven't exceeded retry limit
    if (_authToken != null && _marketPricesRetryCount < _maxReconnectAttempts) {
      _marketPricesRetryCount++;
      _marketPriceConnectionState = _stateReconnecting;
      
      // Calculate backoff delay
      final delayMs = _calculateBackoffDelay(_marketPricesRetryCount - 1);
      debugPrint('Attempting to reconnect to market prices stream (attempt $_marketPricesRetryCount) in ${delayMs}ms');
      
      // Schedule reconnection after exponential backoff delay
      Future.delayed(Duration(milliseconds: delayMs), () async {
        // Check connectivity before attempting to reconnect
        final isOnline = await _isOnline();
        if (isOnline) {
          connectToMarketPricesStream(_authToken!);
        } else {
          // If offline, schedule another retry with the same delay
          debugPrint('Still offline, scheduling another retry');
          Future.delayed(Duration(milliseconds: delayMs), () {
            _handleMarketPriceDisconnect(); // This will increment retry count and try again
          });
        }
      });
    } else if (_authToken != null) {
      // Max retries exceeded
      _marketPriceConnectionState = _stateFailed;
      debugPrint('Max reconnection attempts reached for market prices stream. Giving up.');
    }
  }
  
  // Notify activity listeners
  void _notifyActivityListeners(dynamic data) {
    for (final listener in _activityListeners) {
      listener(data);
    }
  }
  
  // Notify market price listeners
  void _notifyMarketPriceListeners(MarketPriceModel price) {
    for (final listener in _marketPriceListeners) {
      listener(price);
    }
  }
  
  // Notify activity connection state listeners
  void _notifyActivityConnectionState(bool connected) {
    for (final listener in _activityConnectionListeners) {
      listener(connected);
    }
  }
  
  // Notify market price connection state listeners
  void _notifyMarketPriceConnectionState(bool connected) {
    for (final listener in _marketPriceConnectionListeners) {
      listener(connected);
    }
  }
  
  // Send message to activity stream
  void sendActivityMessage(Map<String, dynamic> message) {
    if (_isActivityConnected && _activityConnectionState == _stateAuthenticated) {
      _activityChannel?.sink.add(jsonEncode(message));
    }
  }
  
  // Send message to market prices stream
  void sendMarketPriceMessage(Map<String, dynamic> message) {
    if (_isMarketPricesConnected && _marketPriceConnectionState == _stateAuthenticated) {
      _marketPricesChannel?.sink.add(jsonEncode(message));
    }
  }
  
  // Check if activity stream is connected
  bool get isActivityConnected => _isActivityConnected;
  
  // Check if market prices stream is connected
  bool get isMarketPricesConnected => _isMarketPricesConnected;
  
  // Get connection states
  int get activityConnectionState => _activityConnectionState;
  int get marketPriceConnectionState => _marketPriceConnectionState;
  
  // Reset retry counters
  void resetRetryCounters() {
    _activityRetryCount = 0;
    _marketPricesRetryCount = 0;
  }
  
  // Check if online
  Future<bool> isOnline() async {
    return await _isOnline();
  }
}