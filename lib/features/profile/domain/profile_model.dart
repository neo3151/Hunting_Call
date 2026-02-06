import 'package:json_annotation/json_annotation.dart';
import '../../rating/domain/rating_model.dart';

part 'profile_model.g.dart';

@JsonSerializable(explicitToJson: true)
class UserProfile {
  final String id;
  final String name;
  final DateTime joinedDate;
  final int totalCalls;
  final double averageScore;
  final List<HistoryItem> history;
  final List<String> achievements;
  final int dailyChallengesCompleted;
  final DateTime? lastDailyChallengeDate;
  final int currentStreak;
  final int longestStreak;

  UserProfile({
    required this.id,
    required this.name,
    required this.joinedDate,
    this.totalCalls = 0,
    this.averageScore = 0.0,
    this.history = const [],
    this.achievements = const [],
    this.dailyChallengesCompleted = 0,
    this.lastDailyChallengeDate,
    this.currentStreak = 0,
    this.longestStreak = 0,
  });

  factory UserProfile.guest() {
    return UserProfile(
      id: 'guest',
      name: 'Guest Handler',
      joinedDate: DateTime.now(),
    );
  }

  UserProfile copyWith({
    int? totalCalls,
    double? averageScore,
    List<HistoryItem>? history,
    List<String>? achievements,
    int? dailyChallengesCompleted,
    DateTime? lastDailyChallengeDate,
    int? currentStreak,
    int? longestStreak,
  }) {
    return UserProfile(
      id: id,
      name: name,
      joinedDate: joinedDate,
      totalCalls: totalCalls ?? this.totalCalls,
      averageScore: averageScore ?? this.averageScore,
      history: history ?? this.history,
      achievements: achievements ?? this.achievements,
      dailyChallengesCompleted: dailyChallengesCompleted ?? this.dailyChallengesCompleted,
      lastDailyChallengeDate: lastDailyChallengeDate ?? this.lastDailyChallengeDate,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);
}

@JsonSerializable(explicitToJson: true)
class HistoryItem {
  final RatingResult result;
  final DateTime timestamp;
  final String animalId;

  HistoryItem({
    required this.result,
    required this.timestamp,
    required this.animalId,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) => _$HistoryItemFromJson(json);
  Map<String, dynamic> toJson() => _$HistoryItemToJson(this);
}
