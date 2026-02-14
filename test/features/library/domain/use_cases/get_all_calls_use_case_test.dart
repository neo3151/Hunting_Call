import 'package:flutter_test/flutter_test.dart';
import 'package:hunting_calls_perfection/features/library/domain/use_cases/get_all_calls_use_case.dart';
import 'package:hunting_calls_perfection/features/library/domain/failures/library_failure.dart';
import 'package:hunting_calls_perfection/features/library/data/reference_database.dart';
import 'package:hunting_calls_perfection/features/library/domain/reference_call_model.dart';

void main() {
  late GetAllCallsUseCase useCase;

  setUp(() {
    useCase = const GetAllCallsUseCase();
  });

  tearDown(() {
    // Reset the database after each test
    ReferenceDatabase.calls = [];
  });

  group('GetAllCallsUseCase', () {
    test('returns success with calls when library is initialized', () {
      // Arrange
      final mockCalls = [
        const ReferenceCall(
          id: 'call1',
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
          id: 'call2',
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
      final result = useCase.execute();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (calls) {
          expect(calls.length, 2);
          expect(calls[0].animalName, 'Mallard');
          expect(calls[1].animalName, 'Elk');
        },
      );
    });

    test('returns LibraryNotInitialized when calls list is empty', () {
      // Arrange
      ReferenceDatabase.calls = [];

      // Act
      final result = useCase.execute();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<LibraryNotInitialized>());
          expect(failure.message, contains('not initialized'));
        },
        (calls) => fail('Should not succeed'),
      );
    });
  });
}
