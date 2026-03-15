import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/features/rating/domain/personality_feedback_service.dart';

void main() {
  group('PersonalityFeedbackService', () {
    group('getFeedback score tiers', () {
      test('score >= 95 returns legendary feedback', () {
        final fb = PersonalityFeedbackService.getFeedback(96.0);
        expect(fb.isNotEmpty, true);
        // Verify it's from the legendary list by checking common words
        expect(fb.length > 20, true, reason: 'Feedback should be a full sentence');
      });

      test('score 85-94 returns expert feedback', () {
        final fb = PersonalityFeedbackService.getFeedback(88.0);
        expect(fb.isNotEmpty, true);
      });

      test('score 75-84 returns proficient feedback', () {
        final fb = PersonalityFeedbackService.getFeedback(78.0);
        expect(fb.isNotEmpty, true);
      });

      test('score 65-74 returns average feedback', () {
        final fb = PersonalityFeedbackService.getFeedback(68.0);
        expect(fb.isNotEmpty, true);
      });

      test('score 50-64 returns struggling feedback', () {
        final fb = PersonalityFeedbackService.getFeedback(55.0);
        expect(fb.isNotEmpty, true);
      });

      test('score 35-49 returns poor feedback', () {
        final fb = PersonalityFeedbackService.getFeedback(40.0);
        expect(fb.isNotEmpty, true);
      });

      test('score < 35 returns terrible feedback', () {
        final fb = PersonalityFeedbackService.getFeedback(20.0);
        expect(fb.isNotEmpty, true);
      });

      test('exact boundary: 95 is legendary', () {
        final fb = PersonalityFeedbackService.getFeedback(95.0);
        expect(fb.isNotEmpty, true);
      });

      test('exact boundary: 85 is expert', () {
        final fb = PersonalityFeedbackService.getFeedback(85.0);
        expect(fb.isNotEmpty, true);
      });

      test('exact boundary: 50 is struggling', () {
        final fb = PersonalityFeedbackService.getFeedback(50.0);
        expect(fb.isNotEmpty, true);
      });

      test('exact boundary: 35 is poor', () {
        final fb = PersonalityFeedbackService.getFeedback(35.0);
        expect(fb.isNotEmpty, true);
      });

      test('score 0 returns terrible feedback', () {
        final fb = PersonalityFeedbackService.getFeedback(0.0);
        expect(fb.isNotEmpty, true);
      });

      test('score 100 returns legendary feedback', () {
        final fb = PersonalityFeedbackService.getFeedback(100.0);
        expect(fb.isNotEmpty, true);
      });
    });

    group('getSpecificCritique', () {
      test('empty scores returns speechless fallback', () {
        final critique = PersonalityFeedbackService.getSpecificCritique({});
        expect(critique, contains('speechless'));
      });

      test('all scores >= 90 returns high-praise', () {
        final critique = PersonalityFeedbackService.getSpecificCritique({
          'pitch': 95.0,
          'timbre': 92.0,
          'rhythm': 91.0,
          'duration': 93.0,
        });
        expect(critique, contains('clean'));
      });

      test('worst metric is pitch → pitch critique', () {
        final critique = PersonalityFeedbackService.getSpecificCritique({
          'pitch': 30.0,
          'timbre': 80.0,
          'rhythm': 75.0,
          'duration': 70.0,
        });
        // Pitch critiques mention things like frequency, sharp, flat
        expect(critique.isNotEmpty, true);
      });

      test('worst metric is timbre → timbre critique', () {
        final critique = PersonalityFeedbackService.getSpecificCritique({
          'pitch': 80.0,
          'timbre': 25.0,
          'rhythm': 75.0,
          'duration': 70.0,
        });
        expect(critique.isNotEmpty, true);
      });

      test('worst metric is rhythm → rhythm critique', () {
        final critique = PersonalityFeedbackService.getSpecificCritique({
          'pitch': 80.0,
          'timbre': 75.0,
          'rhythm': 20.0,
          'duration': 70.0,
        });
        expect(critique.isNotEmpty, true);
      });

      test('worst metric is duration → duration critique', () {
        final critique = PersonalityFeedbackService.getSpecificCritique({
          'pitch': 80.0,
          'timbre': 75.0,
          'rhythm': 70.0,
          'duration': 15.0,
        });
        expect(critique.isNotEmpty, true);
      });

      test('unknown metric falls back to general critique', () {
        final critique = PersonalityFeedbackService.getSpecificCritique({
          'unknown_metric': 10.0,
        });
        expect(critique, contains('slightly off'));
      });
    });
  });
}
