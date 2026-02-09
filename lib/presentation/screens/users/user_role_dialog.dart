import 'package:flutter/material.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_design_tokens.dart';
import 'package:holyverso/core/theme/app_text_styles.dart';
import 'package:holyverso/domain/roles/user_role.dart';
import 'package:holyverso/domain/roles/user_with_role.dart';
import 'package:holyverso/presentation/widgets/common/holy_bottom_sheet.dart';

class UserRoleDialog extends StatefulWidget {
  const UserRoleDialog({
    super.key,
    required this.user,
  });

  final UserWithRole user;

  @override
  State<UserRoleDialog> createState() => _UserRoleDialogState();
}

class _UserRoleDialogState extends State<UserRoleDialog> {
  late UserRole _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.user.role;
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.7;

    return HolyBottomSheet(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cambiar role',
              style: AppTextStyles.headline3.copyWith(
                color: AppColors.holyGold,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.user.displayName,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.pureWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              widget.user.email,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.softMist.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Role actual: ${widget.user.role.displayName}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.softMist.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                child: Column(
                  children: UserRole.values
                      .map(
                        (role) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.sm,
                          ),
                          child: _RoleOption(
                            role: role,
                            isSelected: role == _selectedRole,
                            onTap: () => setState(() => _selectedRole = role),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selectedRole == widget.user.role
                    ? null
                    : () => Navigator.pop(context, _selectedRole),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.holyGold,
                  foregroundColor: AppColors.midnightFaith,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Guardar'),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.holyGold,
              ),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.role,
    required this.isSelected,
    required this.onTap,
  });

  final UserRole role;
  final bool isSelected;
  final VoidCallback onTap;

  IconData _iconForRole() {
    return switch (role) {
      UserRole.admin => Icons.shield_outlined,
      UserRole.lead => Icons.groups_outlined,
      UserRole.editor => Icons.edit_outlined,
      UserRole.user => Icons.person_outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? AppColors.holyGold
        : AppColors.pureWhite.withValues(alpha: 0.12);
    final iconColor = isSelected
        ? AppColors.holyGold
        : AppColors.softMist.withValues(alpha: 0.8);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.pureWhite.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.holyGold.withValues(alpha: 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.pureWhite.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: iconColor.withValues(alpha: 0.6),
                ),
              ),
              child: Icon(_iconForRole(), color: iconColor, size: 22),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.displayName,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.pureWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role.description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.softMist.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.holyGold,
              ),
          ],
        ),
      ),
    );
  }
}
