import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/features/auth/domain/entities/auth_user.dart';

void main() {
  group('AuthUser', () {
    test('stores all fields', () {
      const user = AuthUser(
        id: 'uid_123',
        email: 'hunter@example.com',
        displayName: 'Buck Hunter',
        isAnonymous: false,
      );
      expect(user.id, 'uid_123');
      expect(user.email, 'hunter@example.com');
      expect(user.displayName, 'Buck Hunter');
      expect(user.isAnonymous, false);
    });

    test('defaults isAnonymous to false', () {
      const user = AuthUser(id: 'uid_1');
      expect(user.isAnonymous, false);
      expect(user.email, isNull);
      expect(user.displayName, isNull);
    });

    test('anonymous user', () {
      const user = AuthUser(id: 'anon_1', isAnonymous: true);
      expect(user.isAnonymous, true);
    });

    test('equality via Equatable', () {
      const a = AuthUser(id: 'uid_1', email: 'a@b.com');
      const b = AuthUser(id: 'uid_1', email: 'a@b.com');
      expect(a, equals(b));
    });

    test('different id means not equal', () {
      const a = AuthUser(id: 'uid_1');
      const b = AuthUser(id: 'uid_2');
      expect(a, isNot(equals(b)));
    });

    test('same id but different email means not equal', () {
      const a = AuthUser(id: 'uid_1', email: 'a@b.com');
      const b = AuthUser(id: 'uid_1', email: 'c@d.com');
      expect(a, isNot(equals(b)));
    });

    test('props includes all fields', () {
      const user = AuthUser(
        id: 'uid_1',
        email: 'a@b.com',
        displayName: 'Test',
        isAnonymous: true,
      );
      expect(user.props, [user.id, user.email, user.displayName, user.isAnonymous]);
    });
  });
}
