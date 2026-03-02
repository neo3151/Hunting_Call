import 'package:outcall/features/profile/domain/entities/user_profile.dart';

class Achievement {
  final String id;
  final String name;
  final String description;
  final String icon;
  final bool Function(UserProfile profile) isEarned;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.isEarned,
  });
}

class AchievementService {
  static final List<Achievement> achievements = [
    // ═══════════════════════════════════════════════════════════════════════
    // MILESTONES — recording count progression
    // ═══════════════════════════════════════════════════════════════════════
    Achievement(
      id: 'first_call',
      name: 'First Blood',
      description: 'Record your very first animal call.',
      icon: '🎯',
      isEarned: (p) => p.totalCalls >= 1,
    ),
    Achievement(
      id: 'getting_started',
      name: 'Getting Started',
      description: 'Complete 10 recordings.',
      icon: '🌱',
      isEarned: (p) => p.totalCalls >= 10,
    ),
    Achievement(
      id: 'dedicated_hunter',
      name: 'Dedicated Hunter',
      description: 'Complete 25 recordings.',
      icon: '🔥',
      isEarned: (p) => p.totalCalls >= 25,
    ),
    Achievement(
      id: 'marathon_hunter',
      name: 'Marathon Hunter',
      description: 'Complete 50 recordings.',
      icon: '🏃',
      isEarned: (p) => p.totalCalls >= 50,
    ),
    Achievement(
      id: 'centurion',
      name: 'Centurion',
      description: 'Complete 100 recordings. You\'re obsessed.',
      icon: '💯',
      isEarned: (p) => p.totalCalls >= 100,
    ),
    Achievement(
      id: 'legend',
      name: 'Living Legend',
      description: 'Complete 250 recordings. Touch grass.',
      icon: '🏆',
      isEarned: (p) => p.totalCalls >= 250,
    ),

    // ═══════════════════════════════════════════════════════════════════════
    // SCORE TIERS — hitting skill milestones
    // ═══════════════════════════════════════════════════════════════════════
    Achievement(
      id: 'bronze_hunter',
      name: 'Bronze Hunter',
      description: 'Score 70% or higher on any call.',
      icon: '🥉',
      isEarned: (p) => p.history.any((h) => h.result.score >= 70),
    ),
    Achievement(
      id: 'silver_hunter',
      name: 'Silver Hunter',
      description: 'Score 80% or higher on any call.',
      icon: '🥈',
      isEarned: (p) => p.history.any((h) => h.result.score >= 80),
    ),
    Achievement(
      id: 'gold_hunter',
      name: 'Gold Hunter',
      description: 'Score 90% or higher on any call.',
      icon: '🥇',
      isEarned: (p) => p.history.any((h) => h.result.score >= 90),
    ),
    Achievement(
      id: 'master_caller',
      name: 'Master Caller',
      description: 'Score 95% or higher. Near perfection.',
      icon: '👑',
      isEarned: (p) => p.history.any((h) => h.result.score >= 95),
    ),
    Achievement(
      id: 'perfectionist',
      name: 'The Perfectionist',
      description: 'Score 99% or higher. Are you even human?',
      icon: '💎',
      isEarned: (p) => p.history.any((h) => h.result.score >= 99),
    ),

    // ═══════════════════════════════════════════════════════════════════════
    // CONSISTENCY — proving you're not a one-hit wonder
    // ═══════════════════════════════════════════════════════════════════════
    Achievement(
      id: 'consistent_80',
      name: 'Reliable Shot',
      description: 'Score 80%+ on 5 different recordings.',
      icon: '🎯',
      isEarned: (p) => p.history.where((h) => h.result.score >= 80).length >= 5,
    ),
    Achievement(
      id: 'consistent_90',
      name: 'Sharpshooter',
      description: 'Score 90%+ on 10 different recordings.',
      icon: '🔫',
      isEarned: (p) => p.history.where((h) => h.result.score >= 90).length >= 10,
    ),
    Achievement(
      id: 'average_elite',
      name: 'Elite Average',
      description: 'Maintain an overall average score of 85+.',
      icon: '📈',
      isEarned: (p) {
        if (p.history.isEmpty) return false;
        final avg = p.history.map((h) => h.result.score).reduce((a, b) => a + b) / p.history.length;
        return avg >= 85;
      },
    ),

    // ═══════════════════════════════════════════════════════════════════════
    // DIVERSITY — exploring different species
    // ═══════════════════════════════════════════════════════════════════════
    Achievement(
      id: 'explorer',
      name: 'Explorer',
      description: 'Practice 3 different species.',
      icon: '🧭',
      isEarned: (p) {
        final species = p.history.map((h) => h.animalId.split('_')[0]).toSet();
        return species.length >= 3;
      },
    ),
    Achievement(
      id: 'diverse_picker',
      name: 'Diverse Picker',
      description: 'Practice 5 different species.',
      icon: '🦓',
      isEarned: (p) {
        final species = p.history.map((h) => h.animalId.split('_')[0]).toSet();
        return species.length >= 5;
      },
    ),
    Achievement(
      id: 'wildlife_expert',
      name: 'Wildlife Expert',
      description: 'Practice 10 different species.',
      icon: '🌍',
      isEarned: (p) {
        final species = p.history.map((h) => h.animalId.split('_')[0]).toSet();
        return species.length >= 10;
      },
    ),
    Achievement(
      id: 'call_collector',
      name: 'Call Collector',
      description: 'Practice 15 different unique call types.',
      icon: '📚',
      isEarned: (p) {
        final uniqueCalls = p.history.map((h) => h.animalId).toSet();
        return uniqueCalls.length >= 15;
      },
    ),

    // ═══════════════════════════════════════════════════════════════════════
    // DAILY CHALLENGE — streak and dedication
    // ═══════════════════════════════════════════════════════════════════════
    Achievement(
      id: 'challenger',
      name: 'Challenger',
      description: 'Complete your first daily challenge.',
      icon: '⚡',
      isEarned: (p) => p.dailyChallengesCompleted >= 1,
    ),
    Achievement(
      id: 'streak_3',
      name: 'Three-Peat',
      description: 'Achieve a 3-day challenge streak.',
      icon: '🔥',
      isEarned: (p) => p.longestStreak >= 3,
    ),
    Achievement(
      id: 'streak_7',
      name: 'Weekly Warrior',
      description: 'Achieve a 7-day challenge streak.',
      icon: '⚔️',
      isEarned: (p) => p.longestStreak >= 7,
    ),
    Achievement(
      id: 'streak_14',
      name: 'Two-Week Terror',
      description: 'Maintain a 14-day challenge streak.',
      icon: '🌊',
      isEarned: (p) => p.longestStreak >= 14,
    ),
    Achievement(
      id: 'streak_30',
      name: 'Monthly Monster',
      description: '30-day challenge streak. Absolutely unhinged.',
      icon: '🐉',
      isEarned: (p) => p.longestStreak >= 30,
    ),
    Achievement(
      id: 'challenge_veteran',
      name: 'Challenge Veteran',
      description: 'Complete 25 daily challenges total.',
      icon: '🎖️',
      isEarned: (p) => p.dailyChallengesCompleted >= 25,
    ),

    // ═══════════════════════════════════════════════════════════════════════
    // MASTERY — proving deep skill on specific calls
    // ═══════════════════════════════════════════════════════════════════════
    Achievement(
      id: 'specialist',
      name: 'Specialist',
      description: 'Score 85%+ three times on the same call.',
      icon: '🎓',
      isEarned: (p) {
        final byAnimal = <String, int>{};
        for (final h in p.history) {
          if (h.result.score >= 85) {
            byAnimal[h.animalId] = (byAnimal[h.animalId] ?? 0) + 1;
          }
        }
        return byAnimal.values.any((c) => c >= 3);
      },
    ),
    Achievement(
      id: 'master_of_one',
      name: 'Master of One',
      description: 'Score 90%+ five times on the same call.',
      icon: '🏅',
      isEarned: (p) {
        final byAnimal = <String, int>{};
        for (final h in p.history) {
          if (h.result.score >= 90) {
            byAnimal[h.animalId] = (byAnimal[h.animalId] ?? 0) + 1;
          }
        }
        return byAnimal.values.any((c) => c >= 5);
      },
    ),

    // ═══════════════════════════════════════════════════════════════════════
    // HIDDEN / FUN — surprise achievements
    // ═══════════════════════════════════════════════════════════════════════
    Achievement(
      id: 'night_owl',
      name: 'Night Owl',
      description: 'Practice between midnight and 5 AM. Sleep is overrated.',
      icon: '🦉',
      isEarned: (p) => p.history.any((h) {
        final hour = h.timestamp.hour;
        return hour >= 0 && hour < 5;
      }),
    ),
    Achievement(
      id: 'early_bird',
      name: 'Early Bird',
      description: 'Practice before 6 AM. The deer are still sleeping.',
      icon: '🐦',
      isEarned: (p) => p.history.any((h) {
        final hour = h.timestamp.hour;
        return hour >= 5 && hour < 6;
      }),
    ),
    Achievement(
      id: 'comeback_kid',
      name: 'Comeback Kid',
      description: 'Score below 40%, then score above 85% on the same call.',
      icon: '🦅',
      isEarned: (p) {
        final lowCalls = p.history
            .where((h) => h.result.score < 40)
            .map((h) => h.animalId)
            .toSet();
        return p.history.any(
            (h) => lowCalls.contains(h.animalId) && h.result.score >= 85);
      },
    ),
    Achievement(
      id: 'speed_demon',
      name: 'Speed Demon',
      description: 'Complete 5 recordings in a single day.',
      icon: '⚡',
      isEarned: (p) {
        final byDay = <String, int>{};
        for (final h in p.history) {
          final key = '${h.timestamp.year}-${h.timestamp.month}-${h.timestamp.day}';
          byDay[key] = (byDay[key] ?? 0) + 1;
        }
        return byDay.values.any((c) => c >= 5);
      },
    ),
    Achievement(
      id: 'grinder',
      name: 'The Grinder',
      description: 'Complete 10 recordings in a single day. Respect.',
      icon: '💪',
      isEarned: (p) {
        final byDay = <String, int>{};
        for (final h in p.history) {
          final key = '${h.timestamp.year}-${h.timestamp.month}-${h.timestamp.day}';
          byDay[key] = (byDay[key] ?? 0) + 1;
        }
        return byDay.values.any((c) => c >= 10);
      },
    ),
  ];

  static List<Achievement> getEarnedAchievements(UserProfile profile) {
    return achievements.where((a) => a.isEarned(profile)).toList();
  }
  
  static List<String> getNewAchievementIds(UserProfile profile, List<String> currentIds) {
    final earned = getEarnedAchievements(profile);
    return earned
        .map((a) => a.id)
        .where((id) => !currentIds.contains(id))
        .toList();
  }
}
