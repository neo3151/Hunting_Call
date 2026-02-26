
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outcall/features/auth/domain/repositories/auth_repository.dart';
import 'package:outcall/features/auth/presentation/controllers/auth_controller.dart';
import 'package:outcall/features/auth/domain/usecases/sign_out.dart';
import 'package:outcall/features/auth/domain/usecases/get_auth_state_stream.dart';
import 'package:outcall/di_providers.dart';
import 'package:mocktail/mocktail.dart';

// Mocks
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepo;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    // Default stubs
    when(() => mockAuthRepo.authStateChanges).thenAnswer((_) => Stream.value(null));
    when(() => mockAuthRepo.currentUser).thenAnswer((_) async => null);
    when(() => mockAuthRepo.isMock).thenReturn(true);
  });

  test('AuthController.signOut handles repository exceptions gracefully', () async {
    // Arrange
    when(() => mockAuthRepo.signOut()).thenThrow(Exception('Simulated Logout Crash'));
    
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
        getAuthStateStreamUseCaseProvider.overrideWithValue(GetAuthStateStream(mockAuthRepo)),
        signOutUseCaseProvider.overrideWithValue(SignOut(mockAuthRepo)),
      ],
    );
    addTearDown(container.dispose);

    // Initialize controller and wait for stream to settle
    final sub = container.listen(authControllerProvider, (_, __) {});
    // Give the StreamNotifier time for the initial stream emission
    await Future.delayed(const Duration(milliseconds: 100));

    // Act
    await container.read(authControllerProvider.notifier).signOut();

    // Assert
    verify(() => mockAuthRepo.signOut()).called(1);
    
    // Check that the state reflects the error
    final state = container.read(authControllerProvider);
    debugPrint('Final State: $state');
    
    expect(state.hasError, true);
    expect(state.error.toString(), contains('Simulated Logout Crash'));
    sub.close();
  });
  
  test('AuthController.signOut calls repository signOut successfully', () async {
    // Arrange
    when(() => mockAuthRepo.signOut()).thenAnswer((_) async {});
    
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
        getAuthStateStreamUseCaseProvider.overrideWithValue(GetAuthStateStream(mockAuthRepo)),
        signOutUseCaseProvider.overrideWithValue(SignOut(mockAuthRepo)),
      ],
    );
    addTearDown(container.dispose);

    // Initialize controller and wait for stream to settle
    final sub = container.listen(authControllerProvider, (_, __) {});
    await Future.delayed(const Duration(milliseconds: 100));

    // Act
    await container.read(authControllerProvider.notifier).signOut();

    // Assert
    verify(() => mockAuthRepo.signOut()).called(1);
    
    // State should not be error
    final state = container.read(authControllerProvider);
    expect(state.hasError, false);
    sub.close();
  });
}
