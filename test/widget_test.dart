import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hunting_calls_perfection/main.dart';
import 'package:hunting_calls_perfection/injection_container.dart' as di;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hunting_calls_perfection/features/splash/presentation/splash_screen.dart';

void main() {
  testWidgets('App loads without crashing', (WidgetTester tester) async {
    // Setup Mock Dependencies
    SharedPreferences.setMockInitialValues({});
    await di.init();

    // Pump the app
    await tester.pumpWidget(const HuntingCallsApp());
    
    // Just verify the app builds without errors
    // The splash screen should appear first
    expect(find.byType(SplashScreen), findsOneWidget);

    // Wait for the splash screen timer and navigation
    await tester.pumpAndSettle(const Duration(seconds: 4));
    
    // Verify we are still alive (might be at AuthWrapper now)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
