import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/core/errors/app_error_mapper.dart';
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
            (user) => user.id == userId ? user.copyWith(role: newRole) : user,
          )
          .toList();
      state = state.copyWith(users: updatedUsers);
      return true;
    } catch (error) {
      state = state.copyWith(errorMessage: _mapError(error));
      return false;
    }
  }

  Future<bool> blockUser(String userId, String reason) async {
    try {
      final updatedUser = await _repository.blockUser(
        userId: userId,
        reason: reason,
      );
      state = state.copyWith(
        users: state.users
            .map((user) => user.id == userId ? updatedUser : user)
            .toList(),
      );
      return true;
    } catch (error) {
      state = state.copyWith(errorMessage: _mapError(error));
      return false;
    }
  }

  Future<bool> unblockUser(String userId, String reason) async {
    try {
      final updatedUser = await _repository.unblockUser(
        userId: userId,
        reason: reason,
      );
      state = state.copyWith(
        users: state.users
            .map((user) => user.id == userId ? updatedUser : user)
            .toList(),
      );
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
    return AppErrorMapper.toMessage(
      error,
      l10n: _l10n,
      fallbackMessage: _l10n.genericError,
      businessCodeMessages: const {
        'FORBIDDEN': 'No tienes permisos para esta acción',
        'LAST_ADMIN': 'No puedes quitar el último administrador',
        'CANNOT_CHANGE_OWN_ROLE': 'No puedes cambiar tu propio rol',
        'CANNOT_BLOCK_SELF': 'No puedes bloquear tu propia cuenta',
        'CANNOT_UNBLOCK_SELF': 'No puedes desbloquear tu propia cuenta',
        'BLOCK_REASON_REQUIRED': 'Debes escribir un motivo para bloquear',
        'UNBLOCK_REASON_REQUIRED': 'Debes escribir un motivo para desbloquear',
        'USER_ALREADY_BLOCKED': 'La cuenta ya está bloqueada',
        'USER_NOT_BLOCKED': 'La cuenta no está bloqueada',
        'USER_NOT_FOUND': 'No se encontró el usuario',
        'INVALID_ROLE': 'El rol seleccionado no es válido',
        'AUTH_REQUIRED': 'Debes iniciar sesión para continuar',
      },
    );
  }
}

final usersListControllerProvider =
    NotifierProvider<UsersListController, UsersListState>(
      UsersListController.new,
    );
