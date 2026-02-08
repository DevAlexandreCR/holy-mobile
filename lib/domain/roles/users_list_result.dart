import 'package:holyverso/domain/roles/user_with_role.dart';

class UsersListResult {
  const UsersListResult({
    required this.users,
    required this.pagination,
  });

  final List<UserWithRole> users;
  final UsersPagination pagination;
}

class UsersPagination {
  const UsersPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasNextPage => page < totalPages;
  bool get hasPreviousPage => page > 1;
}
