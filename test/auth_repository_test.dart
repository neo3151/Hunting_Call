import 'package:flutter_test/flutter_test.dart';
import 'package:hunting_calls_perfection/features/auth/data/mock_auth_repository.dart';

void main() {
  late MockAuthRepository authRepository;

  setUp(() {
    authRepository = MockAuthRepository();
  });

  group('MockAuthRepository Tests', () {
    test('Initial state should be null', () async {
      expect(await authRepository.onAuthStateChanged.first, null);
    });

    test('signIn should update state and emit userId', () async {
      await authRepository.signIn('test_user');
      expect(await authRepository.onAuthStateChanged.first, 'test_user');
    });

    test('signInAnonymously should update state and emit anon_user_123', () async {
      await authRepository.signInAnonymously();
      expect(await authRepository.onAuthStateChanged.first, 'anon_user_123');
    });

    test('signInWithGoogle should update state and emit google_user_456', () async {
      await authRepository.signInWithGoogle();
      expect(await authRepository.onAuthStateChanged.first, 'google_user_456');
    });

    test('signOut should reset state to null', () async {
      await authRepository.signIn('test_user');
      await authRepository.signOut();
      expect(await authRepository.onAuthStateChanged.first, null);
    });

    test('Stream should emit events when state changes', () async {
      final states = <String?>[];
      final subscription = authRepository.onAuthStateChanged.listen((user) {
        states.add(user);
      });

      // Give it a moment to receive the initial state from onListen
      await Future.delayed(Duration.zero);

      await authRepository.signIn('user1');
      await authRepository.signIn('user2');
      await authRepository.signOut();

      // Wait for all events to be processed
      await Future.delayed(Duration.zero);

      expect(states, [null, 'user1', 'user2', null]);
      
      await subscription.cancel();
    });
  });
}
