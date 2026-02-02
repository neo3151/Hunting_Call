abstract class AuthRepository {
  Future<void> signInAnonymously();
  Future<void> signInWithGoogle();
  Future<void> signIn(String userId);
  Future<void> signOut();
  Stream<String?> get onAuthStateChanged;
}
