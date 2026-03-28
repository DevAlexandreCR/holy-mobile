import 'package:holyverso/domain/roles/user_role.dart';

enum UserManagementActionType { updateRole, block, unblock }

class UserManagementAction {
  const UserManagementAction.updateRole(this.role)
    : type = UserManagementActionType.updateRole,
      reason = null;

  const UserManagementAction.block(this.reason)
    : type = UserManagementActionType.block,
      role = null;

  const UserManagementAction.unblock(this.reason)
    : type = UserManagementActionType.unblock,
      role = null;

  final UserManagementActionType type;
  final UserRole? role;
  final String? reason;
}
