import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/data/network/api_client.dart';
import 'package:holyverso/domain/roles/user_role.dart';
import 'package:holyverso/domain/roles/user_with_role.dart';
import 'package:holyverso/domain/roles/users_list_result.dart';

class RolesApiClient {
  RolesApiClient(this._dio);

  final Dio _dio;

  Future<UserRole> getMyRole() async {
    final response = await _dio.get('/roles/me');
    final rawData = response.data;
    final data = rawData is Map ? rawData['data'] ?? rawData : rawData;
    if (data is Map) {
      return UserRole.fromString(data['role']?.toString() ?? '');
    }
    return UserRole.user;
  }

  Future<UsersListResult> getUsersList({
    int page = 1,
    int limit = 20,
    String? search,
    UserRole? roleFilter,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'limit': limit};

    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    if (roleFilter != null) {
      queryParams['role'] = roleFilter.value.toUpperCase();
    }

    final response = await _dio.get(
      '/roles/users',
      queryParameters: queryParams,
    );

    final rawData = response.data;
    final data = rawData is Map ? rawData['data'] ?? rawData : rawData;

    if (data is Map) {
      final usersRaw = data['users'];
      final paginationRaw = data['pagination'];

      final users = usersRaw is List
          ? usersRaw
                .whereType<Map>()
                .map(
                  (user) =>
                      UserWithRole.fromMap(Map<String, dynamic>.from(user)),
                )
                .toList()
          : <UserWithRole>[];

      final paginationMap = paginationRaw is Map
          ? Map<String, dynamic>.from(paginationRaw)
          : <String, dynamic>{};

      final pagination = UsersPagination(
        page: (paginationMap['page'] as num?)?.toInt() ?? page,
        limit: (paginationMap['limit'] as num?)?.toInt() ?? limit,
        total: (paginationMap['total'] as num?)?.toInt() ?? 0,
        totalPages: (paginationMap['totalPages'] as num?)?.toInt() ?? 1,
      );

      return UsersListResult(users: users, pagination: pagination);
    }

    return UsersListResult(
      users: const [],
      pagination: UsersPagination(
        page: page,
        limit: limit,
        total: 0,
        totalPages: 1,
      ),
    );
  }

  Future<void> updateUserRole({
    required String userId,
    required UserRole role,
  }) async {
    await _dio.patch(
      '/roles/users/$userId/role',
      data: {'role': role.value.toUpperCase()},
    );
  }
}

final rolesApiClientProvider = Provider<RolesApiClient>((ref) {
  return RolesApiClient(ref.watch(dioProvider));
});
