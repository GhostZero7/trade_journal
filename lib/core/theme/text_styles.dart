import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTextStyles {
  // Main large page titles
  static const heading1 = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  // Section titles
  static const heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Small section subtitles / form titles
  static const heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  // Standard text
  static const body = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  // Secondary text (less important)
  static const bodySecondary = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  // Button text
  static const button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
}
