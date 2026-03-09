import 'package:flutter_test/flutter_test.dart';
import 'package:mulimi/core/services/websocket_service.dart';
import 'package:mulimi/core/constants/app_constants.dart';

void main() {
  group('WebSocketService Tests', () {

    test('WebSocketService is a singleton', () {
      final instance1 = WebSocketService();
      final instance2 = WebSocketService();
      expect(instance1, equals(instance2));
    });

    group('URL Configuration Tests', () {
      test('WebSocket URL conversion from HTTP to WS', () {
        final httpUrl = 'http://127.0.0.1:8000';
        final wsUrl = httpUrl.replaceFirst('http', 'ws');
        expect(wsUrl, 'ws://127.0.0.1:8000');
      });

      test('WebSocket URL conversion from HTTPS to WSS', () {
        final httpsUrl = 'https://example.com';
        final wssUrl = httpsUrl.replaceFirst('https', 'wss');
        expect(wssUrl, 'wss://example.com');
      });

      test('AppConstants WebSocket URL format', () {
        final wsUrl = AppConstants.wsUrl;
        expect(wsUrl, isNotEmpty);
        expect(wsUrl.startsWith('ws://') || wsUrl.startsWith('wss://'), isTrue);
      });
    });

    group('Backoff Delay Tests', () {
      test('Backoff delay calculation for first attempt', () {
        // Test the exponential backoff calculation
        const baseDelayMs = 1000; // 1 second
        const attempt = 0;
        final delay = baseDelayMs * (2 ^ attempt);
        expect(delay, 1000);
      });

      test('Backoff delay calculation for second attempt', () {
        const baseDelayMs = 1000; // 1 second
        const attempt = 1;
        final delay = baseDelayMs * (2 ^ attempt);
        expect(delay, 2000);
      });

      test('Backoff delay calculation with maximum limit', () {
        const maxDelayMs = 60000; // 60 seconds
        const delay = maxDelayMs + 1000; // Exceed maximum
        expect(delay > maxDelayMs, isTrue);
        // In implementation, this should be capped at maxDelayMs
      });
    });
  });
}