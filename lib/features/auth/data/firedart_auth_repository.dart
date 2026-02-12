import 'package:flutter/foundation.dart';
import 'package:firedart/firedart.dart';
import 'dart:async';
import '../domain/repositories/auth_repository.dart';
import '../domain/entities/auth_user.dart';

class FiredartAuthRepository implements AuthRepository {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  
  /// Stores the ID of the user we are "impersonating" for this session.
  String? _impersonatedUserId;

  final _authStateController = StreamController<AuthUser?>.broadcast();

  FiredartAuthRepository() {
    _auth.signInState.listen((isSignedIn) {
      _emitCurrentState();
    });
  }

  void _emitCurrentState() {
     // This is tricky because we need to return AuthUser, but _impersonatedUserId is just a String.
     // If we are impersonating, we assume we are that user.
     // We return a basic AuthUser with the ID.
    final user = _createCurrentAuthUser();
    debugPrint("FiredartAuth: Emitting state - user: ${user?.id}");
    _authStateController.add(user);
  }

  AuthUser? _createCurrentAuthUser() {
     if (_impersonatedUserId != null) {
         return AuthUser(id: _impersonatedUserId!);
     }
     
     if (_auth.isSignedIn) {
         // Return the technical user
         return AuthUser(id: _auth.userId, isAnonymous: true);
     }
     
     return null;
  }

  @override
  Stream<AuthUser?> get authStateChanges {
    // Return a stream that emits the current logical state first, then all subsequent updates
    late StreamController<AuthUser?> controller;
    
    controller = StreamController<AuthUser?>(
      onListen: () {
        final initial = _createCurrentAuthUser();
        debugPrint("FiredartAuth: authStateChanges listened. Sending current: ${initial?.id}");
        controller.add(initial);
        
        final subscription = _authStateController.stream.listen(
          (data) {
            if (!controller.isClosed) {
              controller.add(data);
            }
          },
          onDone: () => controller.close(),
          onError: (e) => controller.addError(e),
        );
        
        controller.onCancel = () => subscription.cancel();
      }
    );
    
    return controller.stream;
  }

  @override
  Future<void> signIn(String userId) async {
    debugPrint("FiredartAuth: signIn (impersonate) requested for $userId");
    
    if (!_auth.isSignedIn) {
      debugPrint("FiredartAuth: No technical session. Signing in anonymously first.");
      await signInAnonymously();
    }

    _impersonatedUserId = userId;
    debugPrint("FiredartAuth: Now impersonating $userId");
    _emitCurrentState();
  }

  @override
  Future<void> signInAnonymously() async {
    debugPrint("FiredartAuth: Technical anonymous sign-in requested.");
    await _auth.signInAnonymously();
    debugPrint("FiredartAuth: Technical anonymous sign-in complete. Waiting 500ms for session settlement.");
    await Future.delayed(const Duration(milliseconds: 500));
    _emitCurrentState();
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    throw UnimplementedError("Google Sign-In is not supported on Linux via Firedart yet.");
  }

  @override
  Future<void> signOut() async {
    debugPrint("FiredartAuth: signOut (clear impersonation) requested.");
    _impersonatedUserId = null; 
    
    _emitCurrentState();
    
    try {
      _auth.signOut();
    } catch (e) {
      debugPrint("FiredartAuth: Error during technical signOut: $e");
    }
    
    debugPrint("FiredartAuth: Performing immediate technical anonymous re-auth for future use.");
    await signInAnonymously();
  }

  @override
  Future<AuthUser?> get currentUser async {
    return _createCurrentAuthUser();
  }

  @override
  bool get isMock => false;
}
