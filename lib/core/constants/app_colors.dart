import 'package:flutter/material.dart';

/// Central color palette for FinMate.
/// Kept deliberately minimal per the design system: dark green primary,
/// white background, light green accent, dark grey text.
class AppColors {
  AppColors._();

  // Primary — Dark Green
  static const Color primary = Color(0xFF1B4D3E);
  static const Color primaryDark = Color(0xFF123529);
  static const Color primaryLight = Color(0xFF2E6E58);

  // Accent — Light Green
  static const Color accent = Color(0xFF6FCF97);
  static const Color accentSoft = Color(0xFFE3F5EA);

  // Background
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color scaffoldGrey = Color(0xFFF7F8F9);

  // Text — Dark Grey
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Semantic
  static const Color income = Color(0xFF2E9E6B);
  static const Color expense = Color(0xFFE25C5C);
  static const Color warning = Color(0xFFE7A93B);
  static const Color error = Color(0xFFD64545);
  static const Color info = Color(0xFF4A90D9);

  // Card category tag colors (for pie charts / category chips)
  static const List<Color> categoryPalette = [
    Color(0xFF1B4D3E),
    Color(0xFF6FCF97),
    Color(0xFFE7A93B),
    Color(0xFF4A90D9),
    Color(0xFFE25C5C),
    Color(0xFF9B6BD6),
    Color(0xFF3FB6C4),
    Color(0xFFD98BB0),
  ];

  // Borders / dividers
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFEFF1F3);

  // Shadow
  static const Color shadow = Color(0x14000000);
}
