
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hunting_calls_perfection/features/auth/domain/auth_repository.dart';
import 'package:hunting_calls_perfection/providers/auth_provider.dart';
import 'package:hunting_calls_perfection/providers/profile_provider.dart';
import 'package:mocktail/mocktail.dart';

// Mocks
class MockAuthRepository extends Mock implements AuthRepository {}
class MockProfileNotifier extends Mock implements ProfileNotifier {}

void main() {
  late MockAuthRepository mockAuthRepo;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    // Default stubs
    when(() => mockAuthRepo.onAuthStateChanged).thenAnswer((_) => Stream.value("user1"));
  });

  test('AuthNotifier.signOut handles repository exceptions gracefully', () async {
    // Arrange
    when(() => mockAuthRepo.signOut()).thenThrow(Exception("Simulated Logout Crash"));
    
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
        profileNotifierProvider.overrideWith(() => MockProfileNotifier()), 
      ],
    );

    // Trigger initialization and wait for stream to settle
    final sub = container.listen(authNotifierProvider, (_, __) {});
    await Future.delayed(Duration.zero); // Allow Stream.value to emit

    // Check pre-condition
    debugPrint("Initial State: ${container.read(authNotifierProvider)}");

    // Act
    try {
      await container.read(authNotifierProvider.notifier).signOut();
    } catch (e) {
      debugPrint("Caught exception in test (unexpected): $e");
    }

    // Assert
    verify(() => mockAuthRepo.signOut()).called(1);
    
    // Check that the state reflects the error
    final state = container.read(authNotifierProvider);
    debugPrint("Final State: $state");
    
    expect(state.hasError, true);
    expect(state.error.toString(), contains("Simulated Logout Crash"));
    sub.close();
  });
  
  test('AuthNotifier.signOut calls repository signOut successfully', () async {
      // Arrange
      when(() => mockAuthRepo.signOut()).thenAnswer((_) async {});
      
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
        ],
      );

      // Act
      await container.read(authNotifierProvider.notifier).signOut();

      // Assert
      verify(() => mockAuthRepo.signOut()).called(1);
      
      // State should not be error (it might be loading or data depending on timing)
      final state = container.read(authNotifierProvider);
      expect(state.hasError, false);
    });
}
