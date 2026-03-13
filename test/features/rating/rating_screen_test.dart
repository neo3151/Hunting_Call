import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:outcall/di_providers.dart';
import 'package:outcall/features/rating/presentation/controllers/rating_controller.dart';
import 'package:outcall/features/rating/presentation/rating_screen.dart';
import 'package:outcall/l10n/app_localizations.dart';

void main() {
  late SharedPreferences mockPrefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockPrefs = await SharedPreferences.getInstance();
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        platformEnvironmentProvider.overrideWithValue(PlatformEnvironment(
          isFirebaseEnabled: false,
          isDesktop: false,
          useMocks: true,
          sharedPreferences: mockPrefs,
        )),
      ],
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: const RatingScreen(
          audioPath: '/test/dummy.wav',
          animalId: 'turkey_yelp',
          userId: 'test_user',
        ),
      ),
    );
  }

  testWidgets('RatingScreen renders successfully', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    expect(find.byType(RatingScreen), findsOneWidget);
  });

  testWidgets('RatingScreen shows review state initially', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(const Duration(milliseconds: 500));

    // Review state shows play and analyze buttons
    expect(find.text('REVIEW RECORDING'), findsOneWidget);
  });

  test('RatingNotifier initializes with idle state', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        platformEnvironmentProvider.overrideWithValue(PlatformEnvironment(
          isFirebaseEnabled: false,
          isDesktop: true,
          useMocks: true,
          sharedPreferences: prefs,
        )),
      ],
    );
    addTearDown(container.dispose);

    final state = container.read(ratingNotifierProvider);
    expect(state.isAnalyzing, isFalse);
    expect(state.result, isNull);
    expect(state.error, isNull);
  });

  test('RatingNotifier.reset clears state', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        platformEnvironmentProvider.overrideWithValue(PlatformEnvironment(
          isFirebaseEnabled: false,
          isDesktop: true,
          useMocks: true,
          sharedPreferences: prefs,
        )),
      ],
    );
    addTearDown(container.dispose);

    container.read(ratingNotifierProvider.notifier).reset();
    final state = container.read(ratingNotifierProvider);
    expect(state.isAnalyzing, isFalse);
    expect(state.result, isNull);
  });
}
