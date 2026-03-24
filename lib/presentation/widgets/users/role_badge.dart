import 'package:flutter/material.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_text_styles.dart';
import 'package:holyverso/domain/roles/user_role.dart';

class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.role});

  final UserRole role;

  Color _getRoleColor() {
    return switch (role) {
      UserRole.admin => AppColors.holyGold,
      UserRole.lead => AppColors.warning,
      UserRole.editor => AppColors.morningLight,
      UserRole.user => AppColors.softMist,
    };
  }

  IconData _getRoleIcon() {
    return switch (role) {
      UserRole.admin => Icons.admin_panel_settings,
      UserRole.lead => Icons.supervisor_account,
      UserRole.editor => Icons.edit,
      UserRole.user => Icons.person,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _getRoleColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getRoleIcon(), size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            role.displayName,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
