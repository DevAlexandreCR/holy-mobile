import 'package:flutter/material.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_text_styles.dart';
import 'package:holyverso/domain/roles/user_role.dart';
import 'package:holyverso/domain/roles/user_with_role.dart';
import 'package:holyverso/presentation/widgets/users/role_badge.dart';

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

    return AlertDialog(
      backgroundColor: AppColors.midnightFaith,
      title: Text(
        'Cambiar role',
        style: AppTextStyles.headline3.copyWith(
          color: AppColors.pureWhite,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 8),
                Text(
                  'Role actual: ${widget.user.role.displayName}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.softMist.withValues(alpha: 0.9),
                  ),
                ),
                Divider(
                  height: 32,
                  color: AppColors.pureWhite.withValues(alpha: 0.15),
                ),
                Text(
                  'Seleccionar nuevo role:',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.pureWhite,
                  ),
                ),
                const SizedBox(height: 16),
                ...UserRole.values.map(
                  (role) => RadioListTile<UserRole>(
                    title: Text(
                      role.displayName,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.pureWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          role.description,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.softMist.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 6),
                        RoleBadge(role: role),
                      ],
                    ),
                    isThreeLine: true,
                    activeColor: AppColors.holyGold,
                    contentPadding: EdgeInsets.zero,
                    value: role,
                    groupValue: _selectedRole,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedRole = value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.holyGold,
          ),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _selectedRole == widget.user.role
              ? null
              : () => Navigator.pop(context, _selectedRole),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.holyGold,
            foregroundColor: AppColors.midnightFaith,
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
