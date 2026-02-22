import 'dart:async';
import 'package:hunting_calls_perfection/features/auth/domain/repositories/auth_repository.dart';
import 'package:hunting_calls_perfection/features/auth/domain/entities/auth_user.dart';
import 'package:hunting_calls_perfection/core/utils/app_logger.dart';

class MockAuthRepository implements AuthRepository {
  final _controller = StreamController<AuthUser?>.broadcast();
  AuthUser? _currentUser;

  MockAuthRepository() {
      // Initialize with no user
  }

  @override
  Stream<AuthUser?> get authStateChanges => _controller.stream;

  @override
  Future<AuthUser?> get currentUser async => _currentUser;

  @override
  Future<void> signIn(String userId) async {
    _currentUser = AuthUser(id: userId);
    _controller.add(_currentUser);
    AppLogger.d('Mock Auth: Signed in as ${_currentUser?.id}');
  }

  @override
  Future<void> signInAnonymously() async {
    _currentUser = const AuthUser(id: 'anon_user_123', isAnonymous: true);
    _controller.add(_currentUser);
    AppLogger.d('Mock Auth: Signed in as anon');
  }

  @override
  Future<void> signInWithEmail(String email, String password) async {
    _currentUser = AuthUser(id: 'email_user_789', email: email);
    _controller.add(_currentUser);
    AppLogger.d('Mock Auth: Signed in with email $email');
  }

  @override
  Future<void> signUpWithEmail(String email, String password) async {
    _currentUser = AuthUser(id: 'new_email_user_101', email: email);
    _controller.add(_currentUser);
    AppLogger.d('Mock Auth: Signed up with email $email');
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    AppLogger.d('Mock Auth: Password reset email requested for $email');
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    _currentUser = const AuthUser(
        id: 'google_user_456', 
        email: 'mock@example.com', 
        displayName: 'Mock User'
    );
    _controller.add(_currentUser);
    AppLogger.d('Mock Auth: Signed in with Google as ${_currentUser?.id}');
    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
    AppLogger.d('Mock Auth: Signed out');
  }

  @override
  Future<void> ensureTechnicalSession() async {
    // No-op for mock
  }

  @override
  bool get isMock => true;

  @override
  Future<String> signUpSilent(String email, String password) async {
    _currentUser = AuthUser(id: 'silent_user_999', email: email);
    // Don't emit — that's the point
    return _currentUser!.id;
  }

  @override
  void emitAuthState() {
    _controller.add(_currentUser);
  }
}
