import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:firebase_core/firebase_core.dart';
import 'injection_container.dart' as di;
import 'core/theme/theme_notifier.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'features/library/data/reference_database.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Reference Database
  await ReferenceDatabase.init();
  
  // Initialize Firebase
  try {
    debugPrint("Firebase: Attempting initialization...");
    await Firebase.initializeApp();
    debugPrint("Firebase: Initialized successfully.");
  } catch (e) {
    debugPrint("Firebase: Initialization failed. Entering 'Off-Grid' mode.");
    debugPrint("Note: To enable Cloud Sync, add your google-services.json/GoogleService-Info.plist and run 'flutterfire configure'.");
  }
  
  // Global Error Handling for better stability and debugging
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint("GLOBAL FLUTTER ERROR: ${details.exception}");
    // Here you could send errors to Sentry or Firebase Crashlytics
  };

  await di.init();
  runApp(const ProviderScope(child: HuntingCallsApp()));
}

class HuntingCallsApp extends StatelessWidget {
  const HuntingCallsApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Keep legacy Provider for ThemeNotifier during migration
    return legacy_provider.ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: legacy_provider.Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, child) {
          return MaterialApp(
            title: 'Hunting Calls Perfection',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
