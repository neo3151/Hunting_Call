import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hunting_calls_perfection/main.dart';
import 'package:hunting_calls_perfection/injection_container.dart' as di;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App loads and shows login or home', (WidgetTester tester) async {
    // Setup Mock Dependencies
    SharedPreferences.setMockInitialValues({});
    await di.init();

    // Pump the app
    await tester.pumpWidget(const HuntingCallsApp());
    await tester.pumpAndSettle();

    // Check if we are on the login screen
    expect(find.text('HUNTING\nCALLS'), findsOneWidget);
    expect(find.byIcon(Icons.forest_rounded), findsOneWidget);
  });
}
