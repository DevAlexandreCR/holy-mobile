import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/data/verse/verse_repository.dart';
import 'package:holyverso/domain/verse/saved_verse.dart';
import 'package:holyverso/domain/verse/verse_of_the_day.dart';
import 'package:holyverso/presentation/state/auth/auth_controller.dart';
import 'package:holyverso/presentation/state/verse/saved_verses_state.dart';

class SavedVersesController extends Notifier<SavedVersesState> {
  late final VerseRepository _repository;
  static const _l10n = AppLocalizations(Locale('es'));

  @override
  SavedVersesState build() {
    _repository = ref.read(verseRepositoryProvider);
    ref.listen(authControllerProvider, (previous, next) {
      if (previous?.isAuthenticated == true && !next.isAuthenticated) {
        _repository.clearSession();
        state = const SavedVersesState();
      }
    });
    return SavedVersesState(savedIds: _repository.savedIds);
  }

  bool isSaved(int libraryVerseId) => state.savedIds.contains(libraryVerseId);

  bool isPending(int libraryVerseId) =>
      state.pendingIds.contains(libraryVerseId);

  Future<void> loadInitialSaved() async {
    if (state.isLoading) return;

    state = state.copyWith(
      status: SavedVersesStatus.loading,
      isFetchingMore: false,
      clearError: true,
    );

    try {
      final result = await _repository.fetchSavedVerses();
      final savedIds = <int>{
        ...state.savedIds,
        ...result.items.map((item) => item.libraryVerseId),
      };

      state = state.copyWith(
        status: SavedVersesStatus.success,
        items: result.items,
        nextCursor: result.nextCursor,
        savedIds: savedIds,
      );
    } catch (error) {
      state = state.copyWith(
        status: SavedVersesStatus.error,
        error: _mapError(error),
      );
    }
  }

  Future<void> loadMoreSaved() async {
    if (state.isFetchingMore || state.nextCursor == null) return;

    state = state.copyWith(isFetchingMore: true, clearError: true);

    try {
      final result = await _repository.fetchSavedVerses(
        cursor: state.nextCursor,
      );

      final updatedItems = [...state.items, ...result.items];
      final savedIds = <int>{
        ...state.savedIds,
        ...result.items.map((item) => item.libraryVerseId),
      };

      state = state.copyWith(
        items: updatedItems,
        nextCursor: result.nextCursor,
        savedIds: savedIds,
      );
    } catch (error) {
      state = state.copyWith(error: _mapError(error));
    } finally {
      state = state.copyWith(isFetchingMore: false);
    }
  }

  Future<void> toggleSave(int libraryVerseId) async {
    if (isPending(libraryVerseId)) return;

    final previousState = state;
    final wasSaved = _repository.isSaved(libraryVerseId);
    final pending = {...state.pendingIds, libraryVerseId};
    final savedIds = <int>{...state.savedIds};

    if (wasSaved) {
      savedIds.remove(libraryVerseId);
      final trimmedItems = state.items
          .where((item) => item.libraryVerseId != libraryVerseId)
          .toList();
      state = state.copyWith(
        savedIds: savedIds,
        pendingIds: pending,
        items: trimmedItems,
        clearError: true,
      );
    } else {
      savedIds.add(libraryVerseId);
      state = state.copyWith(
        savedIds: savedIds,
        pendingIds: pending,
        clearError: true,
      );
    }

    try {
      SavedVerse? savedVerse;
      if (wasSaved) {
        await _repository.removeSavedVerse(libraryVerseId);
      } else {
        savedVerse = await _repository.saveVerse(libraryVerseId);
      }

      var items = state.items;
      if (savedVerse != null &&
          !items.any((item) => item.libraryVerseId == savedVerse!.libraryVerseId)) {
        items = [savedVerse, ...items];
      }

      state = state.copyWith(
        savedIds: _repository.savedIds,
        items: items,
      );
    } catch (error) {
      state = previousState.copyWith(error: _mapError(error));
    } finally {
      final pendingIds = {...state.pendingIds};
      pendingIds.remove(libraryVerseId);
      state = state.copyWith(pendingIds: pendingIds);
    }
  }

  void syncFromTodayVerse(VerseOfTheDay verse) {
    final verseId = verse.libraryVerseId;
    if (verseId == null) return;

    final savedIds = <int>{...state.savedIds};
    if (verse.isSaved) {
      savedIds.add(verseId);
    } else {
      savedIds.remove(verseId);
    }

    state = state.copyWith(savedIds: savedIds);
  }

  String _mapError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      final responseMessage = data is Map && data['message'] is String
          ? data['message'] as String
          : null;
      return responseMessage ?? error.message ?? _l10n.genericError;
    }

    return _l10n.genericError;
  }
}

final savedVersesControllerProvider =
    NotifierProvider<SavedVersesController, SavedVersesState>(
  SavedVersesController.new,
);
