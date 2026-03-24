import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_design_tokens.dart';
import 'package:holyverso/core/theme/app_text_styles.dart';
import 'package:holyverso/domain/roles/user_role.dart';
import 'package:holyverso/domain/roles/user_with_role.dart';
import 'package:holyverso/presentation/screens/users/user_role_dialog.dart';
import 'package:holyverso/presentation/state/roles/role_provider.dart';
import 'package:holyverso/presentation/state/roles/users_list_controller.dart';
import 'package:holyverso/presentation/widgets/users/user_list_item.dart';
import 'package:holyverso/presentation/widgets/users/user_search_bar.dart';

class UsersListScreen extends ConsumerStatefulWidget {
  const UsersListScreen({super.key});

  @override
  ConsumerState<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends ConsumerState<UsersListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(usersListControllerProvider.notifier).loadUsers();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      ref.read(usersListControllerProvider.notifier).loadNextPage();
    }
  }

  AppBar _buildAppBar(UsersListState state) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      title: Text(
        'Gestión de usuarios',
        style: AppTextStyles.headline3.copyWith(
          color: AppColors.pureWhite,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        PopupMenuButton<UserRole?>(
          icon: Icon(Icons.tune_rounded, color: AppColors.pureWhite),
          tooltip: 'Filtrar por rol',
          initialValue: state.roleFilter,
          onSelected: (role) {
            ref.read(usersListControllerProvider.notifier).filterByRole(role);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: null, child: Text('Todos los usuarios')),
            ...UserRole.values.map(
              (role) =>
                  PopupMenuItem(value: role, child: Text(role.displayName)),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(usersListControllerProvider);
    final isAdmin = ref.watch(isAdminProvider);

    return Scaffold(
      backgroundColor: AppColors.midnightFaith,
      appBar: _buildAppBar(state),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(gradient: AppColors.midnightGradient),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: UserSearchBar(
                    onSearch: (query) {
                      ref
                          .read(usersListControllerProvider.notifier)
                          .searchUsers(query);
                    },
                  ),
                ),
                if (state.roleFilter != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Chip(
                        backgroundColor: AppColors.inputBackground,
                        label: Text(
                          'Filtro: ${state.roleFilter!.displayName}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.pureWhite,
                          ),
                        ),
                        onDeleted: () {
                          ref
                              .read(usersListControllerProvider.notifier)
                              .filterByRole(null);
                        },
                      ),
                    ),
                  ),
                if (state.errorMessage != null && state.users.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.sm,
                    ),
                    child: _ErrorBanner(message: state.errorMessage!),
                  ),
                Expanded(child: _buildUsersList(state, isAdmin)),
                if (state.users.isNotEmpty) _buildPaginationInfo(state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(UsersListState state, bool isAdmin) {
    if (state.isLoading && state.users.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.holyGold),
      );
    }

    if (state.errorMessage != null && state.users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              state.errorMessage!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.pureWhite,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: () {
                ref.read(usersListControllerProvider.notifier).loadUsers();
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (state.users.isEmpty) {
      return Center(
        child: Text(
          'No se encontraron usuarios',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.softMist.withValues(alpha: 0.8),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.holyGold,
      backgroundColor: AppColors.midnightFaith,
      onRefresh: () =>
          ref.read(usersListControllerProvider.notifier).loadUsers(),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: state.users.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.users.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.holyGold),
              ),
            );
          }

          final user = state.users[index];
          return UserListItem(
            user: user,
            onTap: isAdmin ? () => _showRoleDialog(user) : null,
          );
        },
      ),
    );
  }

  Widget _buildPaginationInfo(UsersListState state) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.midnightFaith.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(color: AppColors.pureWhite.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Página ${state.pagination.page} de ${state.pagination.totalPages}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.softMist.withValues(alpha: 0.8),
            ),
          ),
          Text(
            '${state.pagination.total} usuarios',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.softMist.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRoleDialog(UserWithRole user) async {
    final result = await showModalBottomSheet<UserRole>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => UserRoleDialog(user: user),
    );

    if (result == null || !mounted) return;

    final success = await ref
        .read(usersListControllerProvider.notifier)
        .updateUserRole(user.id, result);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Role actualizado a ${result.displayName}'),
          backgroundColor: AppColors.holyGold,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No fue posible actualizar el role'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withValues(alpha: 0.25),
        borderRadius: AppBorderRadius.card,
        border: Border.all(color: Colors.red.shade700.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade300),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.pureWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
