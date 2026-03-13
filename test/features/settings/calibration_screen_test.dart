import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:outcall/di_providers.dart';
import 'package:outcall/features/settings/presentation/calibration_screen.dart';
import 'package:outcall/features/settings/presentation/controllers/calibration_controller.dart';
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
      child: const MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: CalibrationScreen(),
      ),
    );
  }

  testWidgets('Should display calibration header and sections', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('CALIBRATE SCORING'), findsOneWidget);
    expect(find.text('AMBIENT NOISE TEST'), findsOneWidget);
    expect(find.text('SCORE OFFSET'), findsOneWidget);
    expect(find.text('MIC SENSITIVITY'), findsOneWidget);
  });

  testWidgets('Should display noise test button', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Start Noise Test'), findsOneWidget);
  });

  testWidgets('Should display save and reset buttons', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);
  });

  testWidgets('Score offset slider starts at 0', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('+0 points'), findsOneWidget);
  });

  testWidgets('Mic sensitivity starts at 1.0x', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('1.0x'), findsWidgets); // label + value display
  });

  test('CalibrationNotifier initializes with default state', () async {
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

    final state = container.read(calibrationNotifierProvider);
    expect(state.scoreOffset, 0.0);
    expect(state.micSensitivity, 1.0);
    expect(state.noiseFloorLevel, 0.0);
    expect(state.isMeasuring, false);
    expect(state.noiseMeasured, false);
  });

  test('CalibrationNotifier.setScoreOffset updates state', () async {
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

    container.read(calibrationNotifierProvider.notifier).setScoreOffset(10.0);
    expect(container.read(calibrationNotifierProvider).scoreOffset, 10.0);
  });

  test('CalibrationNotifier.setMicSensitivity updates state', () async {
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

    container.read(calibrationNotifierProvider.notifier).setMicSensitivity(1.5);
    expect(container.read(calibrationNotifierProvider).micSensitivity, 1.5);
  });

  test('CalibrationNotifier.reset clears state to defaults', () async {
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

    // Modify state
    final notifier = container.read(calibrationNotifierProvider.notifier);
    notifier.setScoreOffset(15.0);
    notifier.setMicSensitivity(1.8);
    expect(container.read(calibrationNotifierProvider).scoreOffset, 15.0);

    // Reset
    notifier.reset();
    final resetState = container.read(calibrationNotifierProvider);
    expect(resetState.scoreOffset, 0.0);
    expect(resetState.micSensitivity, 1.0);
  });
}
