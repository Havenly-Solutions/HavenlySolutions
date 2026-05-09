import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();
  static const Color _primary = Color(0xFF00BFA5);
  static const Color _background = Color(0xFF0A0A0A);
  static const Color _surface = Color(0xFF141414);
  static const Color _onSurface = Color(0xFFE0E0E0);
  static const Color _error = Color(0xFFCF6679);
  static final ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _background,
    primaryColor: _primary,
    colorScheme: const ColorScheme.dark(
      primary: _primary,
      secondary: _primary,
      surface: _surface,
      onSurface: _onSurface,
      error: _error,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _background,
      foregroundColor: _onSurface,
      elevation: 0,
      centerTitle: true,
    ),
    useMaterial3: true,
  );
}
