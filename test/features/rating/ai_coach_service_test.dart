import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/features/rating/data/ai_coach_service.dart';
import 'package:outcall/features/rating/domain/rating_model.dart';

void main() {
  group('AiCoachService Fallback', () {
    RatingResult makeResult({
      double score = 50.0,
      double pitchHz = 500.0,
      Map<String, double>? metrics,
    }) {
      return RatingResult(
        score: score,
        feedback: '',
        pitchHz: pitchHz,
        metrics: metrics ??
            {
              'score_pitch': 70.0,
              'score_timbre': 65.0,
              'score_rhythm': 80.0,
              'score_duration': 60.0,
              'Pitch (Hz)': pitchHz,
              'Duration (s)': 1.5,
            },
      );
    }

    test('High score (>85) produces congratulatory message', () async {
      final result = makeResult(
        score: 92.0,
        pitchHz: 705.0,
        metrics: {
          'score_pitch': 95.0,
          'score_timbre': 90.0,
          'score_rhythm': 88.0,
          'score_duration': 92.0,
        },
      );

      // Use the fallback by calling with an unreachable URL
      final coaching = await AiCoachService.getCoaching(
        animalName: 'Turkey',
        callType: 'Yelp',
        result: result,
        idealPitchHz: 700.0,
        baseUrl: 'http://localhost:1', // unreachable → triggers fallback
        audioPath: '/nonexistent.wav',
      );

      expect(coaching, contains('92%'));
      expect(coaching, contains('solid work'));
    });

    test('Low pitch accuracy includes pitch adjustment advice', () async {
      final result = makeResult(
        score: 55.0,
        pitchHz: 500.0,
        metrics: {
          'score_pitch': 40.0,
          'score_timbre': 70.0,
          'score_rhythm': 65.0,
          'score_duration': 55.0,
        },
      );

      final coaching = await AiCoachService.getCoaching(
        animalName: 'Elk',
        callType: 'Bugle',
        result: result,
        idealPitchHz: 700.0,
        baseUrl: 'http://localhost:1',
        audioPath: '/nonexistent.wav',
      );

      expect(coaching, contains('Hz too low'));
      expect(coaching, contains('tightening'));
    });

    test('Weak rhythm gets rhythm-specific practice drill', () async {
      final result = makeResult(
        score: 60.0,
        pitchHz: 698.0,
        metrics: {
          'score_pitch': 90.0,
          'score_timbre': 75.0,
          'score_rhythm': 35.0,
          'score_duration': 70.0,
        },
      );

      final coaching = await AiCoachService.getCoaching(
        animalName: 'Turkey',
        callType: 'Cluck',
        result: result,
        idealPitchHz: 700.0,
        baseUrl: 'http://localhost:1',
        audioPath: '/nonexistent.wav',
      );

      expect(coaching, contains('Rhythm'));
      expect(coaching, contains('clap the pattern'));
    });

    test('Identifies strongest metric correctly', () async {
      final result = makeResult(
        score: 70.0,
        pitchHz: 700.0,
        metrics: {
          'score_pitch': 95.0,
          'score_timbre': 50.0,
          'score_rhythm': 60.0,
          'score_duration': 55.0,
        },
      );

      final coaching = await AiCoachService.getCoaching(
        animalName: 'Deer',
        callType: 'Grunt',
        result: result,
        idealPitchHz: 700.0,
        baseUrl: 'http://localhost:1',
        audioPath: '/nonexistent.wav',
      );

      expect(coaching, contains('Pitch'));
      expect(coaching, contains('strength'));
      expect(coaching, contains('95%'));
    });

    test('Pitch on target gets positive feedback', () async {
      final result = makeResult(
        score: 75.0,
        pitchHz: 705.0,
        metrics: {
          'score_pitch': 85.0,
          'score_timbre': 70.0,
          'score_rhythm': 65.0,
          'score_duration': 60.0,
        },
      );

      final coaching = await AiCoachService.getCoaching(
        animalName: 'Turkey',
        callType: 'Yelp',
        result: result,
        idealPitchHz: 700.0,
        baseUrl: 'http://localhost:1',
        audioPath: '/nonexistent.wav',
      );

      expect(coaching, contains('right on target'));
    });
  });
}
