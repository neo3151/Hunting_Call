import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:outcall/core/services/api_gateway.dart';

/// ══════════════════════════════════════════════════════════════════
/// STRESS TEST 2: API Gateway — Timeout & Error Resilience
/// Validates that the API gateway handles network failures, timeouts,
/// concurrent requests, and malformed data without crashing the app.
/// ══════════════════════════════════════════════════════════════════

// Mock Firestore
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}
class MockQuerySnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}
class MockQueryDocumentSnapshot extends Mock implements QueryDocumentSnapshot<Map<String, dynamic>> {}
class MockQuery extends Mock implements Query<Map<String, dynamic>> {}

void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockCollection;
  late MockDocumentReference mockDocRef;
  late FirebaseApiGateway gateway;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockCollection = MockCollectionReference();
    mockDocRef = MockDocumentReference();
    gateway = FirebaseApiGateway(mockFirestore);

    when(() => mockFirestore.collection(any())).thenReturn(mockCollection);
    when(() => mockCollection.doc(any())).thenReturn(mockDocRef);
  });

  setUpAll(() {
    registerFallbackValue(const GetOptions(source: Source.cache));
    registerFallbackValue(const GetOptions(source: Source.server));
  });

  // ─── Timeout Boundary Tests ────────────────────────────────────
  group('API Gateway Stress — Timeout Boundaries', () {
    test('getDocument should timeout after 4s on server failure', () async {
      final mockSnapshot = MockDocumentSnapshot();

      // Cache miss
      when(() => mockDocRef.get(any()))
          .thenAnswer((_) async {
        // Check if this is the cache call or server call
        final options = _.positionalArguments.isEmpty ? null : _.positionalArguments[0] as GetOptions?;
        if (options?.source == Source.cache) {
          throw FirebaseException(plugin: 'firestore', message: 'cache miss');
        }
        // Server call — simulate a network hang
        await Future.delayed(const Duration(seconds: 10));
        return mockSnapshot;
      });

      // This should hit the 4-second timeout boundary  
      final stopwatch = Stopwatch()..start();
      try {
        await gateway.getDocument('profiles', 'test_user');
      } catch (e) {
        // Expected — timeout error
      }
      stopwatch.stop();

      // Should have timed out around 4s, not wait the full 10s
      expect(stopwatch.elapsedMilliseconds, lessThan(6000),
          reason: 'Should timeout around 4s, not hang for 10s');
    });

    test('getDocument returns cache data when available (fast path)', () async {
      final mockSnapshot = MockDocumentSnapshot();
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.data()).thenReturn({'name': 'Test Hunter', 'score': 85});
      when(() => mockDocRef.get(any())).thenAnswer((_) async => mockSnapshot);

      final stopwatch = Stopwatch()..start();
      final result = await gateway.getDocument('profiles', 'test_user');
      stopwatch.stop();

      expect(result, isNotNull);
      expect(result!['name'], 'Test Hunter');
      // Cache should be nearly instant
      expect(stopwatch.elapsedMilliseconds, lessThan(100),
          reason: 'Cache hit should be <100ms');
    });
  });

  // ─── Concurrent Request Tests ──────────────────────────────────
  group('API Gateway Stress — Concurrent Requests', () {
    test('10 concurrent getDocument calls should all resolve', () async {
      final mockSnapshot = MockDocumentSnapshot();
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.data()).thenReturn({'id': 'test'});
      when(() => mockDocRef.get(any())).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return mockSnapshot;
      });

      final futures = List.generate(10, (i) =>
          gateway.getDocument('profiles', 'user_$i'));

      final results = await Future.wait(futures);

      expect(results.length, 10);
      for (final r in results) {
        expect(r, isNotNull);
      }
    });

    test('Mix of success/failure concurrent calls should isolate errors', () async {
      int callCount = 0;
      final mockSnapshot = MockDocumentSnapshot();
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.data()).thenReturn({'id': 'test'});

      when(() => mockDocRef.get(any())).thenAnswer((_) async {
        callCount++;
        if (callCount % 3 == 0) {
          throw FirebaseException(plugin: 'firestore', message: 'simulated error');
        }
        return mockSnapshot;
      });

      final results = <Map<String, dynamic>?>[];
      final errors = <Object>[];

      final futures = List.generate(9, (i) =>
          gateway.getDocument('profiles', 'user_$i')
              .then((r) => results.add(r))
              .catchError((e) { errors.add(e); }));

      await Future.wait(futures);

      // Some should succeed, some should fail
      // But none should crash the process
      expect(results.length + errors.length, 9,
          reason: 'All 9 requests should resolve (success or error)');
    });
  });

  // ─── Malformed Data Tests ──────────────────────────────────────
  group('API Gateway Stress — Malformed Data', () {
    test('setDocument with deeply nested map should not crash', () async {
      when(() => mockDocRef.set(any())).thenAnswer((_) async {});

      // Create a deeply nested map (10 levels)
      Map<String, dynamic> nested = {'value': 'leaf'};
      for (int i = 0; i < 10; i++) {
        nested = {'level_$i': nested};
      }

      // Should not throw
      await gateway.setDocument('profiles', 'test_user', nested);
      verify(() => mockDocRef.set(nested)).called(1);
    });

    test('setDocument with empty map should work', () async {
      when(() => mockDocRef.set(any())).thenAnswer((_) async {});

      await gateway.setDocument('profiles', 'test_user', {});
      verify(() => mockDocRef.set({})).called(1);
    });

    test('setDocument with special characters should not crash', () async {
      when(() => mockDocRef.set(any())).thenAnswer((_) async {});

      final data = {
        'name': 'Test <script>alert("xss")</script>',
        'emoji': '🦌🎯🔫',
        'newlines': 'line1\nline2\rline3',
        'nullValue': null,
      };

      await gateway.setDocument('profiles', 'test_user', data);
      verify(() => mockDocRef.set(data)).called(1);
    });
  });

  // ─── Error Recovery Tests ──────────────────────────────────────
  group('API Gateway Stress — Error Recovery', () {
    test('Transient error then success should eventually recover', () async {
      int attempt = 0;
      final mockSnapshot = MockDocumentSnapshot();
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.data()).thenReturn({'recovered': true});

      when(() => mockDocRef.get(any())).thenAnswer((_) async {
        attempt++;
        if (attempt <= 2) {
          throw FirebaseException(plugin: 'firestore', message: 'transient');
        }
        return mockSnapshot;
      });

      // First calls may fail (cache + server both throw)
      Map<String, dynamic>? result;
      for (int i = 0; i < 5; i++) {
        try {
          result = await gateway.getDocument('profiles', 'test');
          if (result != null) break;
        } catch (_) {
          // Expected — transient errors
        }
      }

      // Should eventually recover
      expect(result, isNotNull);
      expect(result!['recovered'], true);
    });
  });
}
