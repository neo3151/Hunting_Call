import 'package:json_annotation/json_annotation.dart';
import 'package:hunting_calls_perfection/features/rating/domain/rating_model.dart';

part 'user_profile.g.dart';

@JsonSerializable(explicitToJson: true)
class UserProfile {
  final String id;
  final String name;
  final String? email; // For matching Google accounts across sign-ins
  final String? nickname;
  final String? avatarUrl;
  final DateTime joinedDate;
  final int totalCalls;
  final double averageScore;
  final List<HistoryItem> history;
  final List<String> achievements;
  final int dailyChallengesCompleted;
  final DateTime? lastDailyChallengeDate;
  final int currentStreak;
  final int longestStreak;
  final DateTime? birthday;
  final bool isPremium; // Entitlement: Has user purchased the full app?
  final bool isAlphaTester;

  UserProfile({
    required this.id,
    required this.name,
    this.email,
    this.nickname,
    this.avatarUrl,
    required this.joinedDate,
    this.totalCalls = 0,
    this.averageScore = 0.0,
    this.history = const [],
    this.achievements = const [],
    this.dailyChallengesCompleted = 0,
    this.lastDailyChallengeDate,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.birthday,
    this.isPremium = false,
    this.isAlphaTester = false,
  });

  factory UserProfile.guest() {
    return UserProfile(
      id: 'guest',
      name: 'Guest Handler',
      joinedDate: DateTime.now(),
      isPremium: false,
      isAlphaTester: false,
    );
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? nickname,
    String? avatarUrl,
    int? totalCalls,
    double? averageScore,
    List<HistoryItem>? history,
    List<String>? achievements,
    int? dailyChallengesCompleted,
    DateTime? lastDailyChallengeDate,
    int? currentStreak,
    int? longestStreak,
    DateTime? birthday,
    bool? isPremium,
    bool? isAlphaTester,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      joinedDate: joinedDate,
      totalCalls: totalCalls ?? this.totalCalls,
      averageScore: averageScore ?? this.averageScore,
      history: history ?? this.history,
      achievements: achievements ?? this.achievements,
      dailyChallengesCompleted: dailyChallengesCompleted ?? this.dailyChallengesCompleted,
      lastDailyChallengeDate: lastDailyChallengeDate ?? this.lastDailyChallengeDate,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      birthday: birthday ?? this.birthday,
      isPremium: isPremium ?? this.isPremium,
      isAlphaTester: isAlphaTester ?? this.isAlphaTester,
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
