import 'package:hunting_calls_perfection/features/auth/data/models/auth_user_model.dart';

abstract class AuthRemoteDataSource {
  Stream<AuthUserModel?> get authStateChanges;
  
  AuthUserModel? get currentUser;
  
  Future<void> signInAnonymously();
  
  Future<AuthUserModel> signInWithGoogle();
  
  Future<void> signIn(String userId);

  Future<void> signOut();
}
