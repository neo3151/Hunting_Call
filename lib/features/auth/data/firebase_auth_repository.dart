import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../domain/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  @override
  Stream<String?> get onAuthStateChanged => _auth.authStateChanges().map((user) => user?.uid);

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
  Future<Map<String, String?>> signInWithGoogle() async {
    try {
      debugPrint("🔐 FirebaseAuthRepository: Starting Google Sign-In...");
      
      final googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      
      final UserCredential userCredential = await _auth.signInWithProvider(googleProvider);
      
      final user = userCredential.user;
      final email = user?.email;
      final displayName = user?.displayName;
      final uid = user?.uid;
      
      debugPrint("✅ Google Sign-In successful!");
      debugPrint("👤 Name: $displayName | Email: $email | UID: $uid");
      
      // === CREATE/FIND PROFILE IMMEDIATELY ===
      // We do this RIGHT HERE because:
      // 1. We have the UserCredential with email & displayName
      // 2. This code runs to completion (not a widget that can unmount)
      // 3. onAuthStateChanged already fired, so AuthWrapper is waiting for this profile
      if (uid != null) {
        await _ensureProfileInFirestore(uid, email, displayName);
      }
      
      return {
        'email': email,
        'displayName': displayName,
      };
      
    } catch (e, stackTrace) {
      debugPrint("❌ Google Sign-In Error: $e");
      debugPrint("Stack trace: $stackTrace");
      rethrow;
    }
  }

  /// Creates or finds a profile in Firestore directly.
  /// This is called from signInWithGoogle BEFORE returning.
  Future<void> _ensureProfileInFirestore(String uid, String? email, String? displayName) async {
    try {
      final profilesRef = _firestore.collection('profiles');
      
      // 1. Check if profile exists by UID
      final docSnap = await profilesRef.doc(uid).get();
      if (docSnap.exists) {
        debugPrint("🔍 Profile already exists for UID $uid");
        return;
      }
      
      // 2. Check if profile exists by email (handles different UIDs for same Google account)
      if (email != null) {
        final emailQuery = await profilesRef.where('email', isEqualTo: email).limit(1).get();
        if (emailQuery.docs.isNotEmpty) {
          debugPrint("🔍 Profile found by email: ${emailQuery.docs.first.data()['name']}");
          // Profile exists with different UID - just return, AuthWrapper will find it
          return;
        }
      }
      
      // 3. No profile exists - create one
      final profileName = displayName ?? email?.split('@').first ?? 'Hunter';
      
      debugPrint("🆕 Creating profile: $profileName (email: $email, uid: $uid)");
      
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
      
      debugPrint("✅ Profile created in Firestore!");
      
    } catch (e) {
      debugPrint("⚠️ Error in _ensureProfileInFirestore: $e");
      // Don't rethrow - profile creation failure shouldn't block sign-in
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  String? get authenticatedUserId => _auth.currentUser?.uid;

  @override
  bool get isMock => false;
}
