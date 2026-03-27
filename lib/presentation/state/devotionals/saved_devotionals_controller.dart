import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/core/errors/app_error_mapper.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/data/devotionals/devotionals_repository.dart';
import 'package:holyverso/domain/devotionals/devotional.dart';
import 'package:holyverso/presentation/state/devotionals/saved_devotionals_state.dart';

class SavedDevotionalsController extends Notifier<SavedDevotionalsState> {
  late final DevotionalsRepository _repository;
  static const _l10n = AppLocalizations(Locale('es'));

  @override
  SavedDevotionalsState build() {
    _repository = ref.read(devotionalsRepositoryProvider);
    return const SavedDevotionalsState();
  }

  Future<void> loadInitial({bool forceRefresh = false}) async {
    if (state.isLoading && !forceRefresh) return;

    state = state.copyWith(
      status: SavedDevotionalsStatus.loading,
      clearError: true,
      isFetchingMore: false,
      items: forceRefresh ? const [] : state.items,
      clearNextCursor: forceRefresh,
      nextCursor: forceRefresh ? null : state.nextCursor,
      hasMore: forceRefresh ? true : state.hasMore,
    );

    try {
      final result = await _repository.fetchSavedDevotionals();
      state = state.copyWith(
        status: SavedDevotionalsStatus.success,
        items: result.items,
        nextCursor: result.nextCursor,
        hasMore: result.hasMore,
      );
    } catch (error) {
      state = state.copyWith(
        status: SavedDevotionalsStatus.error,
        errorMessage: _mapError(error),
      );
    }
  }

  Future<void> refresh() => loadInitial(forceRefresh: true);

  Future<void> loadMore() async {
    if (state.isFetchingMore || !state.hasMore || state.nextCursor == null) {
      return;
    }

    state = state.copyWith(isFetchingMore: true, clearError: true);

    try {
      final result = await _repository.fetchSavedDevotionals(
        cursor: state.nextCursor,
      );
      state = state.copyWith(
        items: [...state.items, ...result.items],
        nextCursor: result.nextCursor,
        hasMore: result.hasMore,
      );
    } catch (error) {
      state = state.copyWith(errorMessage: _mapError(error));
    } finally {
      state = state.copyWith(isFetchingMore: false);
    }
  }

  Future<bool> unsaveDevotional(Devotional devotional) async {
    if (state.pendingIds.contains(devotional.id)) return false;

    final previousState = state;
    final pendingIds = {...state.pendingIds, devotional.id};
    final items = [...state.items]
      ..removeWhere((item) => item.id == devotional.id);

    state = state.copyWith(
      items: items,
      pendingIds: pendingIds,
      clearError: true,
    );

    try {
      await _repository.unsaveDevotional(devotional.id);
      return true;
    } catch (error) {
      state = previousState.copyWith(errorMessage: _mapError(error));
      return false;
    } finally {
      final nextPendingIds = {...state.pendingIds}..remove(devotional.id);
      state = state.copyWith(pendingIds: nextPendingIds);
    }
  }

  void syncSavedDevotional(Devotional devotional) {
    if (state.status == SavedDevotionalsStatus.idle && state.items.isEmpty) {
      return;
    }

    final items = [...state.items];
    final existingIndex = items.indexWhere((item) => item.id == devotional.id);

    if (!devotional.saved) {
      if (existingIndex != -1) {
        items.removeAt(existingIndex);
        state = state.copyWith(items: items);
      }
      return;
    }

    if (existingIndex == -1) {
      items.insert(0, devotional);
    } else {
      items[existingIndex] = devotional;
      if (existingIndex > 0) {
        final updated = items.removeAt(existingIndex);
        items.insert(0, updated);
      }
    }

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

final savedDevotionalsControllerProvider =
    NotifierProvider<SavedDevotionalsController, SavedDevotionalsState>(
      SavedDevotionalsController.new,
    );
