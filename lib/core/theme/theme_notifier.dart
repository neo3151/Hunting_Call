import 'package:flutter/material.dart';

class ThemeNotifier extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeData get currentTheme => _isDarkMode ? _darkTheme : _lightTheme;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  static final _lightTheme = ThemeData(
    primarySwatch: Colors.green,
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF5F7F2),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E7D32),
      brightness: Brightness.light,
    ),
  );

  static final _darkTheme = ThemeData(
    primarySwatch: Colors.green,
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF1B1B1B),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF66BB6A), // Lighter green for dark mode
      brightness: Brightness.dark,
    ),
  );
}
