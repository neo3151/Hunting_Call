import 'package:flutter/material.dart';

/// Centralized color constants for the OUTCALL app.
///
/// Use these instead of hardcoded `Color(0xFF...)` literals throughout the codebase.
/// This ensures visual consistency and makes theme changes trivial.
class AppColors {
  AppColors._(); // prevent instantiation

  // ─── Backgrounds ─────────────────────────────────────────────────────────────
  static const background = Color(0xFF121212);
  static const surface = Color(0xFF1A1A1A);
  static const surfaceLight = Color(0xFF2A2D33);
  static const surfaceDark = Color(0xFF15181D);

  // ─── Text ────────────────────────────────────────────────────────────────────
  static const textPrimary = Colors.white;
  static const textSecondary = Colors.white70;
  static const textTertiary = Colors.white54;
  static const textSubtle = Colors.white38;

  // ─── Accent ──────────────────────────────────────────────────────────────────
  static const accentBlue = Color(0xFF3A86FF);
  static const accentGold = Color(0xFFE8922D);
  static const accentGoldLight = Color(0xFFF0B860);
  static const accentGoldDark = Color(0xFF8B5A1B);

  // ─── Status ──────────────────────────────────────────────────────────────────
  static const success = Color(0xFF5FF7B6);
  static const warning = Color(0xFFFFD54F);
  static const error = Color(0xFFFF5252);

  // ─── Scoring ─────────────────────────────────────────────────────────────────
  static Color scoreColor(num? score) {
    if (score == null) return textTertiary;
    if (score >= 85) return success;
    if (score >= 70) return const Color(0xFF4FC3F7);
    if (score >= 50) return warning;
    return error;
  }
}
