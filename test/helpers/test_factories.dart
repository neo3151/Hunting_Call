import 'package:outcall/features/profile/domain/entities/user_profile.dart';
import 'package:outcall/features/rating/domain/rating_model.dart';

/// Test helpers for creating domain objects quickly.

/// Create a [RatingResult] with sensible defaults.
RatingResult makeResult({
  double score = 75.0,
  String feedback = 'Test feedback',
  double pitchHz = 440.0,
  Map<String, double>? metrics,
}) {
  return RatingResult(
    score: score,
    feedback: feedback,
    pitchHz: pitchHz,
    metrics: metrics ?? {
      'score_pitch': score,
      'score_timbre': score,
      'score_rhythm': score,
      'score_duration': score,
    },
  );
}

/// Create a [HistoryItem] with sensible defaults.
HistoryItem makeHistory({
  String animalId = 'elk_bugle',
  double score = 75.0,
  DateTime? timestamp,
}) {
  return HistoryItem(
    result: makeResult(score: score),
    timestamp: timestamp ?? DateTime(2026, 3, 1, 12, 0),
    animalId: animalId,
  );
}

/// Create a [UserProfile] with sensible defaults.
UserProfile makeProfile({
  String id = 'test_user',
  String name = 'Test Hunter',
  int totalCalls = 0,
  double averageScore = 0.0,
  List<HistoryItem>? history,
  List<String>? achievements,
  int dailyChallengesCompleted = 0,
  int currentStreak = 0,
  int longestStreak = 0,
  DateTime? lastDailyChallengeDate,
}) {
  return UserProfile(
    id: id,
    name: name,
    joinedDate: DateTime(2026, 1, 1),
    totalCalls: totalCalls,
    averageScore: averageScore,
    history: history ?? [],
    achievements: achievements ?? [],
    dailyChallengesCompleted: dailyChallengesCompleted,
    currentStreak: currentStreak,
    longestStreak: longestStreak,
    lastDailyChallengeDate: lastDailyChallengeDate,
  );
}
