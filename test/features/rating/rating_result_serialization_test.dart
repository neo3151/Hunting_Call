import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/features/rating/domain/rating_model.dart';

void main() {
  group('RatingResult serialization', () {
    test('JSON roundtrip preserves all fields', () {
      final original = RatingResult(
        score: 92.3,
        feedback: 'Excellent!',
        pitchHz: 523.25,
        metrics: {
          'score_pitch': 95.0,
          'score_timbre': 88.0,
          'score_rhythm': 91.0,
          'score_duration': 90.0,
        },
        latitude: 45.0,
        longitude: -93.0,
      );
      final json = original.toJson();
      final restored = RatingResult.fromJson(json);

      expect(restored.score, original.score);
      expect(restored.feedback, original.feedback);
      expect(restored.pitchHz, original.pitchHz);
      expect(restored.metrics['score_pitch'], 95.0);
      expect(restored.latitude, 45.0);
      expect(restored.longitude, -93.0);
    });

    test('waveform data survives serialization', () {
      final result = RatingResult(
        score: 75.0,
        feedback: 'OK',
        pitchHz: 330.0,
        metrics: {},
        userWaveform: [0.1, 0.5, 0.3, 0.8],
        referenceWaveform: [0.2, 0.4, 0.6, 0.7],
      );
      final json = result.toJson();
      final restored = RatingResult.fromJson(json);

      expect(restored.userWaveform, isNotNull);
      expect(restored.userWaveform!.length, 4);
      expect(restored.referenceWaveform!.length, 4);
    });

    test('null optional fields survive serialization', () {
      final result = RatingResult(
        score: 50.0,
        feedback: 'Test',
        pitchHz: 220.0,
        metrics: {},
      );
      final json = result.toJson();
      final restored = RatingResult.fromJson(json);

      expect(restored.userWaveform, isNull);
      expect(restored.referenceWaveform, isNull);
      expect(restored.latitude, isNull);
      expect(restored.longitude, isNull);
    });

    test('edge case scores serialize correctly', () {
      for (final s in [0.0, 1.0, 50.0, 99.99, 100.0]) {
        final result = RatingResult(
          score: s,
          feedback: 'Score: $s',
          pitchHz: 440.0,
          metrics: {},
        );
        final restored = RatingResult.fromJson(result.toJson());
        expect(restored.score, s);
      }
    });
  });
}
