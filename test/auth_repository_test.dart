import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/features/auth/data/mock_auth_repository.dart';

void main() {
  late MockAuthRepository authRepository;

  setUp(() {
    authRepository = MockAuthRepository();
  });

  group('MockAuthRepository Tests', () {
    test('Initial state should be null (or empty stream start)', () async {
      // MockAuthRepository uses a broadcast stream that doesn't emit until an action happens.
      // So we check currentUser instead.
      final user = await authRepository.currentUser;
      expect(user, isNull);
    });

    test('signIn should update currentUser', () async {
      await authRepository.signIn('test_user');
      final user = await authRepository.currentUser;
      expect(user, isNotNull);
      expect(user!.id, equals('test_user'));
    });

    test('signInAnonymously should set an anonymous user', () async {
      await authRepository.signInAnonymously();
      final user = await authRepository.currentUser;
      expect(user, isNotNull);
      expect(user!.id, equals('anon_user_123'));
    });

    test('signInWithGoogle should set a google user', () async {
      final user = await authRepository.signInWithGoogle();
      expect(user.id, equals('google_user_456'));
    });

    test('signOut should reset state to null', () async {
      await authRepository.signIn('test_user');
      final userBefore = await authRepository.currentUser;
      expect(userBefore, isNotNull);

      await authRepository.signOut();
      final userAfter = await authRepository.currentUser;
      expect(userAfter, isNull);
    });

    test('isMock should return true', () {
      expect(authRepository.isMock, isTrue);
    });
  });
}
