import 'package:flutter/material.dart';

class AppTheme {
  // Official Havenly Solutions Palette
  static const primaryRed      = Color(0xFFC0392B);
  static const deepNavy        = Color(0xFF1A1A2E);
  static const communityGreen  = Color(0xFF0B6E4F);
  static const authorityGold   = Color(0xFFD4A017);
  static const backgroundCream = Color(0xFFF9F9F9);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: false,
      scaffoldBackgroundColor: Colors.white,
      primaryColor: primaryRed,
      colorScheme: const ColorScheme.light(
        primary: primaryRed,
        secondary: deepNavy,
        surface: Colors.white,
        background: Colors.white,
        error: primaryRed,
      ),
      fontFamily: 'DM Sans',
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Space Grotesk', fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontFamily: 'Space Grotesk', fontWeight: FontWeight.bold),
        titleLarge: TextStyle(fontFamily: 'Space Grotesk', fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(fontFamily: 'DM Sans'),
        bodyMedium: TextStyle(fontFamily: 'DM Sans'),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: false,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121212),
      primaryColor: primaryRed,
      colorScheme: const ColorScheme.dark(
        primary: primaryRed,
        secondary: authorityGold,
        surface: Color(0xFF1E1E1E),
        background: Color(0xFF121212),
      ),
      fontFamily: 'DM Sans',
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Space Grotesk', fontWeight: FontWeight.bold, color: Colors.white),
        titleLarge: TextStyle(fontFamily: 'Space Grotesk', fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }
}
