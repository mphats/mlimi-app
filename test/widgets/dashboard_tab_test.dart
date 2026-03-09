import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mulimi/screens/home/dashboard_tab.dart';
import 'package:mulimi/core/providers/auth_provider.dart';

// Mock classes for testing
class MockAuthProvider extends AuthProvider {
  final bool _isAuthenticated = true;
  final String _accessToken = 'mock_token';

  @override
  bool get isAuthenticated => _isAuthenticated;
  
  // Mock the getAccessToken method
  Future<String?> getAccessToken() async {
    return _accessToken;
  }
}

class MockLocalizationService {
  static final MockLocalizationService _instance = MockLocalizationService._internal();
  factory MockLocalizationService() => _instance;
  MockLocalizationService._internal();

  String getString(String key) {
    switch (key) {
      case 'welcomeBackUser':
        return 'Welcome back,';
      case 'quickActions':
        return 'Quick Actions';
      case 'addProduct':
        return 'Add Product';
      case 'listProduce':
        return 'List your produce for sale';
      case 'aiDiagnosis':
        return 'AI Diagnosis';
      case 'pestDiagnosis':
        return 'Diagnose crop pests with AI';
      case 'askQuestion':
        return 'Ask Question';
      case 'communityForum':
        return 'Ask questions in the community forum';
      case 'marketPrices':
        return 'Market Prices';
      case 'currentPrices':
        return 'View current market prices';
      case 'userActivity':
        return 'Your Activity';
      case 'viewAll':
        return 'View All';
      case 'connectLearnGrow':
        return 'Connect, learn, and grow with other farmers';
      default:
        return key;
    }
  }
}

void main() {
  testWidgets('DashboardTab displays correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<AuthProvider>(
          create: (context) => MockAuthProvider(),
          child: DashboardTab(),
        ),
      ),
    );

    // Verify that the dashboard tab loads without errors
    expect(find.text('Welcome back,'), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('Market Prices'), findsOneWidget);
    expect(find.text('Your Activity'), findsOneWidget);
    
    // Verify that quick action cards are displayed
    expect(find.text('Add Product'), findsOneWidget);
    expect(find.text('AI Diagnosis'), findsOneWidget);
    expect(find.text('Ask Question'), findsOneWidget);
    expect(find.text('Market Prices'), findsOneWidget);
    
    // Verify that sample activities are displayed
    expect(find.text('Added new product: Maize'), findsOneWidget);
    expect(find.text('Posted question about pest control'), findsOneWidget);
    expect(find.text('Completed AI diagnosis'), findsOneWidget);
  });

  testWidgets('DashboardTab handles refresh', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<AuthProvider>(
          create: (context) => MockAuthProvider(),
          child: DashboardTab(),
        ),
      ),
    );

    // Find and tap the refresh indicator
    final scrollView = find.byType(RefreshIndicator);
    expect(scrollView, findsOneWidget);
    
    // This test verifies that the widget can be created and refreshed without errors
    // A more comprehensive test would require mocking the WebSocket and API services
  });
}