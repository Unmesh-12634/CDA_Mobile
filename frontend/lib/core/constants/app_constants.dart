import 'package:flutter/material.dart';

abstract class AppConstants {
  static const String appName = 'CDA Career Companion';
  static const String academyFullName = 'Cranes Digital Academy';

  // Layout Spacing & Margins (Base 8px grid)
  static const double marginMobile = 20.0;
  static const double gutter = 16.0;
  static const double stackXs = 4.0;
  static const double stackSm = 8.0;
  static const double stackMd = 16.0;
  static const double stackLg = 24.0;
  static const double stackXl = 32.0;
  static const double stackXxl = 48.0;

  static const double paddingSm = 8.0;
  static const double paddingMd = 16.0;
  static const double paddingLg = 24.0;

  // Touch Target Minimums
  static const double minTouchTarget = 48.0;

  // Stitch Shape Radii
  static const double radiusSm = 8.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 24.0;
  static const double radiusXl = 32.0;

  static const BorderRadius borderRadiusSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius borderRadiusMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius borderRadiusLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius borderRadiusXl = BorderRadius.all(Radius.circular(radiusXl));

  // Animations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
}
