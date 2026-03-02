import 'package:flutter/material.dart';

/// Centralized color constants for the OUTCALL app.
///
/// Use `AppColors.of(context)` for theme-aware colors, or the static
/// constants for fixed brand colors.
class AppColors {
  AppColors._(); // prevent instantiation

  // ─── Theme-aware helper ───────────────────────────────────────────────────
  static AppColorPalette of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? _darkPalette
        : _lightPalette;
  }

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  // ─── Fixed Brand Colors ───────────────────────────────────────────────────
  static const accentBlue = Color(0xFF3A86FF);
  static const accentGold = Color(0xFFE8922D);
  static const accentGoldLight = Color(0xFFF0B860);
  static const accentGoldDark = Color(0xFF8B5A1B);

  // ─── Status ───────────────────────────────────────────────────────────────
  static const success = Color(0xFF5FF7B6);
  static const warning = Color(0xFFFFD54F);
  static const error = Color(0xFFFF5252);

  // ─── Scoring ──────────────────────────────────────────────────────────────
  static Color scoreColor(num? score) {
    if (score == null) return Colors.white54;
    if (score >= 85) return success;
    if (score >= 70) return const Color(0xFF4FC3F7);
    if (score >= 50) return warning;
    return error;
  }

  // ─── Palettes ─────────────────────────────────────────────────────────────
  static const _darkPalette = AppColorPalette(
    background: Color(0xFF121212),
    surface: Color(0xFF1A1A1A),
    surfaceLight: Color(0xFF2A2D33),
    surfaceDark: Color(0xFF15181D),
    textPrimary: Colors.white,
    textSecondary: Colors.white70,
    textTertiary: Colors.white54,
    textSubtle: Colors.white38,
    divider: Colors.white12,
    border: Color(0x1AFFFFFF), // white 10%
    icon: Colors.white70,
    iconSubtle: Colors.white38,
    cardOverlay: Color(0x0DFFFFFF), // white 5%
  );

  static const _lightPalette = AppColorPalette(
    background: Color(0xFFF9F9F9),
    surface: Color(0xFFFFFFFF),
    surfaceLight: Color(0xFFF0F0F0),
    surfaceDark: Color(0xFFE8E8E8),
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF4A4A4A),
    textTertiary: Color(0xFF777777),
    textSubtle: Color(0xFF999999),
    divider: Color(0xFFE0E0E0),
    border: Color(0x1A000000), // black 10%
    icon: Color(0xFF4A4A4A),
    iconSubtle: Color(0xFF999999),
    cardOverlay: Color(0x0D000000), // black 5%
  );

  // ─── Legacy static accessors (dark-only, for backwards compat) ────────────
  static const background = Color(0xFF121212);
  static const surface = Color(0xFF1A1A1A);
  static const surfaceLight = Color(0xFF2A2D33);
  static const surfaceDark = Color(0xFF15181D);
  static const textPrimary = Colors.white;
  static const textSecondary = Colors.white70;
  static const textTertiary = Colors.white54;
  static const textSubtle = Colors.white38;
}

/// A palette of colors that adapts to light/dark mode.
class AppColorPalette {
  final Color background;
  final Color surface;
  final Color surfaceLight;
  final Color surfaceDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textSubtle;
  final Color divider;
  final Color border;
  final Color icon;
  final Color iconSubtle;
  final Color cardOverlay;

  const AppColorPalette({
    required this.background,
    required this.surface,
    required this.surfaceLight,
    required this.surfaceDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textSubtle,
    required this.divider,
    required this.border,
    required this.icon,
    required this.iconSubtle,
    required this.cardOverlay,
  });
}
