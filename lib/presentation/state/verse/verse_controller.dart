import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/data/verse/verse_repository.dart';
import 'package:holyverso/data/widget/widget_sync_service.dart';
import 'package:holyverso/domain/verse/verse_of_the_day.dart';
import 'package:holyverso/presentation/state/auth/auth_controller.dart';
import 'package:holyverso/presentation/state/verse/verse_state.dart';

class VerseController extends Notifier<VerseState> {
  late final VerseRepository _repository;
  late final WidgetSyncService _widgetSyncService;
  static const _l10n = AppLocalizations(Locale('es'));

  @override
  VerseState build() {
    _repository = ref.read(verseRepositoryProvider);
    _widgetSyncService = ref.read(widgetSyncServiceProvider);

    ref.listen(authControllerProvider, (previous, next) {
      if (previous?.isAuthenticated == true && !next.isAuthenticated) {
        state = const VerseState();
      }
    });

    return const VerseState();
  }

  Future<void> loadVerse({bool forceRefresh = false}) async {
    if (state.isLoading && !forceRefresh) return;

    final authState = ref.read(authControllerProvider);
    if (!authState.isAuthenticated) {
      state = const VerseState();
      return;
    }

    // Check if user has selected a Bible version
    if (authState.preferredVersionId == null) {
      // Don't make API call, just mark as no version selected
      state = const VerseState(
        isLoading: false,
        errorMessage: null, // No error, just no version selected
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _repository.fetchTodayVerse(
        forceRefresh: forceRefresh,
      );
      state = state.copyWith(verse: result.verse, isLoading: false);
      unawaited(
        _handleAfterFetch(result.verse, wasFromNetwork: result.wasFromNetwork),
      );
    } catch (error) {
      // Check if it's a 404 or NO_VERSION_SELECTED error
      final is404 = error is DioException && error.response?.statusCode == 404;
      final isNoVersionError =
          error is DioException &&
          error.response?.statusCode == 400 &&
          error.response?.data is Map &&
          error.response?.data['error']?['code'] == 'NO_VERSION_SELECTED';

      state = state.copyWith(
        isLoading: false,
        errorMessage: (is404 || isNoVersionError) ? null : _mapError(error),
      );
    }
  }

  Future<void> _handleAfterFetch(
    VerseOfTheDay verse, {
    required bool wasFromNetwork,
  }) async {
    final authState = ref.read(authControllerProvider);
    final fontSize = authState.settings?.widgetFontSize.size ?? 16.0;
    // Siempre sincronizar y solicitar actualización inmediata del widget
    // Esto asegura que el widget se actualice incluso si ya había datos guardados
    await _widgetSyncService.syncLatestVerse(
      verse,
      fontSize: fontSize,
      requestImmediateUpdate: true, // Siempre solicitar actualización
    );
  }

  String _mapError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      final responseMessage = data is Map && data['message'] is String
          ? data['message'] as String
          : null;
      return responseMessage ?? error.message ?? _l10n.verseRequestError;
    }

    return _l10n.verseRequestError;
  }

  Future<void> likeVerse(int libraryVerseId) async {
    try {
      await _repository.likeVerse(libraryVerseId);
    } catch (error) {
      // Silently fail - no UI feedback needed for background analytics
    }
  }

  Future<void> shareVerse(int libraryVerseId) async {
    try {
      await _repository.shareVerse(libraryVerseId);
    } catch (error) {
      // Silently fail - no UI feedback needed for background analytics
    }
  }
}

final verseControllerProvider = NotifierProvider<VerseController, VerseState>(
  VerseController.new,
);
