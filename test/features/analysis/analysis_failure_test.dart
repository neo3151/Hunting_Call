import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/features/analysis/domain/failures/analysis_failure.dart';

void main() {
  group('AnalysisFailure', () {
    test('AudioFileNotFound has correct message', () {
      const failure = AudioFileNotFound('/path/to/file.wav');
      expect(failure.message, contains('/path/to/file.wav'));
      expect(failure.message, contains('not found'));
      expect(failure.path, '/path/to/file.wav');
    });

    test('InvalidAudioFormat has correct message', () {
      const failure = InvalidAudioFormat('Unsupported codec');
      expect(failure.message, contains('Unsupported codec'));
      expect(failure.message, contains('Invalid audio'));
    });

    test('AnalysisComputationError has correct message', () {
      const failure = AnalysisComputationError('FFT buffer overflow');
      expect(failure.message, contains('FFT buffer overflow'));
      expect(failure.message, contains('Analysis failed'));
    });

    test('ReferenceDataNotFound has correct message', () {
      const failure = ReferenceDataNotFound('elk_bugle');
      expect(failure.message, contains('elk_bugle'));
      expect(failure.message, contains('Reference data'));
      expect(failure.animalId, 'elk_bugle');
    });

    test('InsufficientAudioData has correct message', () {
      const failure = InsufficientAudioData('Less than 0.5s');
      expect(failure.message, contains('Less than 0.5s'));
      expect(failure.message, contains('Insufficient'));
    });

    test('all failures are AnalysisFailure subtypes', () {
      const failures = <AnalysisFailure>[
        AudioFileNotFound('/test'),
        InvalidAudioFormat('test'),
        AnalysisComputationError('test'),
        ReferenceDataNotFound('test'),
        InsufficientAudioData('test'),
      ];
      for (final f in failures) {
        expect(f, isA<AnalysisFailure>());
        expect(f.message.isNotEmpty, true);
      }
    });
  });
}
