import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/features/library/domain/use_cases/filter_calls_use_case.dart';
import 'package:outcall/features/library/domain/failures/library_failure.dart';
import 'package:outcall/features/library/data/reference_database.dart';
import 'package:outcall/features/library/domain/reference_call_model.dart';

void main() {
  late FilterCallsUseCase useCase;

  setUp(() {
    useCase = const FilterCallsUseCase();
  });

  tearDown(() {
    ReferenceDatabase.calls = [];
  });

  group('FilterCallsUseCase', () {
    test('returns all calls when category is "All" and search is empty', () {
      // Arrange
      final mockCalls = [
        const ReferenceCall(
          id: 'mallard_feeding',
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
          id: 'elk_bugle',
          animalName: 'Elk',
          callType: 'Bugle',
          category: 'Big Game',
          difficulty: 'Pro',
          idealPitchHz: 800.0,
          idealDurationSec: 3.0,
          audioAssetPath: 'assets/audio/elk.mp3',
          isLocked: false,
        ),
      ];
      ReferenceDatabase.calls = mockCalls;

      // Act
      final result = useCase.execute(category: 'All', searchQuery: '');

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (calls) {
          expect(calls.length, 2);
        },
      );
    });

    test('filters calls by category correctly', () {
      // Arrange
      final mockCalls = [
        const ReferenceCall(
          id: 'mallard_feeding',
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
          id: 'elk_bugle',
          animalName: 'Elk',
          callType: 'Bugle',
          category: 'Big Game',
          difficulty: 'Pro',
          idealPitchHz: 800.0,
          idealDurationSec: 3.0,
          audioAssetPath: 'assets/audio/elk.mp3',
          isLocked: false,
        ),
        const ReferenceCall(
          id: 'goose_honk',
          animalName: 'Canada Goose',
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

      // Act
      final result = useCase.execute(category: 'Waterfowl', searchQuery: '');

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (calls) {
          expect(calls.length, 2);
          expect(calls.every((c) => c.category == 'Waterfowl'), true);
        },
      );
    });

    test('filters calls by search query matching animal name', () {
      // Arrange
      final mockCalls = [
        const ReferenceCall(
          id: 'mallard_feeding',
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
          id: 'elk_bugle',
          animalName: 'Elk',
          callType: 'Bugle',
          category: 'Big Game',
          difficulty: 'Pro',
          idealPitchHz: 800.0,
          idealDurationSec: 3.0,
          audioAssetPath: 'assets/audio/elk.mp3',
          isLocked: false,
        ),
      ];
      ReferenceDatabase.calls = mockCalls;

      // Act
      final result = useCase.execute(category: 'All', searchQuery: 'elk');

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (calls) {
          expect(calls.length, 1);
          expect(calls[0].animalName, 'Elk');
        },
      );
    });

    test('filters calls by search query matching call type', () {
      // Arrange
      final mockCalls = [
        const ReferenceCall(
          id: 'mallard_feeding',
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
          id: 'elk_bugle',
          animalName: 'Elk',
          callType: 'Bugle',
          category: 'Big Game',
          difficulty: 'Pro',
          idealPitchHz: 800.0,
          idealDurationSec: 3.0,
          audioAssetPath: 'assets/audio/elk.mp3',
          isLocked: false,
        ),
      ];
      ReferenceDatabase.calls = mockCalls;

      // Act
      final result = useCase.execute(category: 'All', searchQuery: 'bugle');

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (calls) {
          expect(calls.length, 1);
          expect(calls[0].callType, 'Bugle');
        },
      );
    });

    test('search is case-insensitive', () {
      // Arrange
      final mockCalls = [
        const ReferenceCall(
          id: 'elk_bugle',
          animalName: 'Elk',
          callType: 'Bugle',
          category: 'Big Game',
          difficulty: 'Pro',
          idealPitchHz: 800.0,
          idealDurationSec: 3.0,
          audioAssetPath: 'assets/audio/elk.mp3',
          isLocked: false,
        ),
      ];
      ReferenceDatabase.calls = mockCalls;

      // Act
      final result = useCase.execute(category: 'All', searchQuery: 'ELK');

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (calls) {
          expect(calls.length, 1);
          expect(calls[0].animalName, 'Elk');
        },
      );
    });

    test('combines category and search filter', () {
      // Arrange
      final mockCalls = [
        const ReferenceCall(
          id: 'mallard_feeding',
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
          id: 'elk_bugle',
          animalName: 'Elk',
          callType: 'Bugle',
          category: 'Big Game',
          difficulty: 'Pro',
          idealPitchHz: 800.0,
          idealDurationSec: 3.0,
          audioAssetPath: 'assets/audio/elk.mp3',
          isLocked: false,
        ),
        const ReferenceCall(
          id: 'goose_honk',
          animalName: 'Canada Goose',
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

      // Act
      final result = useCase.execute(category: 'Waterfowl', searchQuery: 'mallard');

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (calls) {
          expect(calls.length, 1);
          expect(calls[0].animalName, 'Mallard');
          expect(calls[0].category, 'Waterfowl');
        },
      );
    });

    test('sorts results alphabetically by animal name', () {
      // Arrange
      final mockCalls = [
        const ReferenceCall(
          id: 'elk_bugle',
          animalName: 'Elk',
          callType: 'Bugle',
          category: 'Big Game',
          difficulty: 'Pro',
          idealPitchHz: 800.0,
          idealDurationSec: 3.0,
          audioAssetPath: 'assets/audio/elk.mp3',
          isLocked: false,
        ),
        const ReferenceCall(
          id: 'mallard_feeding',
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
          id: 'bear_growl',
          animalName: 'Black Bear',
          callType: 'Growl',
          category: 'Big Game',
          difficulty: 'Pro',
          idealPitchHz: 300.0,
          idealDurationSec: 2.5,
          audioAssetPath: 'assets/audio/bear.mp3',
          isLocked: false,
        ),
      ];
      ReferenceDatabase.calls = mockCalls;

      // Act
      final result = useCase.execute(category: 'All', searchQuery: '');

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (calls) {
          expect(calls.length, 3);
          expect(calls[0].animalName, 'Black Bear');
          expect(calls[1].animalName, 'Elk');
          expect(calls[2].animalName, 'Mallard');
        },
      );
    });

    test('returns LibraryNotInitialized when database is empty', () {
      // Arrange
      ReferenceDatabase.calls = [];

      // Act
      final result = useCase.execute(category: 'All', searchQuery: '');

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<LibraryNotInitialized>());
        },
        (calls) => fail('Should not succeed'),
      );
    });
  });
}
