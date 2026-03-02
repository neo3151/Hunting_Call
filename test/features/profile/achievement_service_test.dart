import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/features/profile/domain/achievement_service.dart';
import '../../helpers/test_factories.dart';

void main() {
  group('AchievementService', () {
    test('has 30 achievements defined', () {
      expect(AchievementService.achievements.length, 30);
    });

    test('all achievements have unique IDs', () {
      final ids = AchievementService.achievements.map((a) => a.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('all achievements have non-empty name, description, and icon', () {
      for (final a in AchievementService.achievements) {
        expect(a.name.isNotEmpty, true, reason: '${a.id} has empty name');
        expect(a.description.isNotEmpty, true, reason: '${a.id} has empty description');
        expect(a.icon.isNotEmpty, true, reason: '${a.id} has empty icon');
      }
    });

    // ─── MILESTONES ───
    group('Milestones', () {
      test('first_call triggers at 1 recording', () {
        final a = _findById('first_call');
        expect(a.isEarned(makeProfile(totalCalls: 0)), false);
        expect(a.isEarned(makeProfile(totalCalls: 1)), true);
      });

      test('getting_started triggers at 10', () {
        final a = _findById('getting_started');
        expect(a.isEarned(makeProfile(totalCalls: 9)), false);
        expect(a.isEarned(makeProfile(totalCalls: 10)), true);
      });

      test('dedicated_hunter at 25', () {
        final a = _findById('dedicated_hunter');
        expect(a.isEarned(makeProfile(totalCalls: 24)), false);
        expect(a.isEarned(makeProfile(totalCalls: 25)), true);
      });

      test('marathon_hunter at 50', () {
        final a = _findById('marathon_hunter');
        expect(a.isEarned(makeProfile(totalCalls: 49)), false);
        expect(a.isEarned(makeProfile(totalCalls: 50)), true);
      });

      test('centurion at 100', () {
        final a = _findById('centurion');
        expect(a.isEarned(makeProfile(totalCalls: 99)), false);
        expect(a.isEarned(makeProfile(totalCalls: 100)), true);
      });

      test('legend at 250', () {
        final a = _findById('legend');
        expect(a.isEarned(makeProfile(totalCalls: 249)), false);
        expect(a.isEarned(makeProfile(totalCalls: 250)), true);
      });
    });

    // ─── SCORE TIERS ───
    group('Score Tiers', () {
      test('bronze_hunter at 70%+', () {
        final a = _findById('bronze_hunter');
        expect(a.isEarned(makeProfile(history: [makeHistory(score: 69)])), false);
        expect(a.isEarned(makeProfile(history: [makeHistory(score: 70)])), true);
      });

      test('silver_hunter at 80%+', () {
        final a = _findById('silver_hunter');
        expect(a.isEarned(makeProfile(history: [makeHistory(score: 79)])), false);
        expect(a.isEarned(makeProfile(history: [makeHistory(score: 80)])), true);
      });

      test('gold_hunter at 90%+', () {
        final a = _findById('gold_hunter');
        expect(a.isEarned(makeProfile(history: [makeHistory(score: 89)])), false);
        expect(a.isEarned(makeProfile(history: [makeHistory(score: 90)])), true);
      });

      test('master_caller at 95%+', () {
        final a = _findById('master_caller');
        expect(a.isEarned(makeProfile(history: [makeHistory(score: 94)])), false);
        expect(a.isEarned(makeProfile(history: [makeHistory(score: 95)])), true);
      });

      test('perfectionist at 99%+', () {
        final a = _findById('perfectionist');
        expect(a.isEarned(makeProfile(history: [makeHistory(score: 98)])), false);
        expect(a.isEarned(makeProfile(history: [makeHistory(score: 99)])), true);
      });
    });

    // ─── CONSISTENCY ───
    group('Consistency', () {
      test('consistent_80 needs 5 recordings at 80+', () {
        final a = _findById('consistent_80');
        final fourHigh = List.generate(4, (_) => makeHistory(score: 85));
        final fiveHigh = List.generate(5, (_) => makeHistory(score: 85));
        expect(a.isEarned(makeProfile(history: fourHigh)), false);
        expect(a.isEarned(makeProfile(history: fiveHigh)), true);
      });

      test('consistent_90 needs 10 recordings at 90+', () {
        final a = _findById('consistent_90');
        final nineHigh = List.generate(9, (_) => makeHistory(score: 92));
        final tenHigh = List.generate(10, (_) => makeHistory(score: 92));
        expect(a.isEarned(makeProfile(history: nineHigh)), false);
        expect(a.isEarned(makeProfile(history: tenHigh)), true);
      });

      test('average_elite needs 85+ average', () {
        final a = _findById('average_elite');
        expect(a.isEarned(makeProfile(history: [])), false);
        expect(a.isEarned(makeProfile(history: [
          makeHistory(score: 80),
          makeHistory(score: 90),
        ])), true); // avg = 85
        expect(a.isEarned(makeProfile(history: [
          makeHistory(score: 80),
          makeHistory(score: 89),
        ])), false); // avg = 84.5
      });
    });

    // ─── DIVERSITY ───
    group('Diversity', () {
      test('explorer needs 3 species', () {
        final a = _findById('explorer');
        expect(a.isEarned(makeProfile(history: [
          makeHistory(animalId: 'elk_bugle'),
          makeHistory(animalId: 'elk_cow'),
        ])), false); // same species
        expect(a.isEarned(makeProfile(history: [
          makeHistory(animalId: 'elk_bugle'),
          makeHistory(animalId: 'duck_call'),
          makeHistory(animalId: 'turkey_gobble'),
        ])), true);
      });

      test('diverse_picker needs 5 species', () {
        final a = _findById('diverse_picker');
        final history = ['elk_bugle', 'duck_call', 'turkey_gobble', 'crow_call', 'coyote_howl']
            .map((id) => makeHistory(animalId: id)).toList();
        expect(a.isEarned(makeProfile(history: history)), true);
      });

      test('call_collector counts unique call IDs (not species)', () {
        final a = _findById('call_collector');
        final history = List.generate(15, (i) => makeHistory(animalId: 'call_$i'));
        expect(a.isEarned(makeProfile(history: history)), true);
      });
    });

    // ─── DAILY CHALLENGE ───
    group('Daily Challenge', () {
      test('challenger at 1 completed', () {
        final a = _findById('challenger');
        expect(a.isEarned(makeProfile(dailyChallengesCompleted: 0)), false);
        expect(a.isEarned(makeProfile(dailyChallengesCompleted: 1)), true);
      });

      test('streak_3 at 3-day streak', () {
        final a = _findById('streak_3');
        expect(a.isEarned(makeProfile(longestStreak: 2)), false);
        expect(a.isEarned(makeProfile(longestStreak: 3)), true);
      });

      test('streak_7 at 7-day streak', () {
        final a = _findById('streak_7');
        expect(a.isEarned(makeProfile(longestStreak: 6)), false);
        expect(a.isEarned(makeProfile(longestStreak: 7)), true);
      });

      test('streak_30 at 30-day streak', () {
        final a = _findById('streak_30');
        expect(a.isEarned(makeProfile(longestStreak: 29)), false);
        expect(a.isEarned(makeProfile(longestStreak: 30)), true);
      });
    });

    // ─── MASTERY ───
    group('Mastery', () {
      test('specialist needs 3x 85%+ on same call', () {
        final a = _findById('specialist');
        final twoHigh = [
          makeHistory(animalId: 'elk_bugle', score: 90),
          makeHistory(animalId: 'elk_bugle', score: 88),
        ];
        final threeHigh = [
          ...twoHigh,
          makeHistory(animalId: 'elk_bugle', score: 86),
        ];
        expect(a.isEarned(makeProfile(history: twoHigh)), false);
        expect(a.isEarned(makeProfile(history: threeHigh)), true);
      });

      test('master_of_one needs 5x 90%+ on same call', () {
        final a = _findById('master_of_one');
        final history = List.generate(5, (_) =>
            makeHistory(animalId: 'elk_bugle', score: 92));
        expect(a.isEarned(makeProfile(history: history)), true);

        final mixedHistory = List.generate(5, (i) =>
            makeHistory(animalId: 'call_$i', score: 92));
        expect(a.isEarned(makeProfile(history: mixedHistory)), false);
      });
    });

    // ─── HIDDEN / FUN ───
    group('Hidden / Fun', () {
      test('night_owl triggers for midnight-5am recordings', () {
        final a = _findById('night_owl');
        expect(a.isEarned(makeProfile(history: [
          makeHistory(timestamp: DateTime(2026, 3, 1, 3, 0)),
        ])), true);
        expect(a.isEarned(makeProfile(history: [
          makeHistory(timestamp: DateTime(2026, 3, 1, 6, 0)),
        ])), false);
      });

      test('early_bird triggers for 5-6am recordings', () {
        final a = _findById('early_bird');
        expect(a.isEarned(makeProfile(history: [
          makeHistory(timestamp: DateTime(2026, 3, 1, 5, 30)),
        ])), true);
        expect(a.isEarned(makeProfile(history: [
          makeHistory(timestamp: DateTime(2026, 3, 1, 6, 0)),
        ])), false);
      });

      test('comeback_kid needs sub-40 then 85+ on same call', () {
        final a = _findById('comeback_kid');
        expect(a.isEarned(makeProfile(history: [
          makeHistory(animalId: 'elk_bugle', score: 35),
          makeHistory(animalId: 'elk_bugle', score: 90),
        ])), true);
        expect(a.isEarned(makeProfile(history: [
          makeHistory(animalId: 'elk_bugle', score: 35),
          makeHistory(animalId: 'duck_call', score: 90),
        ])), false); // different call
      });

      test('speed_demon needs 5 recordings in one day', () {
        final a = _findById('speed_demon');
        final sameDay = List.generate(5, (i) =>
            makeHistory(timestamp: DateTime(2026, 3, 1, 10 + i)));
        expect(a.isEarned(makeProfile(history: sameDay)), true);

        final spreadDays = List.generate(5, (i) =>
            makeHistory(timestamp: DateTime(2026, 3, i + 1)));
        expect(a.isEarned(makeProfile(history: spreadDays)), false);
      });

      test('grinder needs 10 recordings in one day', () {
        final a = _findById('grinder');
        final tenSameDay = List.generate(10, (i) =>
            makeHistory(timestamp: DateTime(2026, 3, 1, 8 + i)));
        expect(a.isEarned(makeProfile(history: tenSameDay)), true);
      });
    });

    // ─── SERVICE METHODS ───
    group('Service methods', () {
      test('getEarnedAchievements returns only earned ones', () {
        final profile = makeProfile(totalCalls: 5, history: [
          makeHistory(score: 82),
        ]);
        final earned = AchievementService.getEarnedAchievements(profile);
        final ids = earned.map((a) => a.id).toSet();
        expect(ids.contains('first_call'), true);
        expect(ids.contains('bronze_hunter'), true);
        expect(ids.contains('silver_hunter'), true);
        expect(ids.contains('gold_hunter'), false);
      });

      test('getNewAchievementIds excludes already claimed', () {
        final profile = makeProfile(
          totalCalls: 5,
          achievements: ['first_call'],
          history: [makeHistory(score: 82)],
        );
        final newIds = AchievementService.getNewAchievementIds(
          profile,
          profile.achievements,
        );
        expect(newIds.contains('first_call'), false);
        expect(newIds.contains('bronze_hunter'), true);
      });

      test('getNewAchievementIds returns empty when all claimed', () {
        final profile = makeProfile(totalCalls: 1, achievements: ['first_call']);
        final newIds = AchievementService.getNewAchievementIds(
          profile,
          ['first_call'],
        );
        // first_call is already claimed, no other milestones hit
        expect(newIds, isEmpty);
      });
    });
  });
}

Achievement _findById(String id) {
  return AchievementService.achievements.firstWhere((a) => a.id == id);
}
