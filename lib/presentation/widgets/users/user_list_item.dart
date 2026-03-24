import 'package:flutter/material.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_design_tokens.dart';
import 'package:holyverso/core/theme/app_text_styles.dart';
import 'package:holyverso/domain/roles/user_with_role.dart';

class UserListItem extends StatelessWidget {
  const UserListItem({super.key, required this.user, this.onTap});

  final UserWithRole user;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final avatarLetter = user.displayName.isNotEmpty
        ? user.displayName[0].toUpperCase()
        : 'U';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 8,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.inputBorder.withValues(alpha: 0.8),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.holyGold.withValues(alpha: 0.6),
                      width: 1.2,
                    ),
                  ),
                  child: CircleAvatar(
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
                ),
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.holyGold,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.midnightFaith,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
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
                  const SizedBox(height: 6),
                  Text(
                    user.role.displayName,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.holyGold.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.softMist.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}
