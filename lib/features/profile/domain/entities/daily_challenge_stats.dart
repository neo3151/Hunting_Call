/// Domain entity for daily challenge statistics
/// 
/// Pure value object with no dependencies - used in streak calculation logic
class DailyChallengeStats {
  final int challengesCompleted;
  final DateTime? lastChallengeDate;
  final int currentStreak;
  final int longestStreak;

  const DailyChallengeStats({
    required this.challengesCompleted,
    this.lastChallengeDate,
    required this.currentStreak,
    required this.longestStreak,
  });

  const DailyChallengeStats.initial()
      : challengesCompleted = 0,
        lastChallengeDate = null,
        currentStreak = 0,
        longestStreak = 0;

  DailyChallengeStats copyWith({
    int? challengesCompleted,
    DateTime? lastChallengeDate,
    int? currentStreak,
    int? longestStreak,
  }) {
    return DailyChallengeStats(
      challengesCompleted: challengesCompleted ?? this.challengesCompleted,
      lastChallengeDate: lastChallengeDate ?? this.lastChallengeDate,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
    );
  }
}
