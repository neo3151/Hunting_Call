import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/features/rating/domain/rating_model.dart';

void main() {
  group('RatingResult Model', () {
    test('score stays within 0-100 range for valid input', () {
      final rating = RatingResult(
        score: 85.0,
        feedback: 'Great call!',
        pitchHz: 440.0,
        metrics: {'pitch': 90.0, 'timing': 80.0, 'tone': 85.0},
      );

      expect(rating.score, inInclusiveRange(0, 100));
      expect(rating.pitchHz, greaterThan(0));
    });

    test('determinism: same inputs produce same fields', () {
      final rating1 = RatingResult(
        score: 72.5,
        feedback: 'Good attempt',
        pitchHz: 550.0,
        metrics: {'pitch': 80.0, 'timing': 65.0},
      );

      final rating2 = RatingResult(
        score: 72.5,
        feedback: 'Good attempt',
        pitchHz: 550.0,
        metrics: {'pitch': 80.0, 'timing': 65.0},
      );

      expect(rating1.score, rating2.score);
      expect(rating1.pitchHz, rating2.pitchHz);
      expect(rating1.feedback, rating2.feedback);
    });

    test('feedback is a non-empty string', () {
      final rating = RatingResult(
        score: 50.0,
        feedback: 'Average performance',
        pitchHz: 300.0,
        metrics: {},
      );

      expect(rating.feedback, isNotEmpty);
    });

    test('optional waveforms default to null', () {
      final rating = RatingResult(
        score: 60.0,
        feedback: 'Fair',
        pitchHz: 400.0,
        metrics: {},
      );

      expect(rating.userWaveform, isNull);
      expect(rating.referenceWaveform, isNull);
    });

    test('waveforms are preserved when provided', () {
      final rating = RatingResult(
        score: 75.0,
        feedback: 'Good',
        pitchHz: 500.0,
        metrics: {'pitch': 80.0},
        userWaveform: [0.1, 0.5, 0.9],
        referenceWaveform: [0.2, 0.6, 0.8],
      );

      expect(rating.userWaveform, isNotNull);
      expect(rating.userWaveform!.length, 3);
      expect(rating.referenceWaveform, isNotNull);
      expect(rating.referenceWaveform!.length, 3);
    });

    test('location data is optional', () {
      final withLocation = RatingResult(
        score: 80.0,
        feedback: 'Nice',
        pitchHz: 600.0,
        metrics: {},
        latitude: 45.123,
        longitude: -93.456,
      );

      expect(withLocation.latitude, 45.123);
      expect(withLocation.longitude, -93.456);

      final noLocation = RatingResult(
        score: 80.0,
        feedback: 'Nice',
        pitchHz: 600.0,
        metrics: {},
      );

      expect(noLocation.latitude, isNull);
      expect(noLocation.longitude, isNull);
    });

    test('JSON round-trip preserves all fields', () {
      final original = RatingResult(
        score: 88.0,
        feedback: 'Excellent tone quality',
        pitchHz: 1200.0,
        metrics: {'pitch': 95.0, 'timing': 82.0, 'tone': 88.0},
        userWaveform: [0.1, 0.5, 0.9],
        referenceWaveform: [0.2, 0.6, 0.8],
        latitude: 44.0,
        longitude: -93.0,
      );

      final json = original.toJson();
      final restored = RatingResult.fromJson(json);

      expect(restored.score, original.score);
      expect(restored.feedback, original.feedback);
      expect(restored.pitchHz, original.pitchHz);
      expect(restored.metrics.length, original.metrics.length);
      expect(restored.userWaveform?.length, original.userWaveform?.length);
      expect(restored.latitude, original.latitude);
      expect(restored.longitude, original.longitude);
    });

    test('edge case: perfect score', () {
      final rating = RatingResult(
        score: 100.0,
        feedback: 'Perfect!',
        pitchHz: 1000.0,
        metrics: {'pitch': 100.0, 'timing': 100.0, 'tone': 100.0},
      );

      expect(rating.score, 100.0);
    });

    test('edge case: zero score', () {
      final rating = RatingResult(
        score: 0.0,
        feedback: 'No match detected',
        pitchHz: 0.0,
        metrics: {},
      );

      expect(rating.score, 0.0);
    });

    test('metrics can store arbitrary keys', () {
      final rating = RatingResult(
        score: 70.0,
        feedback: 'Good',
        pitchHz: 500.0,
        metrics: {
          'pitch': 75.0,
          'timing': 70.0,
          'tone': 65.0,
          'rhythm': 80.0,
          'snr': 15.0,
        },
      );

      expect(rating.metrics.length, 5);
      expect(rating.metrics['snr'], 15.0);
    });
  });
}
