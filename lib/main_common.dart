import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:outcall/features/hunting_log/data/local_hunting_log_repository.dart';
import 'package:outcall/di_providers.dart';
import 'package:outcall/core/theme/theme_notifier.dart';
import 'package:outcall/features/splash/presentation/splash_screen.dart';
import 'package:outcall/features/library/data/reference_database.dart';
import 'package:outcall/config/app_config.dart';
import 'package:outcall/core/utils/app_logger.dart';
import 'package:outcall/core/widgets/global_error_view.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:outcall/l10n/app_localizations.dart';
import 'package:outcall/core/services/analytics_service.dart';
import 'package:outcall/core/services/notification_service.dart';
import 'package:outcall/core/theme/app_colors.dart';
import 'package:outcall/features/settings/presentation/controllers/settings_controller.dart';

import 'package:outcall/core/services/simple_storage.dart';
import 'package:outcall/core/services/remote_config/remote_config_service.dart';
// removed revenuecat

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

Future<void> mainCommon() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await _configurePlatform();
  await ReferenceDatabase.init();

  final container = ProviderContainer(
    overrides: [
      AppConfig.provider.overrideWithValue(AppConfig.instance),
    ],
  );

  // Spin up and dynamically cache the platform environment dependencies (Firebase, etc.)
  final env = await container.read(asyncPlatformEnvironmentProvider.future);

  _setupErrorHandling(env.isFirebaseEnabled);

  // Initialize Remote Config for AI Coach and feature flags
  if (env.isFirebaseEnabled) {
    await container.read(remoteConfigServiceProvider).initialize();
  }

  // Initialize analytics
  if (env.isFirebaseEnabled) AnalyticsService.initialize();

  // Initialize push notifications
  if (env.isFirebaseEnabled) {
    final notifService = NotificationService(
      SharedPrefsStorage(env.sharedPreferences),
    );
    await notifService.initialize();
  }

  // Initialize Desktop sqlite
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize HuntingLog database tables eagerly
  try {
    final huntingLogRepo = LocalHuntingLogRepository();
    await huntingLogRepo.initialize();
  } catch (e) {
    AppLogger.d('HuntingLog DB init failed: $e');
  }

  // Phase 2: Eagerly start the offline outbox sync listener
  try {
    container.read(offlineSyncServiceProvider);
  } catch (e) {
    AppLogger.d('OfflineSyncService init failed: $e');
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
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

    // Wire up high-contrast mode from settings
    final settingsAsync = ref.watch(settingsNotifierProvider);
    settingsAsync.whenData((settings) {
      AppColors.setHighContrast(settings.highContrast);
    });

    return MaterialApp(
      title: AppConfig.instance.appName,
      debugShowCheckedModeBanner: false,
      theme: themeNotifier.lightTheme,
      darkTheme: themeNotifier.darkTheme,
      themeMode: themeMode,
      // Clamp text scaling to prevent layout overflow on large accessibility
      // settings, while still allowing moderate enlargement (up to 1.35x).
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final clampedScaler = mediaQuery.textScaler.clamp(
          minScaleFactor: 0.8,
          maxScaleFactor: 1.35,
        );
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: clampedScaler),
          child: child!,
        );
      },
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      navigatorObservers: [routeObserver],
      home: const SplashScreen(),
    );
  }
}
