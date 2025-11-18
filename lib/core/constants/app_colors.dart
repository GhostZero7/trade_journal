import 'package:flutter/material.dart';
// core/constants/app_colors.dart
// core/constants/app_colors.dart
class AppColors {
  final Color primary;
  final Color accent;
  final Color secondary;
  final Color background;
  final Color cardDark;
  final Color textLight;
  final Color textFaded;
  final Color success;
  final Color error;
  final Color textPrimary;   // Add this
  final Color textSecondary; // Add this

  const AppColors({
    required this.primary,
    required this.accent,
    required this.secondary,
    required this.background,
    required this.cardDark,
    required this.textLight,
    required this.textFaded,
    required this.success,
    required this.error,
    required this.textPrimary,
    required this.textSecondary,
  });

  // Dark theme
  static const AppColors dark = AppColors(
    primary: Color(0xFF00FF80),
    accent: Color(0xFF40C4FF),
    secondary: Color(0xFFFF4545),
    background: Color(0xFF121212),
    cardDark: Color(0xFF1E1E1E),
    textLight: Color(0xFFE0E0E0),
    textFaded: Color(0xFF888888),
    success: Color(0xFF00FF80),
    error: Color(0xFFFF4545),
    textPrimary: Color(0xFFE0E0E0),   // Same as textLight for dark theme
    textSecondary: Color(0xFF888888), // Same as textFaded for dark theme
  );

  // Light theme
  static const AppColors light = AppColors(
    primary: Color(0xFF00C853),
    accent: Color(0xFF2979FF),
    secondary: Color(0xFFFF1744),
    background: Color(0xFFFAFAFA),
    cardDark: Color(0xFFFFFFFF),
    textLight: Color(0xFF212121),
    textFaded: Color(0xFF757575),
    success: Color(0xFF00C853),
    error: Color(0xFFFF1744),
    textPrimary: Color(0xFF212121),   // Same as textLight for light theme
    textSecondary: Color(0xFF757575), // Same as textFaded for light theme
  );
}