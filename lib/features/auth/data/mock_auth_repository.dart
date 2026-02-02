import 'dart:async';
import 'package:flutter/foundation.dart';
import '../domain/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  final _controller = StreamController<String?>.broadcast();
  String? _currentUser;

  MockAuthRepository() {
    // Start with no user
    _controller.add(null);
  }

  @override
  Stream<String?> get onAuthStateChanged => _controller.stream;

  @override
  Future<void> signIn(String userId) async {
    _currentUser = userId;
    _controller.add(_currentUser);
    debugPrint("Mock Auth: Signed in as $_currentUser");
  }

  @override
  Future<void> signInAnonymously() async {
    _currentUser = "anon_user_123";
    _controller.add(_currentUser);
    debugPrint("Mock Auth: Signed in as $_currentUser");
  }

  @override
  Future<void> signInWithGoogle() async {
    _currentUser = "google_user_456";
    _controller.add(_currentUser);
    debugPrint("Mock Auth: Signed in with Google as $_currentUser");
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
    debugPrint("Mock Auth: Signed out");
  }
}
