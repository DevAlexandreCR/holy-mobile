import 'package:flutter/material.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_design_tokens.dart';
import 'package:holyverso/core/theme/app_text_styles.dart';

/// Input field styled with HolyVerso branding.
class HolyInputField extends StatelessWidget {
  const HolyInputField({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.onChanged,
    this.suffixIcon,
    this.enabled = true,
    this.autovalidateMode,
  });

  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;
  final bool enabled;
  final AutovalidateMode? autovalidateMode;

  OutlineInputBorder _buildBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: AppBorderRadius.input,
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      onChanged: onChanged,
      enabled: enabled,
      cursorColor: AppColors.holyGold,
      style: AppTextStyles.bodyLarge.copyWith(color: AppColors.pureWhite),
      autovalidateMode: autovalidateMode,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        filled: true,
        fillColor: AppColors.inputBackground,
        labelStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.softMist.withValues(alpha: 0.8),
          letterSpacing: 0.2,
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.inputPlaceholder.withValues(alpha: 0.8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        border: _buildBorder(AppColors.inputBorder.withValues(alpha: 0.8)),
        enabledBorder: _buildBorder(AppColors.inputBorder.withValues(alpha: 0.6)),
        focusedBorder: _buildBorder(AppColors.holyGold, width: 1.2),
        errorBorder: _buildBorder(AppColors.error),
        focusedErrorBorder: _buildBorder(AppColors.error, width: 1.2),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
