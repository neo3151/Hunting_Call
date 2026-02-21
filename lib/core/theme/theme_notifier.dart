import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/settings/presentation/controllers/settings_controller.dart';
import 'app_theme.dart';

class ThemeNotifier extends Notifier<AppTheme> {
  @override
  AppTheme build() {
    final settingsAsync = ref.watch(settingsNotifierProvider);
    return settingsAsync.maybeWhen(
      data: (settings) => settings.theme,
      orElse: () => AppTheme.classic,
    );
  }

  ThemeData get currentTheme {
    switch (state) {
      case AppTheme.classic:
        return _buildTheme(const Color(0xFFFF8C00));
      case AppTheme.midnight:
        return _buildTheme(const Color(0xFF3A86FF));
      case AppTheme.forest:
        return _buildTheme(const Color(0xFF2ECC71));
      case AppTheme.hunter:
        return _buildTheme(const Color(0xFFE74C3C));
    }
  }

  ThemeData _buildTheme(Color seedColor) {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF0D0D0D),
      primaryColor: seedColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        primary: seedColor,
        brightness: Brightness.dark,
      ),
    );
  }
}

final themeNotifierProvider = NotifierProvider<ThemeNotifier, AppTheme>(() {
  return ThemeNotifier();
});
