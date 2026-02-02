import 'package:json_annotation/json_annotation.dart';
import '../../rating/domain/rating_model.dart';

part 'profile_model.g.dart';

@JsonSerializable()
class UserProfile {
  final String id;
  final String name;
  final DateTime joinedDate;
  final int totalCalls;
  final double averageScore;
  final List<HistoryItem> history;

  UserProfile({
    required this.id,
    required this.name,
    required this.joinedDate,
    this.totalCalls = 0,
    this.averageScore = 0.0,
    this.history = const [],
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
  }) {
    return UserProfile(
      id: id,
      name: name,
      joinedDate: joinedDate,
      totalCalls: totalCalls ?? this.totalCalls,
      averageScore: averageScore ?? this.averageScore,
      history: history ?? this.history,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);
}

@JsonSerializable()
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
