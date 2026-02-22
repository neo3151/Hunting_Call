
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hunting_calls_perfection/firebase_options.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:hunting_calls_perfection/injection_container.dart' as di;
import 'package:hunting_calls_perfection/di_providers.dart';
import 'package:hunting_calls_perfection/core/theme/theme_notifier.dart';
import 'package:hunting_calls_perfection/features/splash/presentation/splash_screen.dart';
import 'package:hunting_calls_perfection/features/library/data/reference_database.dart';
import 'package:hunting_calls_perfection/features/auth/domain/repositories/auth_repository.dart';
import 'package:hunting_calls_perfection/features/auth/data/firedart_auth_repository.dart';
import 'package:hunting_calls_perfection/config/app_config.dart';
import 'package:hunting_calls_perfection/core/utils/app_logger.dart';
import 'package:hunting_calls_perfection/core/widgets/global_error_view.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void mainCommon() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  // Explicitly allow all orientations (important for tablets)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  // Initialize Reference Database
  await ReferenceDatabase.init();

  // Initialize Firebase
  bool firebaseReady = false;
  try {
    // AppLogger.d("🔥 Firebase: Attempting initialization... Platform.isLinux=${Platform.isLinux}");
    if (!Platform.isLinux) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      // Initialize App Check (Prevent database scraping/abuse)
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
      );
      
      firebaseReady = true;
      // AppLogger.d("✅ Firebase: Initialized successfully. Apps count: ${Firebase.apps.length}");
    } else {
      // AppLogger.d("🐧 Firebase: Skipping official init on Linux (using Firedart).");
    }

  } catch (e, stackTrace) {
      AppLogger.d("❌ Firebase: Initialization failed. Entering 'Off-Grid' mode.");
      AppLogger.d('Error: $e');
      AppLogger.d('Stack: $stackTrace');
      AppLogger.d("Note: To enable Cloud Sync, add your google-services.json/GoogleService-Info.plist and run 'flutterfire configure'.");
  }
  
  // Global Error Handling — route to Crashlytics if available
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppLogger.d('GLOBAL FLUTTER ERROR: ${details.exception}');
    if (firebaseReady && (Platform.isAndroid || Platform.isIOS)) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    }
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    // Send background analytics
    if (firebaseReady && (Platform.isAndroid || Platform.isIOS)) {
      FirebaseCrashlytics.instance.recordFlutterError(details);
    }
    return GlobalErrorView(details: details);
  };

  // Catch async errors that escape the widget tree
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.d('GLOBAL ASYNC ERROR: $error\n$stack');
    if (firebaseReady && (Platform.isAndroid || Platform.isIOS)) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
    return true; // Prevent app crash
  };

  // Initialize Firedart (Linux only) + HuntingLog DB via injection_container
  await di.init();
  
  // Create and initialize the auth repository early (needs async init for session file)
  AuthRepository? preInitAuthRepo;
  if (Platform.isLinux && di.isFirebaseEnabled) {
    final firedartAuth = FiredartAuthRepository();
    await firedartAuth.initialize();
    preInitAuthRepo = firedartAuth;
    // AppLogger.d("FiredartAuth: Repository created and initialized.");
  }
  
  // Create the platform environment for Riverpod DI
  final sharedPreferences = await SharedPreferences.getInstance();
  final env = PlatformEnvironment(
    isFirebaseEnabled: di.isFirebaseEnabled,
    isLinux: Platform.isLinux,
    useMocks: false,
    sharedPreferences: sharedPreferences,
    preInitializedAuthRepo: preInitAuthRepo,
  );

  // Background cleanup of old recordings
  try {
    // Access cleanup after ProviderScope is available — defer to post-frame
  } catch (e) {
    AppLogger.d('Startup: Cleanup failed: $e');
  }

  runApp(ProviderScope(
    overrides: [
      platformEnvironmentProvider.overrideWithValue(env),
    ],
    child: const HuntingCallsApp(),
  ));
}

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
    // Defer cleanup to after the first frame renders
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
    // Watch the theme state so MaterialApp rebuilds on theme change
    ref.watch(themeNotifierProvider);
    final themeNotifier = ref.read(themeNotifierProvider.notifier);
    
    return MaterialApp(
      title: AppConfig.instance.appName,
      debugShowCheckedModeBanner: false,
      theme: themeNotifier.lightTheme,
      darkTheme: themeNotifier.darkTheme,
      themeMode: ThemeMode.system, // Auto-switch based on system settings
      home: const SplashScreen(),
    );
  }
}

