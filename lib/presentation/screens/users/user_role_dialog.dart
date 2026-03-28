import 'package:flutter/material.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_design_tokens.dart';
import 'package:holyverso/core/theme/app_text_styles.dart';
import 'package:holyverso/domain/roles/user_management_action.dart';
import 'package:holyverso/domain/roles/user_role.dart';
import 'package:holyverso/domain/roles/user_with_role.dart';
import 'package:holyverso/presentation/widgets/common/holy_bottom_sheet.dart';

class UserRoleDialog extends StatefulWidget {
  const UserRoleDialog({super.key, required this.user});

  final UserWithRole user;

  @override
  State<UserRoleDialog> createState() => _UserRoleDialogState();
}

class _UserRoleDialogState extends State<UserRoleDialog> {
  late UserRole _selectedRole;
  final TextEditingController _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.user.role;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'Sin registro';
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year} $hour:$minute';
  }

  void _submitBlockAction() {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) return;

    Navigator.pop(
      context,
      widget.user.moderation.isBlocked
          ? UserManagementAction.unblock(reason)
          : UserManagementAction.block(reason),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.86;
    final moderation = widget.user.moderation;
    final isBlocked = moderation.isBlocked;

    return HolyBottomSheet(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gestionar usuario',
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
              const SizedBox(height: AppSpacing.md),
              _SectionCard(
                title: 'Rol',
                subtitle: 'Rol actual: ${widget.user.role.displayName}',
                child: Column(
                  children: UserRole.values
                      .map(
                        (role) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
              const SizedBox(height: AppSpacing.md),
              _SectionCard(
                title: 'Moderación',
                subtitle: isBlocked
                    ? 'La cuenta está bloqueada y no puede publicar ni comentar.'
                    : 'La cuenta no tiene bloqueo activo.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _StatusChip(
                          label: isBlocked ? 'Bloqueado' : 'Activo',
                          isDanger: isBlocked,
                        ),
                        if (moderation.blockedAt != null)
                          _MetaChip(
                            icon: Icons.schedule_outlined,
                            label:
                                'Bloqueado: ${_formatDate(moderation.blockedAt)}',
                          ),
                        if (moderation.unblockedAt != null)
                          _MetaChip(
                            icon: Icons.event_available_outlined,
                            label:
                                'Desbloqueado: ${_formatDate(moderation.unblockedAt)}',
                          ),
                      ],
                    ),
                    if (moderation.blockedReason != null &&
                        moderation.blockedReason!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      _ReasonTile(
                        label: 'Motivo del bloqueo',
                        value: moderation.blockedReason!,
                      ),
                    ],
                    if (moderation.blockedBy != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _ReasonTile(
                        label: 'Bloqueado por',
                        value:
                            '${moderation.blockedBy!.name} • ${moderation.blockedBy!.email}',
                      ),
                    ],
                    if (moderation.unblockedReason != null &&
                        moderation.unblockedReason!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _ReasonTile(
                        label: 'Motivo del desbloqueo',
                        value: moderation.unblockedReason!,
                      ),
                    ],
                    if (moderation.unblockedBy != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _ReasonTile(
                        label: 'Desbloqueado por',
                        value:
                            '${moderation.unblockedBy!.name} • ${moderation.unblockedBy!.email}',
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _reasonController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: isBlocked
                            ? 'Motivo del desbloqueo'
                            : 'Motivo del bloqueo',
                        filled: true,
                        fillColor: AppColors.inputBackground,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppBorderRadius.md,
                          ),
                          borderSide: BorderSide(
                            color: AppColors.inputBorder.withValues(alpha: 0.7),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppBorderRadius.md,
                          ),
                          borderSide: BorderSide(
                            color: isBlocked
                                ? AppColors.holyGold
                                : Colors.red.shade400,
                            width: 1.2,
                          ),
                        ),
                      ),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.pureWhite,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _submitBlockAction,
                        style: FilledButton.styleFrom(
                          backgroundColor: isBlocked
                              ? AppColors.holyGold
                              : Colors.red.shade600,
                          foregroundColor: isBlocked
                              ? AppColors.midnightFaith
                              : AppColors.pureWhite,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          isBlocked
                              ? 'Desbloquear usuario'
                              : 'Bloquear usuario',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _selectedRole == widget.user.role
                      ? null
                      : () => Navigator.pop(
                          context,
                          UserManagementAction.updateRole(_selectedRole),
                        ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.holyGold,
                    foregroundColor: AppColors.midnightFaith,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Guardar rol'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.holyGold,
                ),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.pureWhite.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.pureWhite.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.pureWhite,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.softMist.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _ReasonTile extends StatelessWidget {
  const _ReasonTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.softMist.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.pureWhite),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, this.isDanger = false});

  final String label;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDanger
        ? Colors.red.shade900.withValues(alpha: 0.26)
        : AppColors.holyGold.withValues(alpha: 0.16);
    final foregroundColor = isDanger ? Colors.red.shade100 : AppColors.holyGold;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foregroundColor.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.pureWhite.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.softMist),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.softMist),
          ),
        ],
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
                border: Border.all(color: iconColor.withValues(alpha: 0.6)),
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
            if (isSelected) Icon(Icons.check_circle, color: AppColors.holyGold),
          ],
        ),
      ),
    );
  }
}
