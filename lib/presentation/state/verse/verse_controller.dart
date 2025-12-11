import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holy_mobile/core/l10n/app_localizations.dart';
import 'package:holy_mobile/data/verse/verse_repository.dart';
import 'package:holy_mobile/data/widget/widget_sync_service.dart';
import 'package:holy_mobile/domain/verse/verse_of_the_day.dart';
import 'package:holy_mobile/presentation/state/auth/auth_controller.dart';
import 'package:holy_mobile/presentation/state/verse/verse_state.dart';

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

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final verse = await _repository.fetchTodayVerse(forceRefresh: forceRefresh);
      state = state.copyWith(verse: verse, isLoading: false);
      unawaited(_handleAfterFetch(verse));
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _mapError(error),
      );
    }
  }

  Future<void> _handleAfterFetch(VerseOfTheDay verse) async {
    await _widgetSyncService.syncLatestVerse(verse);
  }

  String _mapError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      final responseMessage =
          data is Map && data['message'] is String ? data['message'] as String : null;
      return responseMessage ??
          error.message ??
          _l10n.verseRequestError;
    }

    return _l10n.verseRequestError;
  }
}

final verseControllerProvider =
    NotifierProvider<VerseController, VerseState>(VerseController.new);
