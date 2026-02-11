import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/domain/roles/user_role.dart';
import 'package:holyverso/presentation/state/roles/role_provider.dart';

class RoleGuard extends ConsumerWidget {
  const RoleGuard({
    super.key,
    required this.child,
    required this.allowedRoles,
    this.fallback,
  });

  final Widget child;
  final List<UserRole> allowedRoles;
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(myRoleProvider);

    return roleAsync.when(
      data: (role) {
        if (allowedRoles.contains(role)) {
          return child;
        }
        return fallback ?? const SizedBox.shrink();
      },
      loading: () => fallback ?? const SizedBox.shrink(),
      error: (_, stackTrace) => fallback ?? const SizedBox.shrink(),
    );
  }
}
