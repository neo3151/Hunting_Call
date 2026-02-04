import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    primaryColor: const Color(0xFF5FF7B6),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF5FF7B6),
      secondary: Color(0xFF8BB781),
      surface: Color(0xFF1E1E1E),
      error: Color(0xFFCF6679),
    ),
    textTheme: GoogleFonts.latoTextTheme(ThemeData.dark().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: GoogleFonts.oswald(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    useMaterial3: true,
  );
}
