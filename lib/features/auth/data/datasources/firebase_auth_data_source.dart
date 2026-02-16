import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../models/auth_user_model.dart';
import 'auth_remote_data_source.dart';

class FirebaseAuthDataSource implements AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  GoogleSignIn? _googleSignIn;

  /// Whether the google_sign_in plugin is available on this platform.
  bool get _isGoogleSignInSupported => Platform.isAndroid || Platform.isIOS;

  FirebaseAuthDataSource({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance {
    // Only create GoogleSignIn on platforms that support it (Android/iOS).
    // On Windows/Linux/macOS, we use signInWithProvider instead.
    if (_isGoogleSignInSupported) {
      _googleSignIn = googleSignIn ?? GoogleSignIn();
    }
  }

  @override
  Stream<AuthUserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((user) {
      if (user == null) return null;
      return AuthUserModel.fromFirebaseUser(user);
    });
  }

  @override
  AuthUserModel? get currentUser {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return AuthUserModel.fromFirebaseUser(user);
  }

  @override
  Future<void> signIn(String userId) async {
    if (_firebaseAuth.currentUser == null) {
      await _firebaseAuth.signInAnonymously();
    }
  }

  @override
  Future<void> signInAnonymously() async {
    await _firebaseAuth.signInAnonymously();
  }

  @override
  Future<AuthUserModel> signInWithGoogle() async {
    try {
      if (_isGoogleSignInSupported && _googleSignIn != null) {
        // Mobile path: use google_sign_in plugin
        return await _signInWithGoogleMobile();
      } else {
        // Desktop path: use Firebase's signInWithProvider (OAuth popup)
        return await _signInWithGoogleDesktop();
      }
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow;
    }
  }

  /// Mobile Google Sign-In via the google_sign_in plugin.
  Future<AuthUserModel> _signInWithGoogleMobile() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
    
    if (googleUser == null) {
      throw Exception('Google Sign-In aborted by user');
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user == null) {
      throw Exception('Firebase Sign-In with Google failed');
    }

    return AuthUserModel.fromFirebaseUser(user);
  }

  /// Desktop Google Sign-In via Firebase's signInWithProvider (OAuth popup).
  Future<AuthUserModel> _signInWithGoogleDesktop() async {
    debugPrint('🔐 Desktop: Using signInWithProvider for Google Sign-In...');
    
    final googleProvider = GoogleAuthProvider();
    googleProvider.addScope('email');
    googleProvider.addScope('profile');

    final UserCredential userCredential = await _firebaseAuth.signInWithProvider(googleProvider);
    final user = userCredential.user;

    if (user == null) {
      throw Exception('Google Sign-In via provider returned null user');
    }

    debugPrint('✅ Desktop Google Sign-In successful: ${user.displayName} (${user.email})');
    return AuthUserModel.fromFirebaseUser(user);
  }

  @override
  Future<void> signOut() async {
    // Only call google sign-out on platforms that support it
    if (_isGoogleSignInSupported && _googleSignIn != null) {
      try {
        await _googleSignIn!.signOut();
      } catch (e) {
        debugPrint('GoogleSignIn.signOut failed (non-critical): $e');
      }
    }
    await _firebaseAuth.signOut();
  }
}
