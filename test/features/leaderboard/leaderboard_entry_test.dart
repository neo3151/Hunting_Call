import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/features/leaderboard/domain/leaderboard_entry.dart';

void main() {
  group('LeaderboardEntry', () {
    final now = DateTime(2025, 3, 1, 12, 0);

    test('constructs with required fields', () {
      final entry = LeaderboardEntry(
        userId: 'user1',
        userName: 'TestUser',
        score: 85.5,
        timestamp: now,
      );

      expect(entry.userId, 'user1');
      expect(entry.userName, 'TestUser');
      expect(entry.score, 85.5);
      expect(entry.timestamp, now);
      expect(entry.profileImageUrl, isNull);
      expect(entry.isAlphaTester, isFalse);
    });

    test('constructs with optional fields', () {
      final entry = LeaderboardEntry(
        userId: 'user2',
        userName: 'AlphaUser',
        score: 92.0,
        timestamp: now,
        profileImageUrl: 'https://example.com/avatar.png',
        isAlphaTester: true,
      );

      expect(entry.profileImageUrl, 'https://example.com/avatar.png');
      expect(entry.isAlphaTester, isTrue);
    });

    test('toJson produces correct map', () {
      final entry = LeaderboardEntry(
        userId: 'user1',
        userName: 'TestUser',
        score: 85.5,
        timestamp: now,
        profileImageUrl: 'https://img.com/a.png',
        isAlphaTester: true,
      );

      final json = entry.toJson();

      expect(json['userId'], 'user1');
      expect(json['userName'], 'TestUser');
      expect(json['score'], 85.5);
      expect(json['timestamp'], now.millisecondsSinceEpoch);
      expect(json['profileImageUrl'], 'https://img.com/a.png');
      expect(json['isAlphaTester'], true);
    });

    test('fromJson parses correctly', () {
      final json = {
        'userId': 'user3',
        'userName': 'ParsedUser',
        'score': 77.3,
        'timestamp': now.millisecondsSinceEpoch,
        'profileImageUrl': null,
        'isAlphaTester': false,
      };

      final entry = LeaderboardEntry.fromJson(json);

      expect(entry.userId, 'user3');
      expect(entry.userName, 'ParsedUser');
      expect(entry.score, 77.3);
      expect(entry.timestamp, now);
      expect(entry.profileImageUrl, isNull);
      expect(entry.isAlphaTester, isFalse);
    });

    test('JSON roundtrip preserves all fields', () {
      final original = LeaderboardEntry(
        userId: 'roundtrip',
        userName: 'RoundtripUser',
        score: 99.9,
        timestamp: now,
        profileImageUrl: 'https://cdn.example.com/pic.jpg',
        isAlphaTester: true,
      );

      final restored = LeaderboardEntry.fromJson(original.toJson());

      expect(restored.userId, original.userId);
      expect(restored.userName, original.userName);
      expect(restored.score, original.score);
      expect(restored.timestamp, original.timestamp);
      expect(restored.profileImageUrl, original.profileImageUrl);
      expect(restored.isAlphaTester, original.isAlphaTester);
    });

    test('fromJson handles missing isAlphaTester as false', () {
      final json = {
        'userId': 'user4',
        'userName': 'NoBool',
        'score': 50.0,
        'timestamp': now.millisecondsSinceEpoch,
      };

      final entry = LeaderboardEntry.fromJson(json);
      expect(entry.isAlphaTester, isFalse);
    });

    test('fromJson handles integer score as num', () {
      final json = {
        'userId': 'user5',
        'userName': 'IntScore',
        'score': 80,
        'timestamp': now.millisecondsSinceEpoch,
      };

      final entry = LeaderboardEntry.fromJson(json);
      expect(entry.score, 80.0);
    });

    test('edge case: zero score', () {
      final entry = LeaderboardEntry(
        userId: 'zero',
        userName: 'ZeroScore',
        score: 0.0,
        timestamp: now,
      );
      expect(entry.score, 0.0);
    });

    test('edge case: perfect score', () {
      final entry = LeaderboardEntry(
        userId: 'perfect',
        userName: 'PerfectScore',
        score: 100.0,
        timestamp: now,
      );
      expect(entry.score, 100.0);
    });
  });
}
