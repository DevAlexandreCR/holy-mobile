import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/core/errors/app_error_mapper.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/data/devotionals/devotionals_repository.dart';
import 'package:holyverso/presentation/state/devotionals/devotionals_list_state.dart';

class DevotionalReviewQueueController extends Notifier<DevotionalsListState> {
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
      clearError: true,
    );

    await _fetchPage(page: 1);
  }

  Future<void> refresh() => loadInitial(forceRefresh: true);

  Future<void> loadMore() async {
    if (state.isFetchingMore || !state.hasMore) return;
    state = state.copyWith(isFetchingMore: true, clearError: true);
    await _fetchPage(page: state.page + 1, append: true);
  }

  Future<void> _fetchPage({required int page, bool append = false}) async {
    try {
      final result = await _repository.fetchReviewQueue(
        page: page,
        limit: state.limit,
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
        errorMessage: AppErrorMapper.toMessage(
          error,
          l10n: _l10n,
          fallbackMessage: _l10n.devotionalsLoadError,
        ),
      );
    } finally {
      if (state.isFetchingMore) {
        state = state.copyWith(isFetchingMore: false);
      }
    }
  }
}

final devotionalReviewQueueControllerProvider = NotifierProvider<
  DevotionalReviewQueueController,
  DevotionalsListState
>(DevotionalReviewQueueController.new);
