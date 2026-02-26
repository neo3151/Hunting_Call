import 'package:firebase_core/firebase_core.dart';
import 'package:firedart/firedart.dart' as fd;
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:outcall/features/auth/data/firedart_file_store.dart';
import 'package:outcall/firebase_options.dart';
import 'package:outcall/features/hunting_log/data/local_hunting_log_repository.dart';
import 'package:outcall/core/utils/app_logger.dart';

/// Whether Firebase (or Firedart on Linux) is available.
/// Set during [init] and read by [main_common.dart] to build [PlatformEnvironment].
bool isFirebaseEnabled = false;

bool _isInitializing = false;

/// Initializes platform-specific services that must run before the widget tree:
///   - Firedart auth & Firestore on Linux
///   - SQLite FFI on desktop
///   - HuntingLog database tables
///
/// **Note:** DI registrations have been migrated to Riverpod providers in
/// `di_providers.dart`. This file no longer uses GetIt.
Future<void> init({bool useMocks = false}) async {
  if (_isInitializing) return;
  _isInitializing = true;

  // In test mode, skip all real platform services
  if (useMocks) {
    isFirebaseEnabled = false;
    _isInitializing = false;
    return;
  }

  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  // Check if Firebase is actually initialized (has apps)
  isFirebaseEnabled = false;
  
  final bool isDesktop = Platform.isLinux || Platform.isWindows || Platform.isMacOS;
  if (isDesktop) {
    try {
      const options = DefaultFirebaseOptions.windows; 
      final appDir = await getApplicationSupportDirectory();
      if (!appDir.existsSync()) {
        await appDir.create(recursive: true);
      }
      final tokenFile = File(p.join(appDir.path, 'auth_token.json'));
      AppLogger.d('Firebase: Using token file at ${tokenFile.path}');
      
      fd.FirebaseAuth.initialize(options.apiKey, FiredartFileStore(tokenFile.path));
      fd.Firestore.initialize(options.projectId);
      
      // Auto-sign in anonymously on desktop if not already signed in 
      final auth = fd.FirebaseAuth.instance;
      if (!auth.isSignedIn) {
        AppLogger.d('Firebase: Performing initial anonymous sign-in on desktop...');
        await auth.signInAnonymously();
      }
      
      // Wait a bit to ensure Firestore/Auth state is synchronized
      int authRetries = 10;
      while (!auth.isSignedIn && authRetries > 0) {
        AppLogger.d('Firebase: Waiting for auth synchronization... ($authRetries left)');
        await Future.delayed(const Duration(milliseconds: 100));
        authRetries--;
      }
      
      AppLogger.d('Firebase: Final startup sign-in check - isSignedIn: ${auth.isSignedIn}, userId: ${auth.userId}');
      
      isFirebaseEnabled = auth.isSignedIn;
      AppLogger.d('Firebase: Firedart initialized with FileStore for desktop. isEnabled: $isFirebaseEnabled');
    } catch (e) {
      AppLogger.d('Firebase: Firedart initialization failed: $e');
      isFirebaseEnabled = false;
    }
  } else {
    try {
      isFirebaseEnabled = Firebase.apps.isNotEmpty;
    } catch (e) {
      AppLogger.d('Firebase apps check failed: $e');
      isFirebaseEnabled = false;
    }
  }

  AppLogger.d('DI Initializing: isFirebaseEnabled = $isFirebaseEnabled');

  // Initialize HuntingLog database tables eagerly
  try {
    final huntingLogRepo = LocalHuntingLogRepository();
    await huntingLogRepo.initialize();
  } catch (e) {
    AppLogger.d('HuntingLog DB init failed: $e');
  }

  _isInitializing = false;
}
