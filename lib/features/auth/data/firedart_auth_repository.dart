import 'package:flutter/foundation.dart';
import 'package:firedart/firedart.dart';
import 'dart:async';
import '../domain/auth_repository.dart';

class FiredartAuthRepository implements AuthRepository {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  
  /// Stores the ID of the user we are "impersonating" for this session.
  String? _impersonatedUserId;

  final _authStateController = StreamController<String?>.broadcast();

  FiredartAuthRepository() {
    _auth.signInState.listen((isSignedIn) {
      _emitCurrentState();
    });
  }

  void _emitCurrentState() {
    final uid = currentUserId; // This is now the Logical User (Impersonated)
    debugPrint("FiredartAuth: Emitting state - logicalUserId: $uid (technicalUserId: $authenticatedUserId)");
    _authStateController.add(uid);
  }

  @override
  Stream<String?> get onAuthStateChanged {
    // Return a stream that emits the current logical state first, then all subsequent updates
    late StreamController<String?> controller;
    
    controller = StreamController<String?>(
      onListen: () {
        final initial = currentUserId;
        debugPrint("FiredartAuth: onAuthStateChanged listened. Sending current logical: $initial");
        controller.add(initial);
        
        // Forward future events WITHOUT blocking
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
    // We DON'T automatically emit here because we haven't impersonated a profile yet.
    // Except if we ARE already impersonating something? 
    // Usually signInAnonymously is called at startup or on logout.
    _emitCurrentState();
  }

  @override
  Future<Map<String, String?>> signInWithGoogle() async {
    throw UnimplementedError("Google Sign-In is not supported on Linux via Firedart yet.");
  }

  @override
  Future<void> signOut() async {
    debugPrint("FiredartAuth: signOut (clear impersonation) requested.");
    _impersonatedUserId = null; 
    
    // We keep the technical session alive but clear the logical one
    _emitCurrentState();
    
    // Optional: Actually sign out techically and re-init for a fresh start?
    // The previous implementation did this. Let's keep it for cleanliness.
    try {
      _auth.signOut();
    } catch (e) {
      debugPrint("FiredartAuth: Error during technical signOut: $e");
    }
    
    debugPrint("FiredartAuth: Performing immediate technical anonymous re-auth for future use.");
    await signInAnonymously();
  }

  @override
  String? get currentUserId {
    // Return the impersonated ID only. 
    // This makes AuthWrapper think we are logged out until a profile is picked.
    return _impersonatedUserId;
  }

  @override
  String? get authenticatedUserId {
    try {
      if (!isSignedIn) return null;
      return _auth.userId;
    } catch (e) {
      return null;
    }
  }

  @override
  bool get isMock => false;

  bool get isSignedIn {
    try {
      return _auth.isSignedIn;
    } catch (e) {
      debugPrint("FiredartAuth: isSignedIn error: $e");
      return false;
    }
  }
}
