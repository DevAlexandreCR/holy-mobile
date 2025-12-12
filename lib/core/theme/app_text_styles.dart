import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// HolyVerso Typography System
/// Based on HolyVerso_UIUX.md guidelines
class AppTextStyles {
  AppTextStyles._();

  // Base fonts
  static TextStyle get _interBase => GoogleFonts.inter();
  static TextStyle get _satoshiBase => GoogleFonts.inter(
    fontWeight: FontWeight.w500,
  ); // Using Inter Medium as Satoshi fallback

  // Headlines (Verse of the day - Satoshi Medium equivalent)
  static TextStyle get headline1 => _satoshiBase.copyWith(
    fontSize: 28,
    height: 1.4, // 140% line height
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w500,
  );

  static TextStyle get headline2 => _satoshiBase.copyWith(
    fontSize: 24,
    height: 1.35,
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w500,
  );

  static TextStyle get headline3 => _satoshiBase.copyWith(
    fontSize: 22,
    height: 1.3,
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w500,
  );

  // Body text (Inter Regular/Medium)
  static TextStyle get bodyLarge => _interBase.copyWith(
    fontSize: 16,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodyMedium => _interBase.copyWith(
    fontSize: 14,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodySmall => _interBase.copyWith(
    fontSize: 12,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  // Labels and UI text
  static TextStyle get labelLarge => _interBase.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static TextStyle get labelMedium => _interBase.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static TextStyle get labelSmall => _interBase.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  // Reference text (Golden)
  static TextStyle get reference => _interBase.copyWith(
    fontSize: 14,
    color: AppColors.holyGold,
    fontWeight: FontWeight.w500,
  );

  static TextStyle get referenceSmall =>
      _interBase.copyWith(fontSize: 12, color: AppColors.holyGold);

  // Button text
  static TextStyle get button => _interBase.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.015,
  );

  // Caption
  static TextStyle get caption =>
      _interBase.copyWith(fontSize: 12, color: AppColors.textMuted);
}
