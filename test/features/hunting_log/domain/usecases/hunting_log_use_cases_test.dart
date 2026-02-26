import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/features/hunting_log/domain/usecases/get_all_logs_use_case.dart';
import 'package:outcall/features/hunting_log/domain/usecases/add_log_use_case.dart';
import 'package:outcall/features/hunting_log/domain/usecases/delete_log_use_case.dart';
import 'package:outcall/features/hunting_log/domain/failures/hunting_log_failure.dart';
import 'package:outcall/features/hunting_log/domain/hunting_log_entry.dart';
import 'package:outcall/features/hunting_log/domain/repositories/hunting_log_repository.dart';

// Mock repository for testing
class MockHuntingLogRepository implements HuntingLogRepository {
  List<HuntingLogEntry> _logs = [];
  bool _initialized = false;
  bool _shouldThrowError = false;

  void setShouldThrowError(bool value) {
    _shouldThrowError = value;
  }

  @override
  Future<void> initialize() async {
    if (_shouldThrowError) throw Exception('Init failed');
    _initialized = true;
  }

  @override
  Future<List<HuntingLogEntry>> getLogs() async {
    if (_shouldThrowError) throw Exception('Get logs failed');
    if (!_initialized) throw Exception('Database not initialized');
    return List.from(_logs);
  }

  @override
  Future<void> addLog(HuntingLogEntry entry) async {
    if (_shouldThrowError) throw Exception('Add log failed');
    if (!_initialized) throw Exception('Database not initialized');
    _logs.add(entry);
  }

  @override
  Future<void> deleteLog(String id) async {
    if (_shouldThrowError) throw Exception('Delete log failed');
    if (!_initialized) throw Exception('Database not initialized');
    _logs.removeWhere((log) => log.id == id);
  }

  void reset() {
    _logs = [];
    _initialized = false;
    _shouldThrowError = false;
  }
}

void main() {
  late MockHuntingLogRepository mockRepository;

  setUp(() {
    mockRepository = MockHuntingLogRepository();
  });

  tearDown(() {
    mockRepository.reset();
  });

  group('GetAllLogsUseCase', () {
    test('returns empty list when no logs exist', () async {
      // Arrange
      final useCase = GetAllLogsUseCase(mockRepository);

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (logs) => expect(logs, isEmpty),
      );
    });

    test('returns all logs when they exist', () async {
      // Arrange
      final useCase = GetAllLogsUseCase(mockRepository);
      final entry1 = HuntingLogEntry(
        id: '1',
        timestamp: DateTime(2024, 1, 1),
        notes: 'First log',
      );
      final entry2 = HuntingLogEntry(
        id: '2',
        timestamp: DateTime(2024, 1, 2),
        notes: 'Second log',
      );
      
      await mockRepository.initialize();
      await mockRepository.addLog(entry1);
      await mockRepository.addLog(entry2);

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (logs) {
          expect(logs.length, 2);
          expect(logs, contains(entry1));
          expect(logs, contains(entry2));
        },
      );
    });

    test('returns DatabaseError when operation fails', () async {
      // Arrange
      final useCase = GetAllLogsUseCase(mockRepository);
      mockRepository.setShouldThrowError(true);

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<DatabaseError>());
          expect(failure.message, contains('Database error'));
        },
        (logs) => fail('Should fail'),
      );
    });
  });

  group('AddLogUseCase', () {
    test('successfully adds a log entry', () async {
      // Arrange
      final useCase = AddLogUseCase(mockRepository);
      final entry = HuntingLogEntry(
        id: '1',
        timestamp: DateTime.now(),
        notes: 'Test log',
        animalId: 'deer_whitetail',
      );

      // Act
      final result = await useCase.execute(entry);

      // Assert
      expect(result.isRight(), true);
      
      // Verify log was added
      await mockRepository.initialize();
      final logs = await mockRepository.getLogs();
      expect(logs.length, 1);
      expect(logs.first.id, entry.id);
    });

    test('returns DatabaseError when add operation fails', () async {
      // Arrange
      final useCase = AddLogUseCase(mockRepository);
      final entry = HuntingLogEntry(
        id: '1',
        timestamp: DateTime.now(),
        notes: 'Test log',
      );
      mockRepository.setShouldThrowError(true);

      // Act
      final result = await useCase.execute(entry);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<DatabaseError>());
          expect(failure.message, contains('Database error'));
        },
        (_) => fail('Should fail'),
      );
    });
  });

  group('DeleteLogUseCase', () {
    test('successfully deletes a log entry', () async {
      // Arrange
      final useCase = DeleteLogUseCase(mockRepository);
      final entry = HuntingLogEntry(
        id: '1',
        timestamp: DateTime.now(),
        notes: 'Test log',
      );
      
      await mockRepository.initialize();
      await mockRepository.addLog(entry);

      // Act
      final result = await useCase.execute('1');

      // Assert
      expect(result.isRight(), true);
      
      // Verify log was deleted
      final logs = await mockRepository.getLogs();
      expect(logs, isEmpty);
    });

    test('returns DatabaseError when delete operation fails', () async {
      // Arrange
      final useCase = DeleteLogUseCase(mockRepository);
      mockRepository.setShouldThrowError(true);

      // Act
      final result = await useCase.execute('1');

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<DatabaseError>());
          expect(failure.message, contains('Database error'));
        },
        (_) => fail('Should fail'),
      );
    });
  });

  group('Integration - CRUD Operations', () {
    test('complete CRUD flow works correctly', () async {
      // Arrange
      final getAllUseCase = GetAllLogsUseCase(mockRepository);
      final addUseCase = AddLogUseCase(mockRepository);
      final deleteUseCase = DeleteLogUseCase(mockRepository);

      // Add multiple logs
      final entry1 = HuntingLogEntry(
        id: '1',
        timestamp: DateTime(2024, 1, 1),
        notes: 'First log',
      );
      final entry2 = HuntingLogEntry(
        id: '2',
        timestamp: DateTime(2024, 1, 2),
        notes: 'Second log',
      );

      // Act & Assert - Add
      final addResult1 = await addUseCase.execute(entry1);
      expect(addResult1.isRight(), true);
      
      final addResult2 = await addUseCase.execute(entry2);
      expect(addResult2.isRight(), true);

      // Act & Assert - Get All
      var getAllResult = await getAllUseCase.execute();
      expect(getAllResult.isRight(), true);
      getAllResult.fold(
        (_) => fail('Should succeed'),
        (logs) => expect(logs.length, 2),
      );

      // Act & Assert - Delete
      final deleteResult = await deleteUseCase.execute('1');
      expect(deleteResult.isRight(), true);

      // Act & Assert - Get All (after delete)
      getAllResult = await getAllUseCase.execute();
      getAllResult.fold(
        (_) => fail('Should succeed'),
        (logs) {
          expect(logs.length, 1);
          expect(logs.first.id, '2');
        },
      );
    });
  });
}
