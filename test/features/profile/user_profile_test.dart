import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/features/profile/domain/entities/user_profile.dart';
import 'package:outcall/features/rating/domain/rating_model.dart';
import '../../helpers/test_factories.dart';

void main() {
  group('UserProfile', () {
    test('default constructor uses correct defaults', () {
      final profile = UserProfile(
        id: 'test',
        name: 'Test',
        joinedDate: DateTime(2026, 1, 1),
      );
      expect(profile.totalCalls, 0);
      expect(profile.averageScore, 0.0);
      expect(profile.history, isEmpty);
      expect(profile.achievements, isEmpty);
      expect(profile.dailyChallengesCompleted, 0);
      expect(profile.currentStreak, 0);
      expect(profile.longestStreak, 0);
      expect(profile.isPremium, false);
      expect(profile.isAlphaTester, false);
    });

    test('guest() creates valid guest profile', () {
      final guest = UserProfile.guest();
      expect(guest.id, 'guest');
      expect(guest.name, 'Guest Hunter');
      expect(guest.isPremium, false);
    });

    test('copyWith preserves unmodified fields', () {
      final original = makeProfile(
        totalCalls: 10,
        currentStreak: 5,
        longestStreak: 8,
      );
      final updated = original.copyWith(totalCalls: 11);
      expect(updated.totalCalls, 11);
      expect(updated.currentStreak, 5); // preserved
      expect(updated.longestStreak, 8); // preserved
      expect(updated.id, original.id); // immutable
    });

    test('copyWith can update all mutable fields', () {
      final original = makeProfile();
      final updated = original.copyWith(
        name: 'Updated',
        email: 'test@test.com',
        nickname: 'Pro Hunter',
        totalCalls: 50,
        averageScore: 85.0,
        currentStreak: 7,
        longestStreak: 7,
        dailyChallengesCompleted: 20,
        isPremium: true,
        isAlphaTester: true,
      );
      expect(updated.name, 'Updated');
      expect(updated.email, 'test@test.com');
      expect(updated.nickname, 'Pro Hunter');
      expect(updated.totalCalls, 50);
      expect(updated.averageScore, 85.0);
      expect(updated.isPremium, true);
      expect(updated.isAlphaTester, true);
    });

    test('history list is immutable reference', () {
      final history = [makeHistory(score: 80)];
      final profile = makeProfile(history: history);
      expect(profile.history.length, 1);
    });

    test('achievements list tracks IDs', () {
      final profile = makeProfile(achievements: ['first_call', 'silver_hunter']);
      expect(profile.achievements.length, 2);
      expect(profile.achievements.contains('first_call'), true);
    });
  });

  group('HistoryItem', () {
    test('constructs with required fields', () {
      final item = HistoryItem(
        result: makeResult(score: 80),
        timestamp: DateTime(2026, 3, 1),
        animalId: 'elk_bugle',
      );
      expect(item.result.score, 80);
      expect(item.animalId, 'elk_bugle');
      expect(item.timestamp.year, 2026);
    });

    test('JSON serialization roundtrip', () {
      final item = HistoryItem(
        result: RatingResult(
          score: 88.5,
          feedback: 'Great!',
          pitchHz: 440.0,
          metrics: {'score_pitch': 90.0},
        ),
        timestamp: DateTime(2026, 3, 1, 14, 30),
        animalId: 'mallard_drake',
      );
      final json = item.toJson();
      final restored = HistoryItem.fromJson(json);

      expect(restored.result.score, 88.5);
      expect(restored.animalId, 'mallard_drake');
      expect(restored.timestamp.hour, 14);
    });
  });

  group('UserProfile JSON', () {
    test('serialization roundtrip with full data', () {
      final profile = UserProfile(
        id: 'user123',
        name: 'Test Hunter',
        email: 'test@example.com',
        joinedDate: DateTime(2026, 1, 1),
        totalCalls: 25,
        averageScore: 78.5,
        history: [makeHistory(score: 80, animalId: 'elk_bugle')],
        achievements: ['first_call', 'bronze_hunter'],
        dailyChallengesCompleted: 10,
        currentStreak: 3,
        longestStreak: 7,
        isPremium: true,
      );

      final json = profile.toJson();
      final restored = UserProfile.fromJson(json);

      expect(restored.id, 'user123');
      expect(restored.name, 'Test Hunter');
      expect(restored.email, 'test@example.com');
      expect(restored.totalCalls, 25);
      expect(restored.averageScore, 78.5);
      expect(restored.history.length, 1);
      expect(restored.achievements.length, 2);
      expect(restored.isPremium, true);
      expect(restored.currentStreak, 3);
      expect(restored.longestStreak, 7);
    });
  });
}
