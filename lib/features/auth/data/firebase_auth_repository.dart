import 'package:firebase_auth/firebase_auth.dart';
import '../domain/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  @override
  Stream<String?> get onAuthStateChanged => _auth.authStateChanges().map((user) => user?.uid);

  @override
  Future<void> signIn(String userId) async {
    // In a real app with Firebase, we usually sign in with email/password or social providers.
    // For now, if we want to "sign in as a specific user ID" (like the mock did), 
    // we might need a custom token or just use anonymous sign-in if the ID is just for local tracking.
    // However, properly speaking, Firebase Auth handles its own IDs.
    // I will implement anonymous sign-in here as a fallback if the userId isn't used for real auth.
    if (_auth.currentUser?.uid != userId) {
      await signInAnonymously();
    }
  }

  @override
  Future<void> signInAnonymously() async {
    await _auth.signInAnonymously();
  }

  @override
  Future<void> signInWithGoogle() async {
    // Note: Google Sign-In requires additional setup (google_sign_in package)
    // and configuration in Firebase Console. 
    // This is a placeholder for the logic.
    throw UnimplementedError("Google Sign-In requires the 'google_sign_in' package and platform-specific setup.");
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  String? get currentUserId => _auth.currentUser?.uid;
}
