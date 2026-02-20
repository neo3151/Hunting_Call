import 'dart:io';
import 'package:firedart/firedart.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../domain/repositories/auth_repository.dart';
import '../domain/entities/auth_user.dart';
import 'package:hunting_calls_perfection/core/utils/app_logger.dart';

class FiredartAuthRepository implements AuthRepository {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  
  /// Whether the user has an active session (explicitly logged in).
  /// Persisted to disk so it survives app restarts.
  bool _hasActiveSession = false;

  /// Path to the session marker file.
  String? _sessionFilePath;

  final _authStateController = StreamController<AuthUser?>.broadcast();

  FiredartAuthRepository() {
    // Synchronous constructor — session state loaded lazily or via initialize()
    _auth.signInState.listen((isSignedIn) {
      // Only emit if we have an active session — ignore technical session changes
      if (_hasActiveSession) {
        _emitCurrentState();
      }
    });
  }
  
  /// Call this after construction to load persisted session state.
  /// If not called, defaults to no active session (shows LoginScreen).
  Future<void> initialize() async {
    try {
      final appDir = await getApplicationSupportDirectory();
      _sessionFilePath = p.join(appDir.path, 'session_active');
      final sessionFile = File(_sessionFilePath!);
      
      if (sessionFile.existsSync() && _auth.isSignedIn) {
        // User was previously logged in and session persists
        _hasActiveSession = true;
        AppLogger.d('FiredartAuth: Restored session for user ${_auth.userId}');
      } else {
        _hasActiveSession = false;
        AppLogger.d('FiredartAuth: No active session found — will show login.');
      }
    } catch (e) {
      AppLogger.d('FiredartAuth: Error loading session state: $e');
      _hasActiveSession = false;
    }
  }
  
  void _setSessionActive(bool active) {
    _hasActiveSession = active;
    if (_sessionFilePath != null) {
      try {
        final file = File(_sessionFilePath!);
        if (active) {
          file.writeAsStringSync('active');
        } else if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (e) {
        AppLogger.d('FiredartAuth: Error persisting session state: $e');
      }
    }
  }

  void _emitCurrentState() {
    final user = _createCurrentAuthUser();
    AppLogger.d('FiredartAuth: Emitting state - user: ${user?.id}');
    _authStateController.add(user);
  }

  AuthUser? _createCurrentAuthUser() {
    if (!_hasActiveSession || !_auth.isSignedIn) return null;
    return AuthUser(id: _auth.userId);
  }

  @override
  Stream<AuthUser?> get authStateChanges {
    late StreamController<AuthUser?> controller;
    
    controller = StreamController<AuthUser?>(
      onListen: () {
        final initial = _createCurrentAuthUser();
        AppLogger.d('FiredartAuth: authStateChanges listened. Sending current: ${initial?.id}');
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
    // Deprecated insecure method - we'll just sign in anonymously for now
    // to maintain some level of compatibility strictly for technical sessions
    AppLogger.d('FiredartAuth: DEPRECATED signIn (impersonate) called for $userId. Using anonymous instead.');
    await signInAnonymously();
  }

  @override
  Future<void> signInAnonymously() async {
    AppLogger.d('FiredartAuth: Anonymous sign-in requested.');
    await _ensureTechnicalSession(forceRefresh: true);
    _setSessionActive(true);
    AppLogger.d('FiredartAuth: Signed in as anonymous user: ${_auth.userId}');
    _emitCurrentState();
  }

  @override
  Future<void> signInWithEmail(String email, String password) async {
    AppLogger.d('FiredartAuth: Email sign-in requested for $email');
    await _auth.signIn(email, password);
    _setSessionActive(true);
    AppLogger.d('FiredartAuth: Signed in as ${_auth.userId}');
    _emitCurrentState();
  }

  @override
  Future<void> signUpWithEmail(String email, String password) async {
    AppLogger.d('FiredartAuth: Email sign-up requested for $email');
    await _auth.signUp(email, password);
    _setSessionActive(true);
    AppLogger.d('FiredartAuth: Signed up as ${_auth.userId}');
    _emitCurrentState();
  }

  @override
  Future<String> signUpSilent(String email, String password) async {
    AppLogger.d('FiredartAuth: SILENT email sign-up requested for $email');
    await _auth.signUp(email, password);
    _setSessionActive(true);
    final uid = _auth.userId;
    AppLogger.d('FiredartAuth: Silent sign-up complete. UID: $uid (auth state NOT emitted)');
    return uid;
  }

  @override
  void emitAuthState() {
    AppLogger.d('FiredartAuth: Manual auth state emission requested.');
    _emitCurrentState();
  }
  
  /// Ensures a technical Firedart session exists (for Firestore access).
  /// If [forceRefresh] is true, signs out first to get a fresh token.
  Future<void> _ensureTechnicalSession({bool forceRefresh = false}) async {
    if (forceRefresh && _auth.isSignedIn) {
      AppLogger.d('FiredartAuth: Force-refreshing technical session...');
      try {
        _auth.signOut();
      } catch (e) {
        AppLogger.d('FiredartAuth: signOut during refresh failed (ignoring): $e');
      }
    }
    if (!_auth.isSignedIn) {
      AppLogger.d('FiredartAuth: Creating technical anonymous session...');
      await _auth.signInAnonymously();
      AppLogger.d('FiredartAuth: Technical session created. Waiting 500ms for settlement.');
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  @override
  Future<void> ensureTechnicalSession() async {
    // Creates a firedart session for Firestore access WITHOUT
    // setting _hasActiveSession or _impersonatedUserId.
    // This means no auth state is emitted → AuthWrapper doesn't rebuild.
    if (!_auth.isSignedIn) {
      AppLogger.d('FiredartAuth: Creating silent technical session for Firestore access...');
      await _auth.signInAnonymously();
      AppLogger.d('FiredartAuth: Silent technical session created.');
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    throw UnimplementedError('Google Sign-In is not supported on Linux via Firedart yet.');
  }

  @override
  Future<void> signOut() async {
    AppLogger.d('FiredartAuth: signOut requested.');
    _setSessionActive(false);
    
    // Also sign out of firedart to invalidate the technical session
    // so the next login gets a fresh token
    try {
      if (_auth.isSignedIn) {
        _auth.signOut();
        AppLogger.d('FiredartAuth: Technical session also signed out.');
      }
    } catch (e) {
      AppLogger.d('FiredartAuth: Technical signOut failed (ignoring): $e');
    }
    
    // Emit null immediately so AuthWrapper shows LoginScreen
    _emitCurrentState();
    
    AppLogger.d('FiredartAuth: Sign-out complete.');
  }

  @override
  Future<AuthUser?> get currentUser async {
    return _createCurrentAuthUser();
  }

  @override
  bool get isMock => false;
}
