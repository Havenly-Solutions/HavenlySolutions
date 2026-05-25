import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand ──
  static const Color primary = Color(0xFFF97316); // Havenly orange
  static const Color primaryDark = Color(0xFFEA6C10);
  static const Color primaryLight = Color(0xFFFED7AA);
  static const Color danger = Color(0xFFDC2626); // SOS red
  static const Color dangerLight = Color(0xFFFEE2E2);
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFD97706);

  // ── Backgrounds ──
  static const Color scaffoldBg = Color(0xFFFFFFFF);
  static const Color surface1 = Color(0xFFF9FAFB);
  static const Color surface2 = Color(0xFFF3F4F6);
  static const Color surface3 = Color(0xFFE5E7EB);

  // ── Text ──
  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Borders ──
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderFocus = Color(0xFFF97316);
  static const Color divider = Color(0xFFD1D5DB);

  // ── Legacy aliases (keep for backward compat during migration) ──
  static const Color black = Color(0xFF111111);
  static const Color white = Color(0xFFFFFFFF);

  static const Color primaryOrange = primary;
  static const Color primaryOrangeLight = primaryLight;
  static const Color background = scaffoldBg;
  static const Color surface = surface1;
  static const Color darkNav = black;
  static const Color textMuted = textDisabled;
  static const Color emergency = danger;
  static const Color green = success;
  static const Color communityGreen = success;
  static const Color authorityGold = Color(0xFFFFCC00);
  static const Color backgroundLight = scaffoldBg;
  static const Color surfaceCard = surface1;
  static const Color orange = primary;
  static const Color grey = surface2;
  static const Color brandDeep = primaryDark;
}
