import '../entities/auth_user.dart';

abstract class AuthRepository {
  Stream<AuthUser?> get authStateChanges;
  
  Future<AuthUser?> get currentUser;
  
  Future<void> signInAnonymously();
  
  Future<AuthUser> signInWithGoogle();
  
  Future<void> signIn(String userId);

  Future<void> signOut();
  
  /// Creates a technical session for Firestore access without
  /// triggering auth state changes (no AuthWrapper rebuild).
  Future<void> ensureTechnicalSession();
  
  bool get isMock;
}
