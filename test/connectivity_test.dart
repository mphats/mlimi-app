import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mulimi/core/constants/app_constants.dart';

void main() {
  group('Connectivity Tests', () {
    group('Connectivity Logic Tests', () {
      test('ConnectivityResult list with wifi is considered online', () {
        final result = [ConnectivityResult.wifi];
        final isConnected = result.any((r) => r != ConnectivityResult.none);
        expect(isConnected, isTrue);
      });

      test('ConnectivityResult list with mobile is considered online', () {
        final result = [ConnectivityResult.mobile];
        final isConnected = result.any((r) => r != ConnectivityResult.none);
        expect(isConnected, isTrue);
      });

      test('ConnectivityResult list with none is considered offline', () {
        final result = [ConnectivityResult.none];
        final isConnected = result.any((r) => r != ConnectivityResult.none);
        expect(isConnected, isFalse);
      });

      test('ConnectivityResult list with mixed results is considered online', () {
        final result = [ConnectivityResult.none, ConnectivityResult.wifi];
        final isConnected = result.any((r) => r != ConnectivityResult.none);
        expect(isConnected, isTrue);
      });
    });

    group('URL Configuration Tests', () {
      test('AppConstants baseUrl is properly formatted', () {
        final baseUrl = AppConstants.baseUrl;
        expect(baseUrl, isNotEmpty);
        expect(baseUrl, startsWith('http'));
      });

      test('AppConstants apiV1 includes version path', () {
        final apiV1 = AppConstants.apiV1;
        expect(apiV1, contains('/api/v1'));
      });

      test('WebSocket URL is properly formatted', () {
        final wsUrl = AppConstants.wsUrl;
        expect(wsUrl, isNotEmpty);
        expect(wsUrl, startsWith('ws'));
      });
    });
  });
}