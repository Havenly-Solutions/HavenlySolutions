import 'package:flutter/material.dart';

class AppTheme {
  static const Color sapsNavyBlue    = Color(0xFF002366);
  static const Color sapsGold        = Color(0xFFFFD700);
  static const Color sapsDarkBlue    = Color(0xFF001A4D);
  static const Color sapsRed         = Color(0xFFCC0000);
  static const Color surfaceWhite    = Color(0xFFFFFFFF);
  static const Color surfaceGrey     = Color(0xFFF4F6FA);
  static const Color surfaceCard     = Color(0xFFF0F3F8);
  static const Color textPrimary     = Color(0xFF0D1B2A);
  static const Color textSecondary   = Color(0xFF4A5568);
  static const Color textMuted       = Color(0xFF8A9BB0);
  static const Color borderColor     = Color(0xFFDDE3EE);
  static const Color successGreen    = Color(0xFF1A7A4A);
  static const Color warningAmber    = Color(0xFFD97706);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: surfaceGrey,
      primaryColor: sapsNavyBlue,
      appBarTheme: const AppBarTheme(
        backgroundColor: sapsNavyBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: sapsNavyBlue,
        foregroundColor: Colors.white,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: sapsNavyBlue,
        primary: sapsNavyBlue,
        secondary: sapsGold,
        surface: surfaceWhite,
        error: sapsRed,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFFF4F6FA),
      primaryColor: const Color(0xFF002366),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF002366),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF002366),
        foregroundColor: Colors.white,
      ),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF002366),
        secondary: sapsGold,
        surface: surfaceWhite,
        background: Color(0xFFF4F6FA),
      ),
    );
  }
}
