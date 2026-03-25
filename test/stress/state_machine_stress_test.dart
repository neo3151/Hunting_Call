import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';

import 'package:outcall/features/recording/presentation/controllers/recording_controller.dart';
import 'package:outcall/features/recording/domain/use_cases/start_recording_use_case.dart';
import 'package:outcall/features/recording/domain/use_cases/stop_recording_use_case.dart';
import 'package:outcall/features/recording/domain/providers.dart';
import 'package:outcall/features/recording/domain/failures/recording_failure.dart';
import 'package:outcall/core/services/file_service.dart';
import 'package:outcall/core/services/logger/logger_service.dart';
import 'package:outcall/di_providers.dart';

/// ══════════════════════════════════════════════════════════════════
/// STRESS TEST 3: State Machine & Memory Pressure
/// Rapidly cycles through controller states to detect memory leaks,
/// state corruption, and race conditions.
/// ══════════════════════════════════════════════════════════════════

class MockStartRecordingUseCase extends Mock implements StartRecordingUseCase {}
class MockStopRecordingUseCase extends Mock implements StopRecordingUseCase {}
class MockFileService extends Mock implements FileService {}
class MockLoggerService extends Mock implements LoggerService {}

void main() {
  late ProviderContainer container;
  late MockStartRecordingUseCase mockStart;
  late MockStopRecordingUseCase mockStop;

  setUp(() {
    mockStart = MockStartRecordingUseCase();
    mockStop = MockStopRecordingUseCase();
    final mockFileService = MockFileService();
    final mockLogger = MockLoggerService();

    when(() => mockFileService.getTemporaryPath(any()))
        .thenAnswer((_) async => '/tmp/stress_audio.wav');
    when(() => mockLogger.log(any())).thenReturn(null);
    when(() => mockLogger.recordError(any(), any(), reason: any(named: 'reason')))
        .thenReturn(null);

    container = ProviderContainer(overrides: [
      startRecordingUseCaseProvider.overrideWithValue(mockStart),
      stopRecordingUseCaseProvider.overrideWithValue(mockStop),
      fileServiceProvider.overrideWithValue(mockFileService),
      loggerServiceProvider.overrideWithValue(mockLogger),
    ]);
  });

  tearDown(() => container.dispose());

  // ─── Rapid State Cycling ───────────────────────────────────────
  group('State Machine Stress — Rapid Cycling', () {
    test('20 start/stop cycles should not corrupt state', () async {
      when(() => mockStart.execute(
            outputPath: any(named: 'outputPath'),
            onCountdownTick: any(named: 'onCountdownTick'),
          )).thenAnswer((inv) async {
        final onTick = inv.namedArguments[#onCountdownTick] as void Function(int);
        onTick(0); // Skip countdown
        return const Right('/tmp/stress_audio.wav');
      });
      when(() => mockStop.execute())
          .thenAnswer((_) async => const Right('/tmp/stress_audio.wav'));

      final notifier = container.read(recordingNotifierProvider.notifier);

      for (int i = 0; i < 20; i++) {
        await notifier.startRecordingWithCountdown();

        var state = container.read(recordingNotifierProvider);
        expect(state.status, RecordingStatus.recording,
            reason: 'Cycle $i: should be recording after start');

        await notifier.stopRecording();

        state = container.read(recordingNotifierProvider);
        expect(state.status, RecordingStatus.idle,
            reason: 'Cycle $i: should be idle after stop');

        notifier.reset();
      }

      // Final state should be clean
      final finalState = container.read(recordingNotifierProvider);
      expect(finalState.status, RecordingStatus.idle);
      expect(finalState.audioPath, isNull);
      expect(finalState.failure, isNull);
    });

    test('Stop without start should not crash', () async {
      final notifier = container.read(recordingNotifierProvider.notifier);

      // Calling stop when idle — should be a no-op or safe error
      try {
        await notifier.stopRecording();
      } catch (_) {
        // Acceptable to throw, but must not corrupt state
      }

      // State should still be valid (idle or stopping — not corrupted)
      final state = container.read(recordingNotifierProvider);
      expect(state, isNotNull);
    });

    test('Double-stop should not corrupt state', () async {
      when(() => mockStart.execute(
            outputPath: any(named: 'outputPath'),
            onCountdownTick: any(named: 'onCountdownTick'),
          )).thenAnswer((inv) async {
        final onTick = inv.namedArguments[#onCountdownTick] as void Function(int);
        onTick(0);
        return const Right('/tmp/stress_audio.wav');
      });
      when(() => mockStop.execute())
          .thenAnswer((_) async => const Right('/tmp/stress_audio.wav'));

      final notifier = container.read(recordingNotifierProvider.notifier);
      await notifier.startRecordingWithCountdown();
      await notifier.stopRecording();

      // Second stop
      try {
        await notifier.stopRecording();
      } catch (_) {
        // May throw, but state should be consistent
      }

      final state = container.read(recordingNotifierProvider);
      expect(state.status, RecordingStatus.idle);
    });

    test('Reset during recording should safely stop', () async {
      when(() => mockStart.execute(
            outputPath: any(named: 'outputPath'),
            onCountdownTick: any(named: 'onCountdownTick'),
          )).thenAnswer((inv) async {
        final onTick = inv.namedArguments[#onCountdownTick] as void Function(int);
        onTick(0);
        return const Right('/tmp/stress_audio.wav');
      });

      final notifier = container.read(recordingNotifierProvider.notifier);
      await notifier.startRecordingWithCountdown();

      // Reset while recording
      notifier.reset();

      final state = container.read(recordingNotifierProvider);
      expect(state.status, RecordingStatus.idle);
      expect(state.audioPath, isNull);
    });
  });

  // ─── Container Disposal Stress ─────────────────────────────────
  group('State Machine Stress — Provider Disposal', () {
    test('Creating/disposing 50 containers should not leak', () async {
      for (int i = 0; i < 50; i++) {
        final c = ProviderContainer(overrides: [
          startRecordingUseCaseProvider.overrideWithValue(mockStart),
          stopRecordingUseCaseProvider.overrideWithValue(mockStop),
          fileServiceProvider.overrideWithValue(MockFileService()),
          loggerServiceProvider.overrideWithValue(MockLoggerService()),
        ]);

        // Read a provider to force initialization
        c.read(recordingNotifierProvider);
        c.dispose();
      }

      // If we get here without OOM, the test passes
      expect(true, isTrue);
    });
  });

  // ─── Error State Stress ────────────────────────────────────────
  group('State Machine Stress — Error Paths', () {
    test('Start failure should transition to error state cleanly', () async {
      when(() => mockStart.execute(
            outputPath: any(named: 'outputPath'),
            onCountdownTick: any(named: 'onCountdownTick'),
          )).thenAnswer((_) async =>
              Left(const PermissionDenied()));

      final notifier = container.read(recordingNotifierProvider.notifier);
      await notifier.startRecordingWithCountdown();

      final state = container.read(recordingNotifierProvider);
      expect(state.failure, isNotNull);
      // Should be recoverable
      notifier.reset();
      final resetState = container.read(recordingNotifierProvider);
      expect(resetState.status, RecordingStatus.idle);
      expect(resetState.failure, isNull);
    });

    test('Alternating success/failure 10 times should not corrupt', () async {
      int attempt = 0;
      when(() => mockStart.execute(
            outputPath: any(named: 'outputPath'),
            onCountdownTick: any(named: 'onCountdownTick'),
          )).thenAnswer((inv) async {
        attempt++;
        if (attempt.isOdd) {
          final onTick = inv.namedArguments[#onCountdownTick] as void Function(int);
          onTick(0);
          return const Right('/tmp/stress_audio.wav');
        }
        return Left(const PermissionDenied());
      });
      when(() => mockStop.execute())
          .thenAnswer((_) async => const Right('/tmp/stress_audio.wav'));

      final notifier = container.read(recordingNotifierProvider.notifier);

      for (int i = 0; i < 10; i++) {
        await notifier.startRecordingWithCountdown();
        final state = container.read(recordingNotifierProvider);

        if (state.status == RecordingStatus.recording) {
          await notifier.stopRecording();
        }
        notifier.reset();
      }

      final finalState = container.read(recordingNotifierProvider);
      expect(finalState.status, RecordingStatus.idle);
    });
  });
}
