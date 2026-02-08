import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/data/roles/role_repository.dart';
import 'package:holyverso/domain/roles/user_role.dart';
import 'package:holyverso/presentation/state/auth/auth_controller.dart';

final myRoleProvider = FutureProvider<UserRole>((ref) async {
  final authState = ref.watch(authControllerProvider);
  if (!authState.isAuthenticated) {
    return UserRole.user;
  }

  try {
    return await ref.read(roleRepositoryProvider).getMyRole();
  } catch (_) {
    return UserRole.user;
  }
});

final isAdminProvider = Provider<bool>((ref) {
  final roleAsync = ref.watch(myRoleProvider);
  return roleAsync.maybeWhen(
    data: (role) => role.isAdmin,
    orElse: () => false,
  );
});

final canManageUsersProvider = Provider<bool>((ref) {
  final roleAsync = ref.watch(myRoleProvider);
  return roleAsync.maybeWhen(
    data: (role) => role.canManageUsers,
    orElse: () => false,
  );
});
