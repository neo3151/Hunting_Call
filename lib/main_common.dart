import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:outcall/firebase_options.dart';
import 'dart:io';
import 'package:outcall/injection_container.dart' as di;
import 'package:outcall/di_providers.dart';
import 'package:outcall/core/theme/theme_notifier.dart';
import 'package:outcall/features/splash/presentation/splash_screen.dart';
import 'package:outcall/features/library/data/reference_database.dart';
import 'package:outcall/features/auth/domain/repositories/auth_repository.dart';
import 'package:outcall/features/auth/data/firedart_auth_repository.dart';
import 'package:outcall/config/app_config.dart';
import 'package:outcall/core/utils/app_logger.dart';
import 'package:outcall/core/widgets/global_error_view.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

Future<void> mainCommon() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await _configurePlatform();
  await ReferenceDatabase.init();

  final firebaseReady = await _initFirebase();
  _setupErrorHandling(firebaseReady);

  // Initialize Firedart (desktop) + HuntingLog DB via injection_container
  await di.init();

  final env = await _createPlatformEnvironment(firebaseReady);

  runApp(
    ProviderScope(
      overrides: [
        platformEnvironmentProvider.overrideWithValue(env),
        AppConfig.provider.overrideWithValue(AppConfig.instance),
      ],
      child: const HuntingCallsApp(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Private helpers — extracted for readability, logic unchanged
// ---------------------------------------------------------------------------

/// Allow all orientations (important for tablets).
Future<void> _configurePlatform() async {
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  // NOTE: sqfliteFfiInit() is handled inside di.init() — no duplicate call here.
}

/// Initialize Firebase + App Check on mobile. Returns false on desktop or failure.
Future<bool> _initFirebase() async {
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) return false;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
    );
    return true;
  } catch (e, st) {
    AppLogger.e('Firebase init failed', e, st);
    return false;
  }
}

/// Wire up global error handlers, routing to Crashlytics when available.
void _setupErrorHandling(bool firebaseReady) {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (firebaseReady && (Platform.isAndroid || Platform.isIOS)) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    }
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (firebaseReady && (Platform.isAndroid || Platform.isIOS)) {
      FirebaseCrashlytics.instance.recordFlutterError(details);
    }
    return GlobalErrorView(details: details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.e('Uncaught async error', error, stack);
    if (firebaseReady && (Platform.isAndroid || Platform.isIOS)) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
    return true;
  };
}

/// Build the [PlatformEnvironment], optionally initializing Firedart auth.
Future<PlatformEnvironment> _createPlatformEnvironment(bool firebaseReady) async {
  final prefs = await SharedPreferences.getInstance();
  final isDesktop = Platform.isLinux || Platform.isWindows || Platform.isMacOS;
  AuthRepository? preInitAuthRepo;

  if (isDesktop && di.isFirebaseEnabled) {
    final firedartAuth = FiredartAuthRepository();
    await firedartAuth.initialize();
    preInitAuthRepo = firedartAuth;
  }

  return PlatformEnvironment(
    isFirebaseEnabled: di.isFirebaseEnabled,
    isLinux: isDesktop,
    useMocks: false,
    sharedPreferences: prefs,
    preInitializedAuthRepo: preInitAuthRepo,
  );
}

// ---------------------------------------------------------------------------
// Root widget
// ---------------------------------------------------------------------------

class HuntingCallsApp extends ConsumerStatefulWidget {
  const HuntingCallsApp({super.key});

  @override
  ConsumerState<HuntingCallsApp> createState() => _HuntingCallsAppState();
}

class _HuntingCallsAppState extends ConsumerState<HuntingCallsApp> {
  bool _cleanupDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_cleanupDone) {
        _cleanupDone = true;
        _cleanupOldRecordings();
      }
    });
  }

  void _cleanupOldRecordings() {
    try {
      final recorderService = ref.read(audioRecorderServiceProvider);
      recorderService.cleanupOldFiles();
    } catch (e) {
      AppLogger.d('Startup: Cleanup failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeNotifierProvider);
    final themeNotifier = ref.read(themeNotifierProvider.notifier);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: AppConfig.instance.appName,
      debugShowCheckedModeBanner: false,
      theme: themeNotifier.lightTheme,
      darkTheme: themeNotifier.darkTheme,
      themeMode: themeMode,
      home: const SplashScreen(),
    );
  }
}
