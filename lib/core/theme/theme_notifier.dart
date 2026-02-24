import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hunting_calls_perfection/features/settings/presentation/controllers/settings_controller.dart';
import 'package:hunting_calls_perfection/core/theme/app_theme.dart';

class ThemeNotifier extends Notifier<AppTheme> {
  @override
  AppTheme build() {
    final settingsAsync = ref.watch(settingsNotifierProvider);
    return settingsAsync.maybeWhen(
      data: (settings) => settings.theme,
      orElse: () => AppTheme.classic,
    );
  }

  Color _getSeedColor() {
    switch (state) {
      case AppTheme.classic:
        return const Color(0xFFFF8C00);
      case AppTheme.midnight:
        return const Color(0xFF3A86FF);
      case AppTheme.forest:
        return const Color(0xFF2ECC71);
      case AppTheme.hunter:
        return const Color(0xFFE74C3C);
    }
  }

  ThemeData get lightTheme {
    final seedColor = _getSeedColor();
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF9F9F9),
      primaryColor: seedColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        primary: seedColor,
        brightness: Brightness.light,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: const TextStyle(fontSize: 16.0),
        ),
      ),
    );
  }

  ThemeData get darkTheme {
    final seedColor = _getSeedColor();
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF0D0D0D),
      primaryColor: seedColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        primary: seedColor,
        brightness: Brightness.dark,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: const TextStyle(fontSize: 16.0),
        ),
      ),
    );
  }
  
  // Keep currentTheme for backwards compatibility if used elsewhere directly
  ThemeData get currentTheme => darkTheme; 
}

final themeNotifierProvider = NotifierProvider<ThemeNotifier, AppTheme>(() {
  return ThemeNotifier();
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  final settingsAsync = ref.watch(settingsNotifierProvider);
  return settingsAsync.maybeWhen(
    data: (settings) => settings.themeMode,
    orElse: () => ThemeMode.system,
  );
});
