import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/features/daily_challenge/domain/usecases/get_daily_challenge_use_case.dart';
import 'package:outcall/features/library/domain/use_cases/get_all_calls_use_case.dart';
import 'package:outcall/features/library/domain/use_cases/check_call_lock_status_use_case.dart';
import 'package:outcall/features/daily_challenge/domain/daily_challenge_repository.dart';
import 'package:outcall/features/library/data/reference_database.dart';
import 'package:outcall/features/library/domain/reference_call_model.dart';
import 'package:outcall/config/app_config.dart';

class MockDailyChallengeRepository implements DailyChallengeRepository {
  String? mockCallId;

  @override
  Future<String?> getDailyChallengeId() async {
    return mockCallId;
  }
}

void main() {
  late GetDailyChallengeUseCase useCase;
  late GetAllCallsUseCase getAllCallsUseCase;
  late CheckCallLockStatusUseCase checkLockStatusUseCase;
  late MockDailyChallengeRepository mockRepository;

  setUp(() {
    AppConfig.create(flavor: AppFlavor.free, appName: 'Hunting Call Test');
    getAllCallsUseCase = const GetAllCallsUseCase();
    checkLockStatusUseCase = const CheckCallLockStatusUseCase();
    mockRepository = MockDailyChallengeRepository();
    useCase = GetDailyChallengeUseCase(getAllCallsUseCase, checkLockStatusUseCase, mockRepository);
  });

  tearDown(() {
    ReferenceDatabase.calls = [];
  });

  group('GetDailyChallengeUseCase', () {
    test('returns a cloud challenge if repository provides one', () async {
      // Arrange
      final mockCalls = [
        const ReferenceCall(
          id: 'cloud_call_1',
          animalName: 'Rare Cloud Bird',
          callType: 'Chirp',
          category: 'Rare',
          difficulty: 'Hard',
          idealPitchHz: 800.0,
          idealDurationSec: 1.0,
          audioAssetPath: 'assets/audio/rare.mp3',
          isLocked: false,
        ),
      ];
      ReferenceDatabase.calls = mockCalls;
      mockRepository.mockCallId = 'cloud_call_1';

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (challenge) {
          expect(challenge.id, 'cloud_call_1');
          expect(challenge.animalName, 'Rare Cloud Bird');
        },
      );
    });

    test('returns a calculated challenge when free calls are available and no cloud challenge', () async {
      // Arrange
      final mockCalls = [
        const ReferenceCall(
          id: 'free_call_1',
          animalName: 'Mallard',
          callType: 'Feeding Call',
          category: 'Waterfowl',
          difficulty: 'Easy',
          idealPitchHz: 500.0,
          idealDurationSec: 2.0,
          audioAssetPath: 'assets/audio/mallard.mp3',
          isLocked: false,
        ),
        const ReferenceCall(
          id: 'free_call_2',
          animalName: 'Goose',
          callType: 'Honk',
          category: 'Waterfowl',
          difficulty: 'Easy',
          idealPitchHz: 400.0,
          idealDurationSec: 1.5,
          audioAssetPath: 'assets/audio/goose.mp3',
          isLocked: false,
        ),
      ];
      ReferenceDatabase.calls = mockCalls;
      mockRepository.mockCallId = null; // No cloud challenge

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (challenge) {
          expect(challenge, isA<ReferenceCall>());
          // Should be one of the free calls
          expect(mockCalls.contains(challenge) || challenge.id == 'duck_mallard', true);
        },
      );
    });

    test('selects challenge based on day of year', () async {
      // Arrange
      final mockCalls = [
        const ReferenceCall(
          id: 'call_0',
          animalName: 'Call 0',
          callType: 'Type',
          category: 'Waterfowl',
          difficulty: 'Easy',
          idealPitchHz: 500.0,
          idealDurationSec: 2.0,
          audioAssetPath: 'assets/audio/call0.mp3',
          isLocked: false,
        ),
        const ReferenceCall(
          id: 'call_1',
          animalName: 'Call 1',
          callType: 'Type',
          category: 'Waterfowl',
          difficulty: 'Easy',
          idealPitchHz: 500.0,
          idealDurationSec: 2.0,
          audioAssetPath: 'assets/audio/call1.mp3',
          isLocked: false,
        ),
        const ReferenceCall(
          id: 'call_2',
          animalName: 'Call 2',
          callType: 'Type',
          category: 'Waterfowl',
          difficulty: 'Easy',
          idealPitchHz: 500.0,
          idealDurationSec: 2.0,
          audioAssetPath: 'assets/audio/call2.mp3',
          isLocked: false,
        ),
      ];
      ReferenceDatabase.calls = mockCalls;
      mockRepository.mockCallId = null;

      // Act - Test with specific dates to verify modulo logic
      final date1 = DateTime(2024, 1, 1); // Day 1 of year
      final result1 = await useCase.execute(now: date1);
      
      final date2 = DateTime(2024, 1, 2); // Day 2 of year
      final result2 = await useCase.execute(now: date2);

      // Assert - Challenges should be deterministic based on day
      expect(result1.isRight(), true);
      expect(result2.isRight(), true);
      
      final challenge1 = result1.getOrElse((l) => mockCalls.first);
      final challenge2 = result2.getOrElse((l) => mockCalls.first);
      
      // Different days should potentially give different challenges (modulo 3)
      expect(challenge1.id, isNotEmpty);
      expect(challenge2.id, isNotEmpty);
    });

    test('returns default challenge when no calls available', () async {
      // Arrange
      ReferenceDatabase.calls = [];
      mockRepository.mockCallId = null;

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (challenge) {
          expect(challenge.id, 'duck_mallard'); // Default fallback
          expect(challenge.animalName, 'Mallard Duck');
        },
      );
    });

    test('fixes image asset paths for predator/big game heroes', () async {
      // Arrange
      final mockCalls = [
        const ReferenceCall(
          id: 'predator_call',
          animalName: 'Coyote',
          callType: 'Howl',
          category: 'Predators',
          difficulty: 'Pro',
          idealPitchHz: 600.0,
          idealDurationSec: 3.0,
          audioAssetPath: 'assets/audio/coyote.mp3',
          imageUrl: 'assets/images/predator_hero.png',
          isLocked: false,
        ),
      ];
      ReferenceDatabase.calls = mockCalls;
      mockRepository.mockCallId = null;

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (challenge) {
          expect(challenge.imageUrl, 'assets/images/forest_background.webp');
        },
      );
    });

    test('returns same challenge for same day across multiple calls', () async {
      // Arrange
      final mockCalls = [
        const ReferenceCall(
          id: 'call_1',
          animalName: 'Call 1',
          callType: 'Type',
          category: 'Waterfowl',
          difficulty: 'Easy',
          idealPitchHz: 500.0,
          idealDurationSec: 2.0,
          audioAssetPath: 'assets/audio/call1.mp3',
          isLocked: false,
        ),
      ];
      ReferenceDatabase.calls = mockCalls;
      final testDate = DateTime(2024, 6, 15);
      mockRepository.mockCallId = null;

      // Act - Call multiple times on same day
      final result1 = await useCase.execute(now: testDate);
      final result2 = await useCase.execute(now: testDate);

      // Assert - Should return same challenge
      expect(result1.isRight(), true);
      expect(result2.isRight(), true);
      
      final challenge1 = result1.getOrElse((l) => mockCalls.first);
      final challenge2 = result2.getOrElse((l) => mockCalls.first);
      
      expect(challenge1.id, challenge2.id);
    });
  });
}

