import 'package:flutter/material.dart';

/// HolyVerso Official Brand Colors
/// Based on HolyVerso_Branding.md
class AppColors {
  AppColors._();

  // Primary Colors
  /// Holy Gold - #F4D27A
  /// Used for accents, highlights, and spiritual emphasis
  static const Color holyGold = Color(0xFFF4D27A);

  /// Midnight Faith - #1A2940
  /// Primary dark background color
  static const Color midnightFaith = Color(0xFF1A2940);

  /// Midnight Faith Dark - #121A2A
  /// Darker variant for gradients and depth
  static const Color midnightFaithDark = Color(0xFF121A2A);

  /// Pure White - #FFFFFF
  /// For clarity and primary text
  static const Color pureWhite = Color(0xFFFFFFFF);

  /// Morning Light - #7EA9E1
  /// Soft blue for secondary elements
  static const Color morningLight = Color(0xFF7EA9E1);

  /// Soft Mist - #D7DCE3
  /// Neutral gray for UI elements
  static const Color softMist = Color(0xFFD7DCE3);

  // Functional Colors
  /// Success color (soft gold)
  static const Color success = Color(0xFFF4D27A);

  /// Warning color (intense gold)
  static const Color warning = Color(0xFFD4AF37);

  /// Error color (burnt gold to maintain spirituality)
  static const Color error = Color(0xFFC8943C);

  // Text Colors
  static const Color textPrimary = pureWhite;
  static const Color textSecondary = softMist;
  static const Color textMuted = Color(0xFFB0B0B0);

  // UI State Colors
  static const Color inputBackground = Color(0xFF27241B);
  static const Color inputBorder = Color(0xFF544E3B);
  static const Color inputPlaceholder = Color(0xFFBAB29C);

  // Shadows & Overlays
  static const Color shadowDark = Color(0x80000000);
  static const Color overlayLight = Color(0x1AFFFFFF);

  // Gradients
  static LinearGradient get midnightGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [midnightFaithDark, midnightFaith],
  );

  static LinearGradient get widgetGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      midnightFaithDark.withValues(alpha: 0.9),
      midnightFaith.withValues(alpha: 0.8),
    ],
  );
}
