import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false; // Default to light mode (matching previous _isDarkMode = false)
  }

  void toggleTheme() {
    state = !state;
  }

  ThemeData get currentTheme => state ? darkTheme : lightTheme;

  static final lightTheme = ThemeData(
    primarySwatch: Colors.green,
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF5F7F2),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E7D32),
      brightness: Brightness.light,
    ),
  );

  static final darkTheme = ThemeData(
    primarySwatch: Colors.green,
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF1B1B1B),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF66BB6A),
      brightness: Brightness.dark,
    ),
  );
}

final themeNotifierProvider = NotifierProvider<ThemeNotifier, bool>(() {
  return ThemeNotifier();
});
