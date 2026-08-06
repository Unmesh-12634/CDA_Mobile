import 'package:flutter/material.dart';

abstract class AppColors {
  // Porcelain Light Theme Palette
  static const Color background = Color(0xFFF7F9FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF2F4F6);
  static const Color surfaceContainer = Color(0xFFECEEF0);
  static const Color surfaceContainerHigh = Color(0xFFE6E8EA);
  static const Color surfaceContainerHighest = Color(0xFFE0E3E5);

  // CRED Pure Obsidian Dark Theme Palette
  // Pure shiny obsidian black design language (CRED inspired)
  static const Color credDarkBackground = Color(0xFF030508);  // pure deep obsidian black
  static const Color credDarkBase      = Color(0xFF090D16);   // sleek midnight base
  static const Color credDarkSurface   = Color(0xFF0E1422);   // obsidian glass surface
  static const Color credDarkCard      = Color(0xFF121B2D);   // card elevation surface
  static const Color credDarkBorder    = Color(0xFF1E2D4A);   // metallic electric-blue border
  static const Color credDarkGlow      = Color(0xFF2D4268);   // ambient border glow

  // Primary & Secondary Accents
  static const Color primary = Color(0xFF4648D4);
  static const Color primaryContainer = Color(0xFF6063EE);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFFFFFFF);

  static const Color secondary = Color(0xFF006591);
  static const Color secondaryContainer = Color(0xFF39B8FD);
  static const Color onSecondary = Color(0xFFFFFFFF);

  static const Color tertiary = Color(0xFF904900);
  static const Color tertiaryContainer = Color(0xFFB55D00);

  // CRED Coin & Gold Accent
  static const Color credGold = Color(0xFFF59E0B);
  static const Color credNeonCyan = Color(0xFF0EA5E9);
  static const Color credEmerald = Color(0xFF10B981);
  static const Color credPurple = Color(0xFF6366F1);

  // Text & Ink Colors
  static const Color onSurface = Color(0xFF191C1E);
  static const Color onSurfaceVariant = Color(0xFF464554);
  static const Color outline = Color(0xFF767586);
  static const Color outlineVariant = Color(0xFFC7C4D7);
  static const Color cardBorder = Color(0xFFEEF2F5);
  static const Color glassBorder = Color(0xFFECEEF0);

  // Semantic Feedback Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4648D4), Color(0xFF6063EE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient credGoldGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient credNeonGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF818CF8), Color(0xFF4F46E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF7F9FB)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
