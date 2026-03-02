import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outcall/features/settings/presentation/controllers/settings_controller.dart';
import 'package:outcall/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final textTheme = GoogleFonts.interTextTheme(ThemeData.light().textTheme);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF9F9F9),
      primaryColor: seedColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        primary: seedColor,
        brightness: Brightness.light,
      ),
      textTheme: textTheme.apply(
        bodyColor: const Color(0xFF1A1A1A),
        displayColor: const Color(0xFF1A1A1A),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF4A4A4A)),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
        titleTextStyle: GoogleFonts.oswald(
          color: const Color(0xFF1A1A1A),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      listTileTheme: const ListTileThemeData(
        textColor: Color(0xFF1A1A1A),
        iconColor: Color(0xFF4A4A4A),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE0E0E0),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: seedColor,
        unselectedItemColor: const Color(0xFF777777),
        selectedIconTheme: IconThemeData(color: seedColor),
        unselectedIconTheme: const IconThemeData(color: Color(0xFF999999)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return seedColor;
          return const Color(0xFFBBBBBB);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return seedColor.withValues(alpha: 0.3);
          return const Color(0xFFE0E0E0);
        }),
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
    final textTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0D0D0D),
      primaryColor: seedColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        primary: seedColor,
        brightness: Brightness.dark,
      ),
      textTheme: textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white70),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.oswald(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      listTileTheme: const ListTileThemeData(
        textColor: Colors.white,
        iconColor: Colors.white70,
      ),
      dividerTheme: const DividerThemeData(
        color: Colors.white12,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1A1A1A),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF121212),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        selectedIconTheme: IconThemeData(color: seedColor),
        unselectedIconTheme: const IconThemeData(color: Colors.white54),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return seedColor;
          return Colors.white54;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return seedColor.withValues(alpha: 0.3);
          return Colors.white12;
        }),
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
