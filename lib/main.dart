import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'injection_container.dart' as di;
import 'core/theme/theme_notifier.dart';
import 'features/auth/presentation/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const HuntingCallsApp());
}

class HuntingCallsApp extends StatelessWidget {
  const HuntingCallsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: Consumer<ThemeNotifier>(
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

