import '../domain/profile_model.dart';

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
    Achievement(
      id: 'first_call',
      name: 'First Blood',
      description: 'Record your very first animal call.',
      icon: '🎯',
      isEarned: (p) => p.totalCalls >= 1,
    ),
    Achievement(
      id: 'silver_hunter',
      name: 'Silver Hunter',
      description: 'Achieve a score of 80 or higher.',
      icon: '🥈',
      isEarned: (p) => p.history.any((h) => h.result.score >= 80),
    ),
    Achievement(
      id: 'gold_hunter',
      name: 'Gold Hunter',
      description: 'Achieve a score of 90 or higher.',
      icon: '🥇',
      isEarned: (p) => p.history.any((h) => h.result.score >= 90),
    ),
    Achievement(
      id: 'master_caller',
      name: 'Master Caller',
      description: 'Achieve a near-perfect score of 95 or higher.',
      icon: '👑',
      isEarned: (p) => p.history.any((h) => h.result.score >= 95),
    ),
    Achievement(
      id: 'marathon_hunter',
      name: 'Marathon Hunter',
      description: 'Record over 50 animal calls.',
      icon: '🏃',
      isEarned: (p) => p.totalCalls >= 50,
    ),
    Achievement(
      id: 'diverse_picker',
      name: 'Diverse Picker',
      description: 'Practice calls for 5 different species.',
      icon: '🦓',
      isEarned: (p) {
        final species = p.history.map((h) => h.animalId.split('_')[0]).toSet();
        return species.length >= 5;
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
