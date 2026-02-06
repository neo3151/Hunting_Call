// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      joinedDate: DateTime.parse(json['joinedDate'] as String),
      totalCalls: (json['totalCalls'] as num?)?.toInt() ?? 0,
      averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0.0,
      history: (json['history'] as List<dynamic>?)
              ?.map((e) => HistoryItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      achievements: (json['achievements'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      dailyChallengesCompleted:
          (json['dailyChallengesCompleted'] as num?)?.toInt() ?? 0,
      lastDailyChallengeDate: json['lastDailyChallengeDate'] == null
          ? null
          : DateTime.parse(json['lastDailyChallengeDate'] as String),
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$UserProfileToJson(UserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'joinedDate': instance.joinedDate.toIso8601String(),
      'totalCalls': instance.totalCalls,
      'averageScore': instance.averageScore,
      'history': instance.history.map((e) => e.toJson()).toList(),
      'achievements': instance.achievements,
      'dailyChallengesCompleted': instance.dailyChallengesCompleted,
      'lastDailyChallengeDate':
          instance.lastDailyChallengeDate?.toIso8601String(),
      'currentStreak': instance.currentStreak,
      'longestStreak': instance.longestStreak,
    };

HistoryItem _$HistoryItemFromJson(Map<String, dynamic> json) => HistoryItem(
      result: RatingResult.fromJson(json['result'] as Map<String, dynamic>),
      timestamp: DateTime.parse(json['timestamp'] as String),
      animalId: json['animalId'] as String,
    );

Map<String, dynamic> _$HistoryItemToJson(HistoryItem instance) =>
    <String, dynamic>{
      'result': instance.result.toJson(),
      'timestamp': instance.timestamp.toIso8601String(),
      'animalId': instance.animalId,
    };
