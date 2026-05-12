import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: false,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF00BCD4),
      ),
      fontFamily: 'Roboto',
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: false,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00BCD4),
      ),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          color: Colors.white,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          color: Color(0xFFBDBDBD), // grey shade 400ish
          height: 1.6,
        ),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}