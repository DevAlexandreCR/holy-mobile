import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/data/roles/role_repository.dart';
import 'package:holyverso/domain/roles/user_role.dart';
import 'package:holyverso/domain/roles/user_with_role.dart';
import 'package:holyverso/domain/roles/users_list_result.dart';
import 'package:holyverso/presentation/state/auth/auth_controller.dart';

class UsersListState {
  const UsersListState({
    this.users = const [],
    required this.pagination,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.searchQuery = '',
    this.roleFilter,
  });

  final List<UserWithRole> users;
  final UsersPagination pagination;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final String searchQuery;
  final UserRole? roleFilter;

  UsersListState copyWith({
    List<UserWithRole>? users,
    UsersPagination? pagination,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    String? searchQuery,
    UserRole? roleFilter,
    bool clearError = false,
    bool clearRoleFilter = false,
  }) {
    return UsersListState(
      users: users ?? this.users,
      pagination: pagination ?? this.pagination,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      roleFilter: clearRoleFilter ? null : (roleFilter ?? this.roleFilter),
    );
  }
}

class UsersListController extends Notifier<UsersListState> {
  late final RoleRepository _repository;
  static const _l10n = AppLocalizations(Locale('es'));

  @override
  UsersListState build() {
    _repository = ref.read(roleRepositoryProvider);

    ref.listen(authControllerProvider, (previous, next) {
      if (previous?.isAuthenticated == true && !next.isAuthenticated) {
        state = UsersListState(
          pagination: const UsersPagination(
            page: 1,
            limit: 20,
            total: 0,
            totalPages: 1,
          ),
        );
      }
    });

    return UsersListState(
      pagination: const UsersPagination(
        page: 1,
        limit: 20,
        total: 0,
        totalPages: 1,
      ),
    );
  }

  Future<void> loadUsers({int page = 1}) async {
    if (state.isLoading || state.isLoadingMore) return;

    final isPaging = page > 1;
    state = state.copyWith(
      isLoading: !isPaging,
      isLoadingMore: isPaging,
      clearError: true,
    );

    try {
      final result = await _repository.getUsersList(
        page: page,
        limit: state.pagination.limit,
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        roleFilter: state.roleFilter,
      );

      final nextUsers = isPaging
          ? [...state.users, ...result.users]
          : result.users;

      state = state.copyWith(
        users: nextUsers,
        pagination: result.pagination,
        isLoading: false,
        isLoadingMore: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        errorMessage: _mapError(error),
      );
    }
  }

  Future<void> searchUsers(String query) async {
    state = state.copyWith(searchQuery: query);
    await loadUsers(page: 1);
  }

  Future<void> filterByRole(UserRole? role) async {
    state = state.copyWith(roleFilter: role, clearRoleFilter: role == null);
    await loadUsers(page: 1);
  }

  Future<void> loadNextPage() async {
    if (!state.pagination.hasNextPage) return;
    await loadUsers(page: state.pagination.page + 1);
  }

  Future<void> loadPreviousPage() async {
    if (!state.pagination.hasPreviousPage) return;
    await loadUsers(page: state.pagination.page - 1);
  }

  Future<bool> updateUserRole(String userId, UserRole newRole) async {
    try {
      await _repository.updateUserRole(userId: userId, role: newRole);
      final updatedUsers = state.users
          .map(
            (user) =>
                user.id == userId ? user.copyWith(role: newRole) : user,
          )
          .toList();
      state = state.copyWith(users: updatedUsers);
      return true;
    } catch (error) {
      state = state.copyWith(errorMessage: _mapError(error));
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  String _mapError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['error'] is Map) {
        final errorMap = data['error'] as Map;
        final code = errorMap['code']?.toString();
        switch (code) {
          case 'FORBIDDEN':
            return 'No tienes permisos para esta acción';
          case 'LAST_ADMIN':
            return 'No puedes quitar el último administrador';
          case 'CANNOT_CHANGE_OWN_ROLE':
            return 'No puedes cambiar tu propio role';
          case 'USER_NOT_FOUND':
            return 'No se encontró el usuario';
          case 'INVALID_ROLE':
            return 'El role seleccionado no es válido';
          case 'AUTH_REQUIRED':
            return 'Debes iniciar sesión para continuar';
        }
      }
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      return error.message ?? _l10n.genericError;
    }

    return _l10n.genericError;
  }
}

final usersListControllerProvider =
    NotifierProvider<UsersListController, UsersListState>(
      UsersListController.new,
    );
