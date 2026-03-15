import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/features/recording/domain/entities/recording.dart';
import 'package:outcall/features/recording/domain/failures/recording_failure.dart';

void main() {
  group('Recording', () {
    final now = DateTime(2026, 3, 13, 12, 0);

    Recording makeRecording({String id = 'rec_1', double? score}) {
      return Recording(
        id: id,
        userId: 'user_1',
        animalId: 'elk_bugle',
        audioPath: '/recordings/elk.wav',
        recordedAt: now,
        duration: const Duration(seconds: 5),
        score: score,
      );
    }

    test('stores all required fields', () {
      final rec = makeRecording();
      expect(rec.id, 'rec_1');
      expect(rec.userId, 'user_1');
      expect(rec.animalId, 'elk_bugle');
      expect(rec.audioPath, '/recordings/elk.wav');
      expect(rec.recordedAt, now);
      expect(rec.duration.inSeconds, 5);
      expect(rec.score, isNull);
    });

    test('score is optional', () {
      final withScore = makeRecording(score: 85.0);
      expect(withScore.score, 85.0);
    });

    test('copyWith preserves unchanged fields', () {
      final rec = makeRecording(score: 80.0);
      final copy = rec.copyWith(animalId: 'duck_quack');
      expect(copy.animalId, 'duck_quack');
      expect(copy.id, 'rec_1');
      expect(copy.score, 80.0);
    });

    test('equality by id only', () {
      final a = makeRecording(id: 'rec_1', score: 80.0);
      final b = makeRecording(id: 'rec_1', score: 90.0);
      expect(a, equals(b));
    });

    test('different ids are not equal', () {
      final a = makeRecording(id: 'rec_1');
      final b = makeRecording(id: 'rec_2');
      expect(a, isNot(equals(b)));
    });

    test('hashCode based on id', () {
      final rec = makeRecording(id: 'rec_xyz');
      expect(rec.hashCode, 'rec_xyz'.hashCode);
    });

    test('toString includes key info', () {
      final rec = makeRecording(score: 75.0);
      final str = rec.toString();
      expect(str, contains('rec_1'));
      expect(str, contains('elk_bugle'));
    });
  });

  group('RecordingFailure', () {
    test('PermissionDenied message', () {
      const f = PermissionDenied();
      expect(f.message, contains('permission'));
      expect(f, isA<RecordingFailure>());
    });

    test('RecordingInProgress message', () {
      const f = RecordingInProgress();
      expect(f.message, contains('in progress'));
    });

    test('RecordingTooShort includes durations', () {
      const f = RecordingTooShort(Duration(seconds: 2), Duration(seconds: 1));
      expect(f.message, contains('2'));
      expect(f.message, contains('1'));
      expect(f.minDuration, const Duration(seconds: 2));
      expect(f.actualDuration, const Duration(seconds: 1));
    });

    test('RecordingServiceError includes details', () {
      const f = RecordingServiceError('Microphone busy');
      expect(f.message, contains('Microphone busy'));
    });

    test('FileSystemError includes details', () {
      const f = FileSystemError('Disk full');
      expect(f.message, contains('Disk full'));
    });

    test('RecordingNotFound includes id', () {
      const f = RecordingNotFound('rec_999');
      expect(f.message, contains('rec_999'));
      expect(f.id, 'rec_999');
    });

    test('all failures are RecordingFailure subtypes', () {
      const failures = <RecordingFailure>[
        PermissionDenied(),
        RecordingInProgress(),
        RecordingTooShort(Duration(seconds: 2), Duration(seconds: 1)),
        RecordingServiceError('test'),
        FileSystemError('test'),
        RecordingNotFound('test'),
      ];
      for (final f in failures) {
        expect(f, isA<RecordingFailure>());
        expect(f.message.isNotEmpty, true);
      }
    });
  });
}
