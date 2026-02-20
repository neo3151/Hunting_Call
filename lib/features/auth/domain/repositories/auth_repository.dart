import '../entities/auth_user.dart';

abstract class AuthRepository {
  Stream<AuthUser?> get authStateChanges;
  
  Future<AuthUser?> get currentUser;
  
  Future<void> signInAnonymously();
  
  Future<AuthUser> signInWithGoogle();
  
  /// Authenticates with email and password.
  Future<void> signInWithEmail(String email, String password);

  /// Registers a new user with email and password.
  Future<void> signUpWithEmail(String email, String password);

  /// Registers a new user WITHOUT emitting auth state changes.
  /// Returns the new user's ID so the caller can create a profile
  /// before triggering a navigation rebuild.
  Future<String> signUpSilent(String email, String password);

  /// Manually broadcasts the current auth state.
  /// Call after [signUpSilent] + profile creation to trigger AuthWrapper.
  void emitAuthState();

  /// [DEPRECATED] Use [signInWithEmail] for secure authentication.
  /// Previously used for insecure impersonation on desktop.
  Future<void> signIn(String userId);

  Future<void> signOut();
  
  /// Creates a technical session for Firestore access without
  /// triggering auth state changes (no AuthWrapper rebuild).
  Future<void> ensureTechnicalSession();
  
  bool get isMock;
}
