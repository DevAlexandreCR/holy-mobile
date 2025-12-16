import 'package:flutter/material.dart';

/// HolyVerso Design Tokens
/// Based on UI/UX Guidelines
class AppSpacing {
  AppSpacing._();

  // Spacing scale (8, 16, 24, 32px)
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppBorderRadius {
  AppBorderRadius._();

  // Border radius scale
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double full = 9999.0;

  // Common radius values
  static BorderRadius get card => BorderRadius.circular(lg);
  static BorderRadius get button => BorderRadius.circular(full);
  static BorderRadius get input => BorderRadius.circular(md);
}

class AppShadows {
  AppShadows._();

  // Soft shadow for cards
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 30,
      offset: const Offset(0, 4),
    ),
  ];

  // Gold glow for buttons
  static List<BoxShadow> get goldGlow => [
    BoxShadow(
      color: const Color(0xFFF4D27A).withValues(alpha: 0.3),
      blurRadius: 15,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: const Color(0xFFF4D27A).withValues(alpha: 0.2),
      blurRadius: 25,
      spreadRadius: 0,
    ),
  ];

  // Text shadow for verse
  static List<Shadow> get textGlow => [
    Shadow(
      color: Colors.black.withValues(alpha: 0.5),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];
}

class AppSizes {
  AppSizes._();

  // Button heights
  static const double buttonHeight = 52.0;
  static const double buttonHeightSmall = 44.0;

  // Input heights
  static const double inputHeight = 56.0;

  // Icon sizes
  static const double iconSmall = 20.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
}
