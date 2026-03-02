import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';

import 'package:outcall/features/recording/presentation/controllers/recording_controller.dart';
import 'package:outcall/features/recording/domain/use_cases/start_recording_use_case.dart';
import 'package:outcall/features/recording/domain/use_cases/stop_recording_use_case.dart';
import 'package:outcall/features/recording/domain/providers.dart';
import 'package:outcall/core/services/file_service.dart';
import 'package:outcall/core/services/logger/logger_service.dart';
import 'package:outcall/di_providers.dart';

// Mocks
class MockStartRecordingUseCase extends Mock implements StartRecordingUseCase {}

class MockStopRecordingUseCase extends Mock implements StopRecordingUseCase {}

class MockFileService extends Mock implements FileService {}

class MockLoggerService extends Mock implements LoggerService {}

/// Integration test: verifies the full recording lifecycle
/// idle → countdown → recording → stop → idle (with audio path)
void main() {
  late ProviderContainer container;
  late MockStartRecordingUseCase mockStartUseCase;
  late MockStopRecordingUseCase mockStopUseCase;
  late MockFileService mockFileService;
  late MockLoggerService mockLoggerService;

  setUp(() {
    mockStartUseCase = MockStartRecordingUseCase();
    mockStopUseCase = MockStopRecordingUseCase();
    mockFileService = MockFileService();
    mockLoggerService = MockLoggerService();

    when(() => mockFileService.getTemporaryPath(any()))
        .thenAnswer((_) async => '/tmp/flow_test_audio.wav');
    when(() => mockLoggerService.log(any())).thenReturn(null);
    when(() => mockLoggerService.recordError(any(), any(),
        reason: any(named: 'reason'))).thenReturn(null);

    container = ProviderContainer(
      overrides: [
        startRecordingUseCaseProvider.overrideWithValue(mockStartUseCase),
        stopRecordingUseCaseProvider.overrideWithValue(mockStopUseCase),
        fileServiceProvider.overrideWithValue(mockFileService),
        loggerServiceProvider.overrideWithValue(mockLoggerService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('Recording Flow Integration', () {
    test('Full lifecycle: idle → countdown → recording → stop → idle', () async {
      // Arrange: successful start with countdown ticks
      when(() => mockStartUseCase.execute(
            outputPath: any(named: 'outputPath'),
            onCountdownTick: any(named: 'onCountdownTick'),
          )).thenAnswer((invocation) async {
        final onTick =
            invocation.namedArguments[#onCountdownTick] as void Function(int);
        onTick(3);
        onTick(2);
        onTick(1);
        onTick(0);
        return const Right('/tmp/flow_test_audio.wav');
      });
      when(() => mockStopUseCase.execute())
          .thenAnswer((_) async => const Right('/tmp/flow_test_audio.wav'));

      final notifier = container.read(recordingNotifierProvider.notifier);

      // 1. Verify idle state
      var state = container.read(recordingNotifierProvider);
      expect(state.status, RecordingStatus.idle, reason: 'Should start idle');

      // 2. Start recording (triggers countdown → recording)
      await notifier.startRecordingWithCountdown();
      state = container.read(recordingNotifierProvider);
      expect(state.status, RecordingStatus.recording,
          reason: 'Should be recording after countdown');
      expect(state.isRecording, true);

      // 3. Stop recording
      final path = await notifier.stopRecording();
      state = container.read(recordingNotifierProvider);
      expect(path, '/tmp/flow_test_audio.wav');
      expect(state.status, RecordingStatus.idle,
          reason: 'Should return to idle after stop');
      expect(state.audioPath, '/tmp/flow_test_audio.wav');
    });

    test('Double-start is idempotent when already recording', () async {
      when(() => mockStartUseCase.execute(
            outputPath: any(named: 'outputPath'),
            onCountdownTick: any(named: 'onCountdownTick'),
          )).thenAnswer((invocation) async {
        final onTick =
            invocation.namedArguments[#onCountdownTick] as void Function(int);
        onTick(0);
        return const Right('/tmp/flow_test_audio.wav');
      });

      final notifier = container.read(recordingNotifierProvider.notifier);

      await notifier.startRecordingWithCountdown();
      final firstState = container.read(recordingNotifierProvider);
      expect(firstState.status, RecordingStatus.recording);

      // Second start should not crash
      await notifier.startRecordingWithCountdown();
      final secondState = container.read(recordingNotifierProvider);
      expect(secondState.status, RecordingStatus.recording);
    });

    test('Reset after recording clears all state', () async {
      when(() => mockStartUseCase.execute(
            outputPath: any(named: 'outputPath'),
            onCountdownTick: any(named: 'onCountdownTick'),
          )).thenAnswer((invocation) async {
        final onTick =
            invocation.namedArguments[#onCountdownTick] as void Function(int);
        onTick(0);
        return const Right('/tmp/flow_test_audio.wav');
      });
      when(() => mockStopUseCase.execute())
          .thenAnswer((_) async => const Right('/tmp/flow_test_audio.wav'));

      final notifier = container.read(recordingNotifierProvider.notifier);
      await notifier.startRecordingWithCountdown();
      await notifier.stopRecording();

      // Reset
      notifier.reset();
      final state = container.read(recordingNotifierProvider);
      expect(state.status, RecordingStatus.idle);
      expect(state.audioPath, isNull);
      expect(state.failure, isNull);
      expect(state.recordDuration, 0);
    });
  });
}
