import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:hunting_calls_perfection/features/auth/domain/entities/auth_user.dart';

class AuthUserModel extends AuthUser {
  const AuthUserModel({
    required super.id,
    super.email,
    super.displayName,
    super.isAnonymous,
  });

  factory AuthUserModel.fromFirebaseUser(firebase.User user) {
    return AuthUserModel(
      id: user.uid,
      email: user.email,
      displayName: user.displayName,
      isAnonymous: user.isAnonymous,
    );
  }
}
