import 'package:flutter/material.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_design_tokens.dart';
import 'package:holyverso/core/theme/app_text_styles.dart';

/// Primary HolyVerso action button with glow and pill shape.
class HolyButton extends StatelessWidget {
  const HolyButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.fullWidth = true,
    this.leading,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool fullWidth;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.holyGold,
        foregroundColor: AppColors.midnightFaith,
        minimumSize: Size(
          fullWidth ? double.infinity : 0,
          AppSizes.buttonHeight,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.button,
        ),
        textStyle: AppTextStyles.button.copyWith(
          color: AppColors.midnightFaith,
          fontWeight: FontWeight.w700,
        ),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.midnightFaith),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: AppSpacing.sm),
                ],
                Text(label),
              ],
            ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppBorderRadius.button,
        boxShadow: AppShadows.goldGlow,
      ),
      child: ClipRRect(
        borderRadius: AppBorderRadius.button,
        child: button,
      ),
    );
  }
}
