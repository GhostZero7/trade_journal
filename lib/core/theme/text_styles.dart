// core/theme/text_styles.dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTextStyles {
  // Main large page titles
  static TextStyle heading1({Color? color}) => TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: color,
  );

  // Section titles
  static TextStyle heading2({Color? color}) => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: color,
  );

  // Small section subtitles / form titles
  static TextStyle heading3({Color? color}) => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: color,
  );

  // Standard text
  static TextStyle body({Color? color}) => TextStyle(
    fontSize: 16,
    color: color,
  );

  // Secondary text (less important)
  static TextStyle bodySecondary({Color? color}) => TextStyle(
    fontSize: 14,
    color: color,
  );

  // Button text
  static TextStyle button({Color? color}) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: color ?? Colors.white,
  );
}