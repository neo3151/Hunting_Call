import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/features/leaderboard/domain/use_cases/submit_score_use_case.dart';
import 'package:outcall/features/leaderboard/domain/leaderboard_entry.dart';
import 'package:outcall/features/leaderboard/domain/failures/leaderboard_failure.dart';

void main() {
  late SubmitScoreUseCase useCase;

  setUp(() {
    useCase = SubmitScoreUseCase();
  });

  group('SubmitScoreUseCase', () {
    test('accepts new score from new user', () {
      // Arrange
      final List<LeaderboardEntry> currentEntries = [];
      final newEntry = LeaderboardEntry(
        userId: 'user1',
        userName: 'Test User',
        score: 85.0,
        timestamp: DateTime.now(),
      );

      // Act
      final result = useCase.execute(currentEntries, newEntry);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (submitResult) {
          expect(submitResult.wasAccepted, true);
          expect(submitResult.updatedEntries.length, 1);
          expect(submitResult.updatedEntries.first.userId, 'user1');
        },
      );
    });

    test('rejects lower score from existing user', () {
      // Arrange
      final currentEntries = [
        LeaderboardEntry(
          userId: 'user1',
          userName: 'Test User',
          score: 90.0,
          timestamp: DateTime.now(),
        ),
      ];
      final newEntry = LeaderboardEntry(
        userId: 'user1',
        userName: 'Test User',
        score: 85.0,
        timestamp: DateTime.now(),
      );

      // Act
      final result = useCase.execute(currentEntries, newEntry);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ExistingScoreBetter>());
          expect(failure.message, contains('already has better score'));
        },
        (_) => fail('Should have failed'),
      );
    });

    test('accepts higher score from existing user and removes old score', () {
      // Arrange
      final currentEntries = [
        LeaderboardEntry(
          userId: 'user1',
          userName: 'Test User',
          score: 80.0,
          timestamp: DateTime.now(),
        ),
        LeaderboardEntry(
          userId: 'user2',
          userName: 'Other User',
          score: 75.0,
          timestamp: DateTime.now(),
        ),
      ];
      final newEntry = LeaderboardEntry(
        userId: 'user1',
        userName: 'Test User',
        score: 95.0,
        timestamp: DateTime.now(),
      );

      // Act
      final result = useCase.execute(currentEntries, newEntry);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (submitResult) {
          expect(submitResult.wasAccepted, true);
          expect(submitResult.updatedEntries.length, 2);
          // Should only have one entry for user1 with the new score
          final user1Entries = submitResult.updatedEntries.where((e) => e.userId == 'user1');
          expect(user1Entries.length, 1);
          expect(user1Entries.first.score, 95.0);
        },
      );
    });

    test('sorts entries in descending order by score', () {
      // Arrange
      final currentEntries = [
        LeaderboardEntry(
          userId: 'user1',
          userName: 'User 1',
          score: 70.0,
          timestamp: DateTime.now(),
        ),
        LeaderboardEntry(
          userId: 'user2',
          userName: 'User 2',
          score: 90.0,
          timestamp: DateTime.now(),
        ),
      ];
      final newEntry = LeaderboardEntry(
        userId: 'user3',
        userName: 'User 3',
        score: 85.0,
        timestamp: DateTime.now(),
      );

      // Act
      final result = useCase.execute(currentEntries, newEntry);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (submitResult) {
          expect(submitResult.updatedEntries[0].score, 90.0);
          expect(submitResult.updatedEntries[1].score, 85.0);
          expect(submitResult.updatedEntries[2].score, 70.0);
        },
      );
    });

    test('keeps only top 20 entries', () {
      // Arrange - Create 20 existing entries
      final currentEntries = List.generate(
        20,
        (i) => LeaderboardEntry(
          userId: 'user$i',
          userName: 'User $i',
          score: 50.0 + i,
          timestamp: DateTime.now(),
        ),
      );

      // Add a high-scoring entry that should make the list
      final newEntry = LeaderboardEntry(
        userId: 'user_new',
        userName: 'New User',
        score: 100.0,
        timestamp: DateTime.now(),
      );

      // Act
      final result = useCase.execute(currentEntries, newEntry);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (submitResult) {
          expect(submitResult.updatedEntries.length, 20); // Still only 20
          expect(submitResult.updatedEntries.first.userId, 'user_new'); // New user at top
          expect(submitResult.updatedEntries.first.score, 100.0);
        },
      );
    });

    test('rejects equal score from existing user', () {
      // Arrange
      final currentEntries = [
        LeaderboardEntry(
          userId: 'user1',
          userName: 'Test User',
          score: 85.0,
          timestamp: DateTime.now(),
        ),
      ];
      final newEntry = LeaderboardEntry(
        userId: 'user1',
        userName: 'Test User',
        score: 85.0,
        timestamp: DateTime.now(),
      );

      // Act
      final result = useCase.execute(currentEntries, newEntry);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ExistingScoreBetter>()),
        (_) => fail('Should have failed'),
      );
    });
  });
}
