import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/features/library/domain/use_cases/filter_calls_use_case.dart';
import 'package:outcall/features/library/domain/use_cases/get_all_calls_use_case.dart';
import 'package:outcall/features/library/domain/use_cases/get_call_by_id_use_case.dart';
import 'package:outcall/features/library/data/reference_database.dart';
import 'package:outcall/features/library/domain/reference_call_model.dart';

/// Integration test: verifies the library browsing user journey
/// load all → filter by category → search by name → get by ID
void main() {
  const filterUseCase = FilterCallsUseCase();
  const getAllUseCase = GetAllCallsUseCase();
  const getByIdUseCase = GetCallByIdUseCase();

  // Seed mock data before each test
  final mockCalls = [
    const ReferenceCall(
      id: 'mallard_feeding',
      animalName: 'Mallard Duck',
      callType: 'Feeding Call',
      category: 'Waterfowl',
      difficulty: 'Beginner',
      idealPitchHz: 500.0,
      idealDurationSec: 2.0,
      audioAssetPath: 'assets/audio/mallard.mp3',
    ),
    const ReferenceCall(
      id: 'wood_duck_whistle',
      animalName: 'Wood Duck',
      callType: 'Whistle',
      category: 'Waterfowl',
      difficulty: 'Intermediate',
      idealPitchHz: 700.0,
      idealDurationSec: 1.5,
      audioAssetPath: 'assets/audio/wood_duck.mp3',
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
    ),
    const ReferenceCall(
      id: 'turkey_yelp',
      animalName: 'Wild Turkey',
      callType: 'Yelp',
      category: 'Upland',
      difficulty: 'Beginner',
      idealPitchHz: 600.0,
      idealDurationSec: 1.0,
      audioAssetPath: 'assets/audio/turkey.mp3',
    ),
  ];

  setUp(() {
    ReferenceDatabase.calls = List.from(mockCalls);
  });

  tearDown(() {
    ReferenceDatabase.calls = [];
  });

  group('Library Browsing Flow Integration', () {
    test('Get all calls returns the seeded list', () {
      final result = getAllUseCase.execute();
      result.fold(
        (failure) => fail('getAllCalls should not fail: $failure'),
        (calls) {
          expect(calls.length, 4);
          expect(calls.map((c) => c.id).toList(),
              containsAll(['mallard_feeding', 'elk_bugle', 'wood_duck_whistle', 'turkey_yelp']));
        },
      );
    });

    test('Filter by category returns only matching animals', () {
      final result = filterUseCase.execute(category: 'Waterfowl', searchQuery: '');
      result.fold(
        (failure) => fail('Filter by category should not fail: $failure'),
        (calls) {
          expect(calls.length, 2);
          for (final call in calls) {
            expect(call.category, 'Waterfowl');
          }
        },
      );
    });

    test('Filter with "All" category returns all animals', () {
      final result = filterUseCase.execute(category: 'All', searchQuery: '');
      result.fold(
        (f) => fail('Filter All failed: $f'),
        (calls) => expect(calls.length, 4),
      );
    });

    test('Filter by search query returns partial name matches', () {
      final result = filterUseCase.execute(category: 'All', searchQuery: 'duck');
      result.fold(
        (failure) => fail('Filter by search should not fail: $failure'),
        (calls) {
          expect(calls.length, 2); // Mallard Duck + Wood Duck
          for (final call in calls) {
            expect(call.animalName.toLowerCase(), contains('duck'));
          }
        },
      );
    });

    test('Combined filter: category + search query', () {
      final result = filterUseCase.execute(category: 'Waterfowl', searchQuery: 'mallard');
      result.fold(
        (failure) => fail('Combined filter should not fail: $failure'),
        (calls) {
          expect(calls.length, 1);
          expect(calls.first.id, 'mallard_feeding');
          expect(calls.first.category, 'Waterfowl');
        },
      );
    });

    test('Get call by known ID returns correct animal', () {
      final result = getByIdUseCase.execute('elk_bugle');
      result.fold(
        (failure) => fail('getCallById should not fail: $failure'),
        (call) {
          expect(call.id, 'elk_bugle');
          expect(call.animalName, 'Elk');
          expect(call.category, 'Big Game');
        },
      );
    });

    test('Get call by unknown ID returns failure', () {
      final result = getByIdUseCase.execute('nonexistent_12345');
      result.fold(
        (failure) => expect(failure, isNotNull),
        (call) => fail('Should not return a call for unknown ID'),
      );
    });

    test('Full browsing flow: all → filter → select → verify', () {
      // 1. Load all
      final allResult = getAllUseCase.execute();
      late List<ReferenceCall> allCalls;
      allResult.fold((f) => fail('Load all failed: $f'), (c) => allCalls = c);
      expect(allCalls.length, 4);

      // 2. Get categories
      final categories = allCalls.map((c) => c.category).toSet();
      expect(categories, containsAll(['Waterfowl', 'Big Game', 'Upland']));

      // 3. Filter to Waterfowl
      final filterResult = filterUseCase.execute(category: 'Waterfowl', searchQuery: '');
      late List<ReferenceCall> filtered;
      filterResult.fold((f) => fail('Filter failed: $f'), (c) => filtered = c);
      expect(filtered.length, 2);

      // 4. Select first by ID
      final selected = getByIdUseCase.execute(filtered.first.id);
      selected.fold(
        (f) => fail('Select failed: $f'),
        (call) {
          expect(call.category, 'Waterfowl');
          expect(call.animalName, isNotEmpty);
          expect(call.audioAssetPath, isNotEmpty);
          expect(call.idealPitchHz, greaterThan(0));
        },
      );
    });
  });
}
