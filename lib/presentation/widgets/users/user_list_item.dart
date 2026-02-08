import 'package:flutter/material.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_design_tokens.dart';
import 'package:holyverso/core/theme/app_text_styles.dart';
import 'package:holyverso/domain/roles/user_with_role.dart';
import 'package:holyverso/presentation/widgets/users/role_badge.dart';

class UserListItem extends StatelessWidget {
  const UserListItem({
    super.key,
    required this.user,
    this.onTap,
  });

  final UserWithRole user;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final avatarLetter = user.displayName.isNotEmpty
        ? user.displayName[0].toUpperCase()
        : 'U';

    return InkWell(
      onTap: onTap,
      borderRadius: AppBorderRadius.card,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.pureWhite.withValues(alpha: 0.06),
          borderRadius: AppBorderRadius.card,
          border: Border.all(color: AppColors.pureWhite.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.holyGold.withValues(alpha: 0.2),
              child: Text(
                avatarLetter,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.holyGold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.pureWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.softMist.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            RoleBadge(role: user.role),
          ],
        ),
      ),
    );
  }
}
