import 'package:flutter/material.dart';
import 'package:holy_mobile/core/theme/app_colors.dart';
import 'package:holy_mobile/core/theme/app_design_tokens.dart';
import 'package:holy_mobile/core/theme/app_text_styles.dart';

/// Single setting row with icon, title, and trailing control.
class SettingTile extends StatelessWidget {
  const SettingTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppBorderRadius.input,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.sm,
        ),
        constraints: const BoxConstraints(minHeight: 60),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.holyGold,
              size: AppSizes.iconMedium,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.pureWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.softMist.withOpacity(0.8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right,
                  color: AppColors.softMist.withOpacity(0.8),
                ),
          ],
        ),
      ),
    );
  }
}
