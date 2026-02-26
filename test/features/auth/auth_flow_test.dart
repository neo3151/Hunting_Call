import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/features/auth/data/mock_auth_repository.dart';
import 'package:outcall/features/auth/domain/entities/auth_user.dart';

void main() {
  late MockAuthRepository auth;

  setUp(() {
    auth = MockAuthRepository();
  });

  group('MockAuthRepository', () {
    test('isMock returns true', () {
      expect(auth.isMock, isTrue);
    });

    test('initial state has no current user', () async {
      final user = await auth.currentUser;
      expect(user, isNull);
    });

    test('signInAnonymously sets anonymous user', () async {
      await auth.signInAnonymously();
      final user = await auth.currentUser;

      expect(user, isNotNull);
      expect(user!.isAnonymous, isTrue);
      expect(user.id, isNotEmpty);
    });

    test('signInWithGoogle returns user with email and display name', () async {
      final user = await auth.signInWithGoogle();

      expect(user.id, isNotEmpty);
      expect(user.email, isNotNull);
      expect(user.displayName, isNotNull);
      expect(user.isAnonymous, isFalse);
    });

    test('signIn with userId sets correct user', () async {
      await auth.signIn('custom_user_789');
      final user = await auth.currentUser;

      expect(user, isNotNull);
      expect(user!.id, 'custom_user_789');
    });

    test('signOut clears current user', () async {
      await auth.signInAnonymously();
      expect(await auth.currentUser, isNotNull);

      await auth.signOut();
      expect(await auth.currentUser, isNull);
    });

    test('authStateChanges emits updates on sign-in and sign-out', () async {
      final states = <AuthUser?>[];
      final sub = auth.authStateChanges.listen(states.add);

      await auth.signInAnonymously();
      await auth.signOut();
      await auth.signInWithGoogle();

      // Allow stream to process
      await Future.delayed(const Duration(milliseconds: 50));
      await sub.cancel();

      expect(states.length, 3);
      expect(states[0]?.isAnonymous, isTrue); // anonymous sign-in
      expect(states[1], isNull); // sign-out
      expect(states[2]?.email, isNotNull); // google sign-in
    });

    test('ensureTechnicalSession completes without error', () async {
      await expectLater(auth.ensureTechnicalSession(), completes);
    });

    test('double sign-out does not crash', () async {
      await auth.signOut();
      await auth.signOut();
      expect(await auth.currentUser, isNull);
    });

    test('sign-in after sign-out works correctly', () async {
      await auth.signInAnonymously();
      await auth.signOut();
      await auth.signIn('new_user');

      final user = await auth.currentUser;
      expect(user, isNotNull);
      expect(user!.id, 'new_user');
    });
  });

  group('AuthUser', () {
    test('equality works via Equatable', () {
      const user1 = AuthUser(id: 'abc', email: 'test@test.com');
      const user2 = AuthUser(id: 'abc', email: 'test@test.com');
      const user3 = AuthUser(id: 'def', email: 'test@test.com');

      expect(user1, equals(user2));
      expect(user1, isNot(equals(user3)));
    });

    test('default isAnonymous is false', () {
      const user = AuthUser(id: 'test');
      expect(user.isAnonymous, isFalse);
    });

    test('optional fields are null by default', () {
      const user = AuthUser(id: 'test');
      expect(user.email, isNull);
      expect(user.displayName, isNull);
    });

    test('props include all fields for equality comparison', () {
      const user = AuthUser(
        id: 'test',
        email: 'test@example.com',
        displayName: 'Test User',
        isAnonymous: true,
      );

      expect(user.props, containsAll([
        'test',
        'test@example.com',
        'Test User',
        true,
      ]));
    });
  });
}
