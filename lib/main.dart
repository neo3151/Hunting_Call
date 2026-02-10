import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'injection_container.dart' as di;
import 'core/theme/theme_notifier.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'features/library/data/reference_database.dart';
import 'features/recording/domain/audio_recorder_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  // Initialize Reference Database
  await ReferenceDatabase.init();
  
  // Initialize Firebase
  try {
    debugPrint("🔥 Firebase: Attempting initialization... Platform.isLinux=${Platform.isLinux}");
    if (!Platform.isLinux) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint("✅ Firebase: Initialized successfully. Apps count: ${Firebase.apps.length}");
    } else {
      debugPrint("🐧 Firebase: Skipping official init on Linux (using Firedart).");
    }

  } catch (e, stackTrace) {
    debugPrint("❌ Firebase: Initialization failed. Entering 'Off-Grid' mode.");
    debugPrint("Error: $e");
    debugPrint("Stack: $stackTrace");
    debugPrint("Note: To enable Cloud Sync, add your google-services.json/GoogleService-Info.plist and run 'flutterfire configure'.");
  }
  
  // Global Error Handling for better stability and debugging
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint("GLOBAL FLUTTER ERROR: ${details.exception}");
    // Here you could send errors to Sentry or Firebase Crashlytics
  };

  // Catch async errors that escape the widget tree
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint("GLOBAL ASYNC ERROR: $error\n$stack");
    return true; // Prevent app crash
  };

  await di.init();
  
  // Background cleanup of old recordings
  try {
    final recorderService = di.sl<AudioRecorderService>();
    recorderService.cleanupOldFiles();
  } catch (e) {
    debugPrint("Startup: Cleanup failed: $e");
  }

  runApp(const ProviderScope(child: HuntingCallsApp()));
}

class HuntingCallsApp extends ConsumerWidget {
  const HuntingCallsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeNotifier = ref.read(themeNotifierProvider.notifier);
    
    return MaterialApp(
      title: 'Hunting Calls Perfection',
      debugShowCheckedModeBanner: false,
      theme: themeNotifier.currentTheme,
      home: const SplashScreen(),
    );
  }
}
