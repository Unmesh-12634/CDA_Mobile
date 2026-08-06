import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Triple-Font Typography System defined in Stitch Design Spec:
/// - Headlines / Display: Hanken Grotesk
/// - Body Copy: Inter
/// - Labels / Codes / Scores: JetBrains Mono
abstract class AppTypography {
  static TextStyle get displayLarge => const TextStyle(
        fontFamily: 'Hanken Grotesk',
        fontFamilyFallback: ['Roboto', 'Arial', 'sans-serif'],
        fontSize: 32,
        fontWeight: FontWeight.bold,
        height: 40 / 32,
        color: AppColors.onSurface,
      );

  static TextStyle get displayMobile => const TextStyle(
        fontFamily: 'Hanken Grotesk',
        fontFamilyFallback: ['Roboto', 'Arial', 'sans-serif'],
        fontSize: 28,
        fontWeight: FontWeight.bold,
        height: 36 / 28,
        color: AppColors.onSurface,
      );

  static TextStyle get headlineMedium => const TextStyle(
        fontFamily: 'Hanken Grotesk',
        fontFamilyFallback: ['Roboto', 'Arial', 'sans-serif'],
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 32 / 24,
        color: AppColors.onSurface,
      );

  static TextStyle get headlineSmall => const TextStyle(
        fontFamily: 'Hanken Grotesk',
        fontFamilyFallback: ['Roboto', 'Arial', 'sans-serif'],
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 28 / 20,
        color: AppColors.onSurface,
      );

  static TextStyle get headlineMobile => const TextStyle(
        fontFamily: 'Hanken Grotesk',
        fontFamilyFallback: ['Roboto', 'Arial', 'sans-serif'],
        fontSize: 24,
        fontWeight: FontWeight.bold,
        height: 1.25,
        color: AppColors.onSurface,
      );

  static TextStyle get bodyLarge => const TextStyle(
        fontFamily: 'Inter',
        fontFamilyFallback: ['Roboto', 'Arial', 'sans-serif'],
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
        color: AppColors.onSurface,
      );

  static TextStyle get bodyMedium => const TextStyle(
        fontFamily: 'Inter',
        fontFamilyFallback: ['Roboto', 'Arial', 'sans-serif'],
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        color: AppColors.onSurface,
      );

  static TextStyle get bodySmall => const TextStyle(
        fontFamily: 'Inter',
        fontFamilyFallback: ['Roboto', 'Arial', 'sans-serif'],
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 18 / 12,
        color: AppColors.onSurfaceVariant,
      );

  static TextStyle get titleMedium => const TextStyle(
        fontFamily: 'Inter',
        fontFamilyFallback: ['Roboto', 'Arial', 'sans-serif'],
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 24 / 16,
        color: AppColors.onSurface,
      );

  static TextStyle get labelMedium => const TextStyle(
        fontFamily: 'Inter',
        fontFamilyFallback: ['Roboto', 'Arial', 'sans-serif'],
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 16 / 12,
        letterSpacing: 0.2,
        color: AppColors.onSurfaceVariant,
      );

  static TextStyle get codeMono => const TextStyle(
        fontFamily: 'JetBrains Mono',
        fontFamilyFallback: ['Consolas', 'Courier New', 'monospace'],
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
        letterSpacing: 0.5,
        color: AppColors.onSurfaceVariant,
      );
}
