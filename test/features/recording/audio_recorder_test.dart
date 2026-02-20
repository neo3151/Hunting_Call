import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:hunting_calls_perfection/features/recording/data/repositories/mock_audio_recorder_service.dart';

void main() {
  late MockAudioRecorderService recorder;

  setUp(() {
    recorder = MockAudioRecorderService();
  });

  tearDown(() {
    recorder.dispose();
  });

  group('MockAudioRecorderService', () {
    test('initial state is not recording', () {
      expect(recorder.isRecording, isFalse);
    });

    test('lastError is null initially', () {
      expect(recorder.lastError, isNull);
    });

    test('init completes without error', () async {
      await expectLater(recorder.init(), completes);
    });

    test('startRecorder sets isRecording to true', () async {
      await recorder.init();
      final result = await recorder.startRecorder('/tmp/test_recording.wav');

      expect(result, isTrue);
      expect(recorder.isRecording, isTrue);
    });

    test('stopRecorder sets isRecording to false and returns path', () async {
      await recorder.init();
      await recorder.startRecorder('/tmp/test_recording.wav');

      final path = await recorder.stopRecorder();

      expect(recorder.isRecording, isFalse);
      expect(path, isNotNull);
      expect(path, isNotEmpty);
    });

    test('amplitude stream emits values during recording', () async {
      await recorder.init();

      final amplitudes = <double>[];
      final sub = recorder.onAmplitudeChanged.listen(amplitudes.add);

      await recorder.startRecorder('/tmp/test_recording.wav');

      // Wait for a few amplitude emissions (timer fires every 100ms)
      await Future.delayed(const Duration(milliseconds: 350));

      await recorder.stopRecorder();
      await sub.cancel();

      // Should have received at least 2-3 amplitude values
      expect(amplitudes.length, greaterThanOrEqualTo(2));

      // All values should be between 0 and 1
      for (final amp in amplitudes) {
        expect(amp, inInclusiveRange(0, 1));
      }
    });

    test('stopRecorder emits 0.0 amplitude', () async {
      await recorder.init();

      late StreamSubscription sub;
      sub = recorder.onAmplitudeChanged.listen((amp) {
        // Capture the last value after stop
      });

      await recorder.startRecorder('/tmp/test_recording.wav');
      await Future.delayed(const Duration(milliseconds: 150));

      // Listen for the 0.0 value emitted on stop
      double? lastValue;
      sub.cancel();
      final stopSub = recorder.onAmplitudeChanged.listen((amp) {
        lastValue = amp;
      });

      await recorder.stopRecorder();
      await Future.delayed(const Duration(milliseconds: 50));
      await stopSub.cancel();

      expect(lastValue, 0.0);
    });

    test('cleanupOldFiles completes without error', () async {
      await expectLater(recorder.cleanupOldFiles(), completes);
    });

    test('double start does not crash', () async {
      await recorder.init();
      await recorder.startRecorder('/tmp/test1.wav');
      // Starting again shouldn't crash
      await recorder.startRecorder('/tmp/test2.wav');
      expect(recorder.isRecording, isTrue);
      await recorder.stopRecorder();
    });

    test('stop without start does not crash', () async {
      await recorder.stopRecorder();
      // Should handle gracefully
      expect(recorder.isRecording, isFalse);
    });

    test('dispose can be called multiple times safely', () {
      recorder.dispose();
      // Second dispose should not throw
      expect(() => recorder.dispose(), returnsNormally);
    });
  });
}
