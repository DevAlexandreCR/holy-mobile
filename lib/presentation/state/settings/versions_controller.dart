import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holy_mobile/core/l10n/app_localizations.dart';
import 'package:holy_mobile/data/bible/bible_repository.dart';
import 'package:holy_mobile/presentation/state/auth/auth_controller.dart';
import 'package:holy_mobile/presentation/state/settings/versions_state.dart';
import 'package:holy_mobile/presentation/state/verse/verse_controller.dart';

class VersionsController extends Notifier<VersionsState> {
  late final BibleRepository _repository;
  static const _l10n = AppLocalizations(Locale('es'));

  @override
  VersionsState build() {
    _repository = ref.read(bibleRepositoryProvider);

    ref.listen(authControllerProvider, (previous, next) {
      if (previous?.isAuthenticated == true && !next.isAuthenticated) {
        state = const VersionsState();
      }
    });

    return const VersionsState();
  }

  Future<void> loadVersions({bool forceRefresh = false}) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final versions = await _repository.fetchVersions(forceRefresh: forceRefresh);
      state = state.copyWith(
        versions: versions,
        isLoading: false,
        hasLoaded: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        hasLoaded: true,
        errorMessage: _mapError(error),
      );
    }
  }

  Future<bool> selectVersion(int versionId) async {
    state = state.copyWith(clearError: true);
    final success =
        await ref.read(authControllerProvider.notifier).updatePreferredVersion(versionId);

    if (!success) {
      final authState = ref.read(authControllerProvider);
      state = state.copyWith(
        errorMessage: authState.errorMessage ?? _l10n.versionsUpdateError,
      );
    }

    if (success) {
      // Refresh verse of the day with the newly selected version without blocking the UI.
      unawaited(ref.read(verseControllerProvider.notifier).loadVerse(forceRefresh: true));
    }

    return success;
  }

  String _mapError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      final responseMessage =
          data is Map && data['message'] is String ? data['message'] as String : null;
      return responseMessage ??
          error.message ??
          _l10n.versionsLoadError;
    }

    return _l10n.versionsLoadError;
  }
}

final versionsControllerProvider =
    NotifierProvider<VersionsController, VersionsState>(VersionsController.new);
