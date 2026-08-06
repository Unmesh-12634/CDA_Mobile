import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../constants/app_typography.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        surfaceContainerLowest: AppColors.surfaceContainerLowest,
        surfaceContainerLow: AppColors.surfaceContainerLow,
        surfaceContainer: AppColors.surfaceContainer,
        surfaceContainerHigh: AppColors.surfaceContainerHigh,
        surfaceContainerHighest: AppColors.surfaceContainerHighest,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
        error: AppColors.error,
        onError: AppColors.onPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface.withValues(alpha: 0.9),
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: AppTypography.headlineSmall.copyWith(color: AppColors.onSurface),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppConstants.borderRadiusLg,
          side: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(AppConstants.minTouchTarget),
          shape: const RoundedRectangleBorder(
            borderRadius: AppConstants.borderRadiusMd,
          ),
          textStyle: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: const OutlineInputBorder(
          borderRadius: AppConstants.borderRadiusMd,
          borderSide: BorderSide(color: AppColors.surfaceContainer, width: 1),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppConstants.borderRadiusMd,
          borderSide: BorderSide(color: AppColors.surfaceContainer, width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppConstants.borderRadiusMd,
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.outline),
      ),
    );
  }

  // ── CRED Neo-Noir Dark Theme ──────────────────────────────────────────────
  // Inspired by CRED's obsidian palette: near-black bg, midnight-navy surfaces,
  // subtle electric-blue borders, and high-contrast white text.
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // True CRED obsidian background — NOT a grey, almost pure black-blue
      scaffoldBackgroundColor: AppColors.credDarkBackground,

      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFF818CF8),          // soft indigo accent
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF4648D4),
        onPrimaryContainer: Colors.white,
        secondary: Color(0xFF38BDF8),         // electric cyan
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFF0EA5E9),
        surface: AppColors.credDarkCard,        // 0xFF141E2E — midnight card glass
        onSurface: Color(0xFFF1F5F9),             // near-white readable text
        surfaceContainerLowest: AppColors.credDarkBackground,
        surfaceContainerLow: AppColors.credDarkBase,
        surfaceContainer: AppColors.credDarkSurface,
        surfaceContainerHigh: AppColors.credDarkCard,
        surfaceContainerHighest: Color(0xFF1E2D47),
        outline: Color(0xFF94A3B8),
        outlineVariant: AppColors.credDarkBorder,
        error: Color(0xFFF87171),
        onError: Colors.white,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.credDarkBackground,
        foregroundColor: Color(0xFFF1F5F9),
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        surfaceTintColor: Colors.transparent,
      ),

      // Cards use the glass surface with a blue-tinted border
      cardTheme: const CardThemeData(
        color: AppColors.credDarkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppConstants.borderRadiusLg,
          side: BorderSide(
            color: AppColors.credDarkBorder,
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6B6EF9),
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(AppConstants.minTouchTarget),
          shape: const RoundedRectangleBorder(
            borderRadius: AppConstants.borderRadiusMd,
          ),
          textStyle: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF1E2D47),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: AppConstants.borderRadiusMd,
          borderSide: BorderSide(color: AppColors.credDarkBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppConstants.borderRadiusMd,
          borderSide: BorderSide(color: AppColors.credDarkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppConstants.borderRadiusMd,
          borderSide: BorderSide(color: Color(0xFF818CF8), width: 2),
        ),
        hintStyle: TextStyle(color: Color(0xFF64748B)),
      ),

      dividerColor: AppColors.credDarkBorder,
      dividerTheme: const DividerThemeData(
        color: AppColors.credDarkBorder,
        thickness: 1,
      ),
    );
  }
}
