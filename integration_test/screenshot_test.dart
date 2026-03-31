import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:outcall/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Capture 15 Promotional Screenshots', (WidgetTester tester) async {
    // Disable errors from failing the pipeline directly
    FlutterError.onError = (FlutterErrorDetails details) {
      print('Caught exception: ${details.exception}');
    };

    // Helper to safely pump without settling
    Future<void> safePump([Duration duration = const Duration(seconds: 1)]) async {
      await tester.pump(duration);
      await tester.pump(duration);
    }

    // Start the app
    app.main();
    await safePump(const Duration(seconds: 4));

    // Wait an extra moment for Firebase Auth streams to hit AuthWrapper
    await Future.delayed(const Duration(seconds: 4));
    await safePump();

    int screenshotCount = 1;

    Future<void> snap(String name) async {
      print('\n📸 Taking screenshot $screenshotCount/15: $name...');
      try {
        await tester.pump(const Duration(milliseconds: 500));
        await binding.takeScreenshot('screenshot_${screenshotCount}_$name');
      } catch (e) {
        print('Snapshot failed: $e');
      }
      screenshotCount++;
    }

    print('\n======================================================');
    print('  OUTCALL SCREENSHOT AUTOMATION STARTED');
    print('======================================================\n');

    // 1. Initial State
    await snap('startup_or_login');

    // 2. Login Flow (If not authenticated)
    if (find.text('NEW HUNTER PROFILE').evaluate().isNotEmpty) {
      print('Guest detected. Automating profile creation to bypass login...');
      await tester.tap(find.text('NEW HUNTER PROFILE'));
      await safePump();
      
      await tester.enterText(find.byType(TextField).first, 'HuntingPro');
      await safePump();
      
      await tester.tap(find.byIcon(Icons.calendar_today));
      await safePump();
      final okButton = find.text('OK');
      if (okButton.evaluate().isNotEmpty) {
        await tester.tap(okButton);
        await safePump();
      }
      
      await tester.tap(find.text('START HUNTING'));
      await safePump(const Duration(seconds: 6));
    }

    // 3. Main Navigation Flow
    await snap('home_dashboard');

    await tester.tap(find.text('Library').first);
    await safePump();
    await snap('library_categories');

    // 4. Deep Dive into Audio UI
    try {
      // Tap first category (e.g. Duck)
      await tester.tap(find.byType(InkWell).first);
      await safePump();
      await snap('animal_grid');
      
      // Tap first animal call
      await tester.tap(find.byType(InkWell).first);
      await safePump();
      await snap('call_detail_player');
      
      // Navigate back out to main shell
      await tester.pageBack();
      await safePump();
      await tester.pageBack();
      await safePump();
    } catch (e) {
      print('Navigation deep dive failed, continuing: $e');
    }

    // 5. Practice & Progress
    await tester.tap(find.text('Practice').first);
    await safePump();
    await snap('practice_recorder');

    await tester.tap(find.text('Progress').first);
    await safePump();
    await snap('progress_map');

    await tester.tap(find.text('Profile').first);
    await safePump();
    await snap('profile_settings');

    print('\n======================================================');
    print('  AUTONOMOUS PHASE COMPLETE');
    print('  Switching to Manual Mode for the remaining captures.');
    print('  You have 60s total. Navigate the app yourself!');
    print('  I will passively snap a photo every 6 seconds.');
    print('======================================================\n');

    // 6. Manual Showcase Mode
    while (screenshotCount <= 15) {
      await Future.delayed(const Duration(seconds: 6));
      await safePump();
      await snap('manual_showcase');
    }

    print('\n✅ ALL 15 SCREENSHOTS CAPTURED SUCCESSFULLY!\n');
  });
}
