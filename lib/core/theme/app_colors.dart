import 'package:flutter/material.dart';

class AppColors {
  // Main Minimalist Palette
  static const Color primaryOrange      = Color(0xFFFF7A00); // Vibrant orange from reference
  static const Color primaryOrangeLight = Color(0xFFFF9D42);
  static const Color background         = Color(0xFFF8F8F8); // Clean off-white
  static const Color surface            = Color(0xFFFFFFFF);
  static const Color darkNav            = Color(0xFF1A1A1A); // Deeper black/grey
  static const Color textPrimary        = Color(0xFF1A1A1A);
  static const Color textSecondary      = Color(0xFF8E8E93); // iOS-style grey
  
  static const Color red                = Color(0xFFFF3B30); // Vibrant emergency red
  static const Color green              = Color(0xFF34C759); // Vibrant success green
  
  // Aliases for consistency
  static const Color emergency          = red;
  static const Color brandDeep          = darkNav;
  static const Color communityGreen     = green;
  static const Color authorityGold      = Color(0xFFFFCC00);
  static const Color backgroundLight    = background;
  static const Color surfaceCard        = surface;
  static const Color textMuted          = Color(0xFFC7C7CC);
  static const Color divider            = Color(0xFFE5E5EA);
  static const Color orange             = primaryOrange;
  static const Color white              = Color(0xFFFFFFFF);
  static const Color black              = Color(0xFF000000);
  static const Color grey               = Color(0xFFF2F2F7);

  // Styling Helpers
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}
