import 'dart:async';
import '../domain/repositories/auth_repository.dart';
import '../domain/entities/auth_user.dart';
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
}
