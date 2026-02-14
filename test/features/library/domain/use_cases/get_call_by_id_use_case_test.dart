import 'package:flutter_test/flutter_test.dart';
import 'package:hunting_calls_perfection/features/library/domain/use_cases/get_call_by_id_use_case.dart';
import 'package:hunting_calls_perfection/features/library/domain/failures/library_failure.dart';
import 'package:hunting_calls_perfection/features/library/data/reference_database.dart';
import 'package:hunting_calls_perfection/features/library/domain/reference_call_model.dart';

void main() {
  late GetCallByIdUseCase useCase;

  setUp(() {
    useCase = const GetCallByIdUseCase();
  });

  tearDown(() {
    ReferenceDatabase.calls = [];
  });

  group('GetCallByIdUseCase', () {
    test('returns call when it exists', () {
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
      final result = useCase.execute('elk_bugle');

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (call) {
          expect(call.id, 'elk_bugle');
          expect(call.animalName, 'Elk');
          expect(call.callType, 'Bugle');
        },
      );
    });

    test('returns CallNotFound when call does not exist', () {
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
      ];
      ReferenceDatabase.calls = mockCalls;

      // Act
      final result = useCase.execute('nonexistent_id');

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<CallNotFound>());
          expect(failure.message, contains('nonexistent_id'));
        },
        (call) => fail('Should not succeed'),
      );
    });

    test('returns LibraryNotInitialized when database is empty', () {
      // Arrange
      ReferenceDatabase.calls = [];

      // Act
      final result = useCase.execute('some_id');

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<LibraryNotInitialized>());
        },
        (call) => fail('Should not succeed'),
      );
    });
  });
}
