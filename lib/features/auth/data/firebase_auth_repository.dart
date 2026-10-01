import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:outcall/features/auth/domain/repositories/auth_repository.dart';
import 'package:outcall/features/auth/domain/entities/auth_user.dart';
import 'package:outcall/core/utils/app_logger.dart';
import 'dart:io';

import 'package:outcall/features/auth/data/desktop_oauth_helper.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789FFFFFFABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  @override
  Stream<AuthUser?> get authStateChanges =>
      _auth.authStateChanges().map(_mapFirebaseUser);

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
  Future<void> signInWithEmail(String email, String password) async {
    AppLogger.d('🔐 FirebaseAuthRepository: Signing in with email: $email');
    final credential = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    final user = credential.user;
    if (user != null) {
      await _ensureProfileInFirestore(user.uid, user.email, user.displayName);
    }
  }

  @override
  Future<void> signUpWithEmail(String email, String password) async {
    AppLogger.d('🔐 FirebaseAuthRepository: Signing up with email: $email');
    final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    final user = userCredential.user;
    if (user != null) {
      await _ensureProfileInFirestore(user.uid, email, null);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    AppLogger.d(
        '🔐 FirebaseAuthRepository: Sending password reset email to: $email');
    await _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    try {
      AppLogger.d('🔐 FirebaseAuthRepository: Starting Google Sign-In...');

      UserCredential userCredential;
      String? googleDisplayName;

      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        // Native Google Sign-In for mobile
        final GoogleSignIn googleSignIn = GoogleSignIn.instance;
        try {
          await googleSignIn.initialize();
        } catch (e) {
          AppLogger.d('GoogleSignIn.initialize() failed (non-critical): $e');
        }

        GoogleSignInAccount googleUser;
        try {
          googleUser =
              await googleSignIn.authenticate(scopeHint: ['email', 'profile']);
        } catch (e) {
          AppLogger.d('GoogleSignIn.authenticate failed: $e');
          final errStr = e.toString().toLowerCase();
          if (errStr.contains('canceled') ||
              errStr.contains('cancelled') ||
              errStr.contains('closed') ||
              errStr.contains('user_canceled')) {
            throw Exception('Google Sign-In was cancelled or closed.');
          }
          rethrow;
        }

        googleDisplayName = googleUser.displayName;

        final GoogleSignInAuthentication googleAuth = googleUser.authentication;
        final authClient = googleUser.authorizationClient;
        final authz =
            await authClient.authorizationForScopes(['email', 'profile']) ??
                await authClient.authorizeScopes(['email', 'profile']);

        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: authz.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
      } else if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
        // Desktop Google Sign-In via Web OAuth Bridge
        userCredential = await DesktopOAuthHelper.signInWithGoogleDesktop();
      } else {
        // Web flow
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        try {
          userCredential = await _auth.signInWithProvider(googleProvider);
        } catch (e) {
          final errStr = e.toString().toLowerCase();
          if (errStr.contains('canceled') ||
              errStr.contains('cancelled') ||
              errStr.contains('closed') ||
              errStr.contains('popup_closed')) {
            throw Exception('Google Sign-In was cancelled or closed.');
          }
          rethrow;
        }
      }

      final user = userCredential.user;
      if (user == null) throw Exception('Google Sign-In returned null user');

      final email = user.email;
      final displayName = (user.displayName != null &&
              user.displayName!.trim().isNotEmpty)
          ? user.displayName!.trim()
          : (googleDisplayName != null && googleDisplayName.trim().isNotEmpty)
              ? googleDisplayName.trim()
              : null;
      final uid = user.uid;

      if (user.displayName == null && displayName != null) {
        try {
          await user.updateDisplayName(displayName);
        } catch (_) {}
      }

      AppLogger.d('✅ Google Sign-In successful!');
      AppLogger.d('👤 Name: $displayName | Email: $email | UID: $uid');

      await _ensureProfileInFirestore(uid, email, displayName);

      final mapped = _mapFirebaseUser(user);
      return AuthUser(
        id: uid,
        email: email,
        displayName: displayName ?? mapped?.displayName,
        isAnonymous: user.isAnonymous,
      );
    } catch (e, stackTrace) {
      AppLogger.d('❌ Google Sign-In Error: $e');
      AppLogger.d('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<AuthUser> signInWithApple() async {
    try {
      AppLogger.d('🔐 FirebaseAuthRepository: Starting Apple Sign-In...');

      UserCredential userCredential;

      if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
        // Native Apple Sign-In on Apple platforms with Desktop Web OAuth Bridge fallback
        try {
          final rawNonce = _generateNonce();
          final nonce = _sha256ofString(rawNonce);

          final appleCredential = await SignInWithApple.getAppleIDCredential(
            scopes: [
              AppleIDAuthorizationScopes.email,
              AppleIDAuthorizationScopes.fullName,
            ],
            nonce: nonce,
          );

          final oauthCredential = OAuthProvider('apple.com').credential(
            idToken: appleCredential.identityToken,
            rawNonce: rawNonce,
          );

          userCredential = await _auth.signInWithCredential(oauthCredential);
        } catch (e) {
          final errStr = e.toString().toLowerCase();
          AppLogger.d('Native Apple Sign-In error: $e');

          if (e is SignInWithAppleAuthorizationException &&
                  e.code == AuthorizationErrorCode.canceled ||
              errStr.contains('authorizationerrorcode.canceled') ||
              errStr.contains('user_canceled')) {
            throw Exception('Apple Sign-In was cancelled.');
          }

          AppLogger.d('Native Apple Sign-In unavailable ($e), launching Desktop Web OAuth Bridge...');
          userCredential = await DesktopOAuthHelper.signInWithAppleDesktop();
        }
      } else {
        final appleProvider = OAuthProvider('apple.com');
        appleProvider.addScope('email');
        appleProvider.addScope('name');
        try {
          userCredential = await _auth.signInWithProvider(appleProvider);
        } catch (e) {
          final errStr = e.toString().toLowerCase();
          if (errStr.contains('cancel') ||
              errStr.contains('closed') ||
              errStr.contains('null value')) {
            throw Exception('Apple Sign-In was cancelled.');
          }
          rethrow;
        }
      }

      final user = userCredential.user;
      if (user == null) throw Exception('Apple Sign-In returned null user');

      final email = user.email;
      final displayName = user.displayName?.trim();
      final uid = user.uid;

      AppLogger.d('✅ Apple Sign-In successful!');
      AppLogger.d('👤 Name: $displayName | Email: $email | UID: $uid');

      await _ensureProfileInFirestore(uid, email, displayName);

      final mapped = _mapFirebaseUser(user);
      return AuthUser(
        id: uid,
        email: email,
        displayName: displayName ?? mapped?.displayName,
        isAnonymous: user.isAnonymous,
      );
    } catch (e, stackTrace) {
      AppLogger.d('❌ Apple Sign-In failed: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<void> _ensureProfileInFirestore(
      String uid, String? email, String? displayName) async {
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('ensureUserProfile');
      await callable.call<void>().timeout(const Duration(seconds: 2));
      AppLogger.d('Profile reconciled for authenticated UID $uid');
      return;
    } catch (e) {
      AppLogger.d('Profile reconciliation function unavailable: $e');
    }

    try {
      final profileRef = _firestore.collection('profiles').doc(uid);
      final snapshot =
          await profileRef.get().timeout(const Duration(seconds: 2));
      final profileName = (displayName != null && displayName.trim().isNotEmpty)
          ? displayName.trim()
          : (email != null &&
                  email.contains('@') &&
                  email.split('@').first.isNotEmpty)
              ? email.split('@').first
              : 'Hunter';
      if (snapshot.exists) {
        final currentName = snapshot.data()?['name'] as String?;
        if ((currentName == null ||
                currentName == 'Hunter' ||
                currentName == 'New Hunter') &&
            profileName != 'Hunter') {
          await profileRef.update({
            'name': profileName,
            if (email != null) 'email': email,
          }).timeout(const Duration(seconds: 2));
        }
        return;
      }

      await profileRef.set({
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
        'isPremium': false,
      }).timeout(const Duration(seconds: 2));
    } catch (e) {
      AppLogger.d('Error ensuring UID profile: $e');
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('deleteUserAccount');
      await callable.call();
      AppLogger.d('✅ Account deletion function invoked successfully for ${user.uid}');
    } catch (e) {
      AppLogger.e('Cloud deleteUserAccount failed, attempting client fallback deletion: $e');
      // Fallback: Delete profile doc and auth user if function call failed
      try {
        await _firestore.collection('profiles').doc(user.uid).delete();
        await user.delete();
      } catch (err) {
        AppLogger.e('Client fallback deletion failed: $err');
        rethrow;
      }
    }
  }

  @override
  Future<AuthUser?> get currentUser async =>
      _mapFirebaseUser(_auth.currentUser);

  @override
  Future<void> ensureTechnicalSession() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _ensureProfileInFirestore(user.uid, user.email, user.displayName);
    }
  }

  @override
  bool get isMock => false;

  @override
  Future<String> signUpSilent(String email, String password) async {
    // On mobile Firebase, just do regular signup — the race is less severe
    // because the Firebase SDK manages the auth state stream internally.
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user!.uid;
  }

  @override
  void emitAuthState() {
    // No-op on mobile — Firebase SDK auto-emits via authStateChanges stream
  }
}
