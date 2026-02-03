import 'dart:async';
import 'package:flutter/foundation.dart';
import '../domain/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  late final StreamController<String?> _controller;
  String? _currentUser;

  MockAuthRepository() {
    _controller = StreamController<String?>.broadcast(
      onListen: () {
        _controller.add(_currentUser);
      },
    );
    // Initial state is already null in _currentUser
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
