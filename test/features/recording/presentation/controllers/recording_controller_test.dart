import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';

import 'package:hunting_calls_perfection/features/recording/presentation/controllers/recording_controller.dart';
import 'package:hunting_calls_perfection/features/recording/domain/use_cases/start_recording_use_case.dart';
import 'package:hunting_calls_perfection/features/recording/domain/use_cases/stop_recording_use_case.dart';
import 'package:hunting_calls_perfection/features/recording/domain/providers.dart';
import 'package:hunting_calls_perfection/core/services/file_service.dart';
import 'package:hunting_calls_perfection/core/services/logger/logger_service.dart';
import 'package:hunting_calls_perfection/features/recording/domain/failures/recording_failure.dart';
import 'package:hunting_calls_perfection/di_providers.dart';

// Mocks
class MockStartRecordingUseCase extends Mock implements StartRecordingUseCase {}
class MockStopRecordingUseCase extends Mock implements StopRecordingUseCase {}
class MockFileService extends Mock implements FileService {}
class MockLoggerService extends Mock implements LoggerService {}

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

    // Default mock behaviors
    when(() => mockFileService.getTemporaryPath(any()))
        .thenAnswer((_) async => '/tmp/test_audio.wav');

    when(() => mockLoggerService.log(any())).thenReturn(null);
    when(() => mockLoggerService.recordError(any(), any(), reason: any(named: 'reason'))).thenReturn(null);

    // Initialize Riverpod container with mocked dependencies
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

  group('RecordingController / RecordingNotifier Tests', () {
    test('Initial state is idle', () {
      final state = container.read(recordingNotifierProvider);
      
      expect(state.status, RecordingStatus.idle);
      expect(state.isRecording, false);
      expect(state.isCountingDown, false);
      expect(state.hasError, false);
      expect(state.audioPath, isNull);
    });

    test('startRecordingWithCountdown enters countdown and then recording on success', () async {
      // 1. Arrange
      when(() => mockStartUseCase.execute(
        outputPath: any(named: 'outputPath'),
        onCountdownTick: any(named: 'onCountdownTick'),
      )).thenAnswer((invocation) async {
        // Simulate a single countdown tick
        final onTick = invocation.namedArguments[#onCountdownTick] as void Function(int);
        onTick(3);
        onTick(0);
        return const Right('/tmp/test_audio.wav');
      });

      // 2. Act
      final future = container.read(recordingNotifierProvider.notifier).startRecordingWithCountdown();
      
      // Before await finishes, it sets status to countdown
      var state = container.read(recordingNotifierProvider);
      expect(state.isCountingDown, true);

      await future;

      // 3. Assert - After successful start, it should be recording
      state = container.read(recordingNotifierProvider);
      expect(state.status, RecordingStatus.recording);
      expect(state.isRecording, true);
      expect(state.hasError, false);
      
      // Ensure the logging safety net captured the event
      verify(() => mockLoggerService.log(any(that: contains('Start recording pressed')))).called(1);
      verify(() => mockLoggerService.log(any(that: contains('Recording actually started')))).called(1);
    });

    test('startRecordingWithCountdown enters error state if use case fails', () async {
      // 1. Arrange
      const failure = PermissionDenied();
      when(() => mockStartUseCase.execute(
        outputPath: any(named: 'outputPath'),
        onCountdownTick: any(named: 'onCountdownTick'),
      )).thenAnswer((_) async {
        return Left(failure);
      });

      // 2. Act
      await container.read(recordingNotifierProvider.notifier).startRecordingWithCountdown();

      // 3. Assert
      final state = container.read(recordingNotifierProvider);
      expect(state.status, RecordingStatus.error);
      expect(state.hasError, true);
      expect(state.failure, equals(failure));

      // Ensure error was logged securely
      verify(() => mockLoggerService.recordError(failure, any(), reason: 'Failed to start recording')).called(1);
    });

    test('stopRecording returns audio path and goes idle on success', () async {
      // 1. Arrange: App is currently recording
      // We manually set the state to simulate recording mode is easier, 
      // but since state is immutable and handled by theNotifier, we can just execute the action.
      when(() => mockStopUseCase.execute()).thenAnswer((_) async => const Right('/tmp/test_audio.wav'));

      // 2. Act
      final resultPath = await container.read(recordingNotifierProvider.notifier).stopRecording();

      // 3. Assert
      final state = container.read(recordingNotifierProvider);
      expect(resultPath, '/tmp/test_audio.wav');
      expect(state.status, RecordingStatus.idle);
      expect(state.audioPath, '/tmp/test_audio.wav');

      // Check log
      verify(() => mockLoggerService.log(any(that: contains('Recording stopped successfully: /tmp/test_audio.wav')))).called(1);
    });
    
    test('stopRecording captures and logs failure', () async {
      // 1. Arrange
      const failure = RecordingServiceError('Recorder crashed');
      when(() => mockStopUseCase.execute()).thenAnswer((_) async => const Left(failure));

      // 2. Act
      final resultPath = await container.read(recordingNotifierProvider.notifier).stopRecording();

      // 3. Assert
      final state = container.read(recordingNotifierProvider);
      expect(resultPath, isNull);
      expect(state.status, RecordingStatus.error);
      expect(state.failure, equals(failure));

      // Check log
      verify(() => mockLoggerService.recordError(failure, any(), reason: 'Failed to stop recording')).called(1);
    });

    test('reset clears everything', () {
      // Manually enter a dirty state via a fake start sequence, or just call reset and verify
      container.read(recordingNotifierProvider.notifier).reset();
      final state = container.read(recordingNotifierProvider);
      expect(state.status, RecordingStatus.idle);
      expect(state.audioPath, isNull);
      expect(state.failure, isNull);
      expect(state.recordDuration, 0);
    });
  });
}
