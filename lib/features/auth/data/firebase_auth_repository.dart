import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/entities/auth_user.dart';
import 'package:hunting_calls_perfection/core/utils/app_logger.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  @override
  Stream<AuthUser?> get authStateChanges => _auth.authStateChanges().map(_mapFirebaseUser);

  AuthUser? _mapFirebaseUser(User? user) {
      if (user == null) return null;
      return AuthUser(
          id: user.uid,
          email: user.email,
          displayName: user.displayName,
          isAnonymous: user.isAnonymous,
      );
  }

  @override
  Future<void> signIn(String userId) async {
    if (_auth.currentUser?.uid != userId) {
      await signInAnonymously();
    }
  }

  @override
  Future<void> signInAnonymously() async {
    await _auth.signInAnonymously();
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    try {
      AppLogger.d('🔐 FirebaseAuthRepository: Starting Google Sign-In...');
      
      final googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      
      final UserCredential userCredential = await _auth.signInWithProvider(googleProvider);
      final user = userCredential.user;
      
      if (user == null) throw Exception('Google Sign-In returned null user');

      final email = user.email;
      final displayName = user.displayName;
      final uid = user.uid;
      
      AppLogger.d('✅ Google Sign-In successful!');
      AppLogger.d('👤 Name: $displayName | Email: $email | UID: $uid');
      
      await _ensureProfileInFirestore(uid, email, displayName);
      
      return _mapFirebaseUser(user)!;
      
    } catch (e, stackTrace) {
      AppLogger.d('❌ Google Sign-In Error: $e');
      AppLogger.d('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Creates or finds a profile in Firestore directly.
  Future<void> _ensureProfileInFirestore(String uid, String? email, String? displayName) async {
    try {
      final profilesRef = _firestore.collection('profiles');
      
      // 1. Check if profile exists by UID
      final docSnap = await profilesRef.doc(uid).get();
      if (docSnap.exists) {
        AppLogger.d('🔍 Profile already exists for UID $uid');
        return;
      }
      
      // 2. Check if profile exists by email
      if (email != null) {
        final emailQuery = await profilesRef.where('email', isEqualTo: email).limit(1).get();
        if (emailQuery.docs.isNotEmpty) {
          AppLogger.d("🔍 Profile found by email: ${emailQuery.docs.first.data()['name']}");
          return;
        }
      }
      
      // 3. No profile exists - create one
      final profileName = displayName ?? email?.split('@').first ?? 'Hunter';
      
      AppLogger.d('🆕 Creating profile: $profileName (email: $email, uid: $uid)');
      
      await profilesRef.doc(uid).set({
        'id': uid,
        'name': profileName,
        'email': email,
        'joinedDate': DateTime.now().toIso8601String(),
        'birthday': null,
        'totalCalls': 0,
        'averageScore': 0.0,
        'currentStreak': 0,
        'longestStreak': 0,
        'dailyChallengesCompleted': 0,
        'lastDailyChallengeDate': null,
        'achievements': [],
        'history': [],
      });
      
      AppLogger.d('✅ Profile created in Firestore!');
      
    } catch (e) {
      AppLogger.d('⚠️ Error in _ensureProfileInFirestore: $e');
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Future<AuthUser?> get currentUser async => _mapFirebaseUser(_auth.currentUser);

  @override
  bool get isMock => false;
}
