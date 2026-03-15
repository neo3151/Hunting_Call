import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/features/rating/data/ai_coach_service.dart';
import 'package:outcall/features/rating/domain/rating_model.dart';

/// Tests for the AI Coach service, focusing on the offline fallback path
/// and the rule-based coaching logic.
void main() {
  RatingResult makeResult({
    double score = 60.0,
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
            'score_rhythm': 45.0,
            'score_duration': 60.0,
          },
    );
  }

  group('AiCoachService - Fallback Coaching', () {
    test('low score (<50) produces encouraging message', () async {
      final result = makeResult(
        score: 35.0,
        pitchHz: 300.0,
        metrics: {
          'score_pitch': 30.0,
          'score_timbre': 40.0,
          'score_rhythm': 35.0,
          'score_duration': 30.0,
        },
      );

      final coaching = await AiCoachService.getCoaching(
        animalName: 'Turkey',
        callType: 'Yelp',
        result: result,
        idealPitchHz: 700.0,
        baseUrl: 'http://localhost:1', // unreachable → triggers fallback
        audioPath: '/nonexistent.wav',
      );

      expect(coaching, contains('35%'));
      expect(coaching, contains('Turkey'));
      expect(coaching, contains("Let's work on it"));
    });

    test('medium score (50-69) gives room to grow message', () async {
      final result = makeResult(
        score: 58.0,
        pitchHz: 500.0,
      );

      final coaching = await AiCoachService.getCoaching(
        animalName: 'Elk',
        callType: 'Bugle',
        result: result,
        idealPitchHz: 700.0,
        baseUrl: 'http://localhost:1',
        audioPath: '/nonexistent.wav',
      );

      expect(coaching, contains('58%'));
      expect(coaching, contains('room to grow'));
    });

    test('decent score (70-84) gets decent attempt message', () async {
      final result = makeResult(score: 75.0, pitchHz: 695.0);

      final coaching = await AiCoachService.getCoaching(
        animalName: 'Deer',
        callType: 'Grunt',
        result: result,
        idealPitchHz: 700.0,
        baseUrl: 'http://localhost:1',
        audioPath: '/nonexistent.wav',
      );

      expect(coaching, contains('Decent attempt'));
    });

    test('pitch too high suggests relaxing lips', () async {
      final result = makeResult(
        score: 60.0,
        pitchHz: 800.0,
        metrics: {
          'score_pitch': 50.0,
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

      expect(coaching, contains('too high'));
      expect(coaching, contains('relaxing'));
    });

    test('weak duration metric gets breath control advice', () async {
      final result = makeResult(
        score: 65.0,
        pitchHz: 698.0,
        metrics: {
          'score_pitch': 80.0,
          'score_timbre': 75.0,
          'score_rhythm': 70.0,
          'score_duration': 35.0,
        },
      );

      final coaching = await AiCoachService.getCoaching(
        animalName: 'Turkey',
        callType: 'Gobble',
        result: result,
        idealPitchHz: 700.0,
        baseUrl: 'http://localhost:1',
        audioPath: '/nonexistent.wav',
      );

      expect(coaching, contains('Duration'));
      expect(coaching, contains('breath'));
    });

    test('weak tone metric gets air pressure advice', () async {
      final result = makeResult(
        score: 65.0,
        pitchHz: 698.0,
        metrics: {
          'score_pitch': 80.0,
          'score_timbre': 30.0,
          'score_rhythm': 70.0,
          'score_duration': 65.0,
        },
      );

      final coaching = await AiCoachService.getCoaching(
        animalName: 'Duck',
        callType: 'Quack',
        result: result,
        idealPitchHz: 700.0,
        baseUrl: 'http://localhost:1',
        audioPath: '/nonexistent.wav',
      );

      expect(coaching, contains('Tone'));
      expect(coaching, contains('air'));
    });

    test('all metrics above 70 produces no drill section', () async {
      final result = makeResult(
        score: 88.0,
        pitchHz: 700.0,
        metrics: {
          'score_pitch': 90.0,
          'score_timbre': 85.0,
          'score_rhythm': 88.0,
          'score_duration': 82.0,
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

      // Should mention the strongest area
      expect(coaching, contains('strength'));
    });
  });
}
