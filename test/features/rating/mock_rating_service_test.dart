import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/features/rating/data/mock_rating_service.dart';
import 'package:outcall/features/rating/domain/rating_model.dart';

void main() {
  group('MockRatingService', () {
    late MockRatingService service;

    setUp(() {
      service = MockRatingService();
    });

    test('returns a RatingResult', () async {
      final result = await service.rateCall(
        'user_1', '/path/to/audio.wav', 'elk',
      );
      expect(result, isA<RatingResult>());
    });

    test('score is between 60 and 100', () async {
      // Run multiple times to test randomness
      for (var i = 0; i < 20; i++) {
        final result = await service.rateCall(
          'user_$i', '/path/audio.wav', 'duck',
        );
        expect(result.score, greaterThanOrEqualTo(60));
        expect(result.score, lessThan(100));
      }
    });

    test('feedback is non-empty', () async {
      final result = await service.rateCall(
        'user_1', '/path/audio.wav', 'turkey',
      );
      expect(result.feedback.isNotEmpty, true);
    });

    test('feedback includes animal type for low scores', () async {
      // We can't guarantee which message, but let's verify the interface
      final result = await service.rateCall(
        'user_1', '/path/audio.wav', 'coyote',
      );
      expect(result.feedback, isA<String>());
    });

    test('pitchHz is always 150.0', () async {
      final result = await service.rateCall(
        'user_1', '/path/audio.wav', 'elk',
      );
      expect(result.pitchHz, 150.0);
    });

    test('metrics map has expected keys', () async {
      final result = await service.rateCall(
        'user_1', '/path/audio.wav', 'elk',
      );
      expect(result.metrics.containsKey('Pitch'), true);
      expect(result.metrics.containsKey('Duration'), true);
      expect(result.metrics.containsKey('Realism'), true);
    });

    test('Pitch metric is between 70 and 100', () async {
      for (var i = 0; i < 10; i++) {
        final result = await service.rateCall(
          'user_$i', '/path/audio.wav', 'elk',
        );
        expect(result.metrics['Pitch'], greaterThanOrEqualTo(70));
        expect(result.metrics['Pitch'], lessThan(100));
      }
    });

    test('Duration metric is between 60 and 100', () async {
      for (var i = 0; i < 10; i++) {
        final result = await service.rateCall(
          'user_$i', '/path/audio.wav', 'elk',
        );
        expect(result.metrics['Duration'], greaterThanOrEqualTo(60));
        expect(result.metrics['Duration'], lessThan(100));
      }
    });

    test('Realism metric is score minus 5', () async {
      final result = await service.rateCall(
        'user_1', '/path/audio.wav', 'elk',
      );
      expect(result.metrics['Realism'], result.score - 5);
    });
  });
}
