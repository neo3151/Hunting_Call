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
    primarySwatch: Colors.orange,
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFFF8C00),
      brightness: Brightness.dark,
    ),
  );

  static final darkTheme = ThemeData(
    primarySwatch: Colors.orange,
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF0D0D0D),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFFF8C00),
      brightness: Brightness.dark,
    ),
  );
}

final themeNotifierProvider = NotifierProvider<ThemeNotifier, bool>(() {
  return ThemeNotifier();
});
