import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/core/errors/app_error_mapper.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/data/devotionals/devotionals_repository.dart';
import 'package:holyverso/domain/devotionals/devotional_status.dart';
import 'package:holyverso/presentation/state/auth/auth_controller.dart';
import 'package:holyverso/presentation/state/devotionals/devotionals_list_state.dart';

class DevotionalsListController extends Notifier<DevotionalsListState> {
  late final DevotionalsRepository _repository;
  static const _l10n = AppLocalizations(Locale('es'));

  @override
  DevotionalsListState build() {
    _repository = ref.read(devotionalsRepositoryProvider);
    return const DevotionalsListState();
  }

  Future<void> loadInitial({bool forceRefresh = false}) async {
    if (state.status == DevotionalsListStatus.loading && !forceRefresh) {
      return;
    }

    state = state.copyWith(
      status: DevotionalsListStatus.loading,
      page: 1,
      likingDevotionalId: null,
      clearError: true,
    );

    await _fetchPage(page: 1);
  }

  Future<void> refresh() async {
    await loadInitial(forceRefresh: true);
  }

  Future<void> loadMore() async {
    if (state.isFetchingMore || !state.hasMore) return;

    state = state.copyWith(isFetchingMore: true, clearError: true);
    await _fetchPage(page: state.page + 1, append: true);
  }

  void setMode(DevotionalsListMode mode) {
    final nextStatus = mode == DevotionalsListMode.all
        ? DevotionalStatus.published
        : DevotionalStatus.draft;

    state = state.copyWith(
      mode: mode,
      statusFilter: nextStatus,
      page: 1,
      total: 0,
      items: const [],
    );

    unawaited(loadInitial(forceRefresh: true));
  }

  void setStatusFilter(DevotionalStatus status) {
    if (state.statusFilter == status) return;
    state = state.copyWith(
      statusFilter: status,
      page: 1,
      total: 0,
      items: const [],
    );
    unawaited(loadInitial(forceRefresh: true));
  }

  Future<void> _fetchPage({required int page, bool append = false}) async {
    try {
      final authState = ref.read(authControllerProvider);
      final authorId = state.mode == DevotionalsListMode.mine
          ? authState.user?.id
          : null;

      final result = await _repository.fetchDevotionals(
        status: state.statusFilter,
        page: page,
        limit: state.limit,
        authorId: authorId,
      );

      final items = append ? [...state.items, ...result.items] : result.items;

      state = state.copyWith(
        status: DevotionalsListStatus.success,
        items: items,
        page: result.page,
        limit: result.limit,
        total: result.total,
      );
    } catch (error) {
      state = state.copyWith(
        status: DevotionalsListStatus.error,
        errorMessage: _mapError(error),
      );
    } finally {
      if (state.isFetchingMore) {
        state = state.copyWith(isFetchingMore: false);
      }
    }
  }

  Future<void> toggleLike(String devotionalId) async {
    if (state.likingDevotionalId == devotionalId) return;
    final index = state.items.indexWhere((item) => item.id == devotionalId);
    if (index == -1) return;

    state = state.copyWith(likingDevotionalId: devotionalId, clearError: true);
    try {
      final result = await _repository.toggleLike(devotionalId);
      final updated = state.items[index].copyWith(
        likesCount: result.likesCount,
        liked: result.liked,
      );
      final items = [...state.items];
      items[index] = updated;
      state = state.copyWith(items: items);
    } catch (error) {
      state = state.copyWith(errorMessage: _mapError(error));
    } finally {
      if (state.likingDevotionalId == devotionalId) {
        state = state.copyWith(likingDevotionalId: null);
      }
    }
  }

  void updateCommentsCount(String devotionalId, int total) {
    final index = state.items.indexWhere((item) => item.id == devotionalId);
    if (index == -1) return;
    final updated = state.items[index].copyWith(commentsCount: total);
    final items = [...state.items];
    items[index] = updated;
    state = state.copyWith(items: items);
  }

  String _mapError(Object error) {
    return AppErrorMapper.toMessage(
      error,
      l10n: _l10n,
      fallbackMessage: _l10n.devotionalsLoadError,
    );
  }
}

final devotionalsListControllerProvider =
    NotifierProvider<DevotionalsListController, DevotionalsListState>(
      DevotionalsListController.new,
    );
