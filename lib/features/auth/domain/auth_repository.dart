abstract class AuthRepository {
  Future<void> signInAnonymously();
  Future<Map<String, String?>> signInWithGoogle();
  Future<void> signIn(String userId);
  Future<void> signOut();
  Stream<String?> get onAuthStateChanged;
  String? get currentUserId;
  String? get authenticatedUserId;
  bool get isMock;
}
