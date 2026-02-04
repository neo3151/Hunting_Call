import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'injection_container.dart' as di;
import 'core/theme/theme_notifier.dart';
import 'features/auth/presentation/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
            theme: themeNotifier.currentTheme,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

