import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/data/roles/roles_api_client.dart';
import 'package:holyverso/domain/roles/user_role.dart';
import 'package:holyverso/domain/roles/user_with_role.dart';
import 'package:holyverso/domain/roles/users_list_result.dart';

class RoleRepository {
  RoleRepository(this._client);

  final RolesApiClient _client;

  Future<UserRole> getMyRole() {
    return _client.getMyRole();
  }

  Future<UsersListResult> getUsersList({
    int page = 1,
    int limit = 20,
    String? search,
    UserRole? roleFilter,
  }) {
    return _client.getUsersList(
      page: page,
      limit: limit,
      search: search,
      roleFilter: roleFilter,
    );
  }

  Future<void> updateUserRole({
    required String userId,
    required UserRole role,
  }) {
    return _client.updateUserRole(userId: userId, role: role);
  }

  Future<UserWithRole> blockUser({
    required String userId,
    required String reason,
  }) {
    return _client.blockUser(userId: userId, reason: reason);
  }

  Future<UserWithRole> unblockUser({
    required String userId,
    required String reason,
  }) {
    return _client.unblockUser(userId: userId, reason: reason);
  }
}

final roleRepositoryProvider = Provider<RoleRepository>((ref) {
  return RoleRepository(ref.watch(rolesApiClientProvider));
});
