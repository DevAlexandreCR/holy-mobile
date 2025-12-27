import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/data/verse/chapter_repository.dart';
import 'package:holyverso/presentation/state/verse/chapter_reader_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChapterReaderController extends Notifier<ChapterReaderState> {
  late final ChapterRepository _repository;
  SharedPreferences? _prefs;

  static const _l10n = AppLocalizations(Locale('es'));
  static const String _textScaleKey = 'chapter_reader_text_scale';

  @override
  ChapterReaderState build() {
    _repository = ref.read(chapterRepositoryProvider);
    unawaited(_loadPersistedTextScale());
    return const ChapterReaderState();
  }

  Future<void> loadChapter({
    ChapterRequest request = const ChapterRequest.today(),
    bool forceRefresh = false,
    ChapterHighlightRange? highlightRange,
  }) async {
    if (state.isLoading && !forceRefresh) return;

    state = state.copyWith(
      status: ChapterReaderStatus.loading,
      clearError: true,
      highlightRange: highlightRange ?? state.highlightRange,
    );

    try {
      final chapter = await _repository.fetchChapter(
        request: request,
        forceRefresh: forceRefresh,
      );
      state = state.copyWith(
        chapter: chapter,
        status: ChapterReaderStatus.success,
        highlightRange: highlightRange ?? state.highlightRange,
      );
    } catch (error) {
      state = state.copyWith(
        status: ChapterReaderStatus.error,
        errorMessage: _mapError(error),
      );
    }
  }

  Future<void> loadTodayChapter({
    bool forceRefresh = false,
    ChapterHighlightRange? highlightRange,
  }) {
    return loadChapter(
      request: const ChapterRequest.today(),
      forceRefresh: forceRefresh,
      highlightRange: highlightRange,
    );
  }

  Future<void> increaseText() async {
    await _updateTextScale(state.textScale + 0.05);
  }

  Future<void> decreaseText() async {
    await _updateTextScale(state.textScale - 0.05);
  }

  Future<void> resetTextScale() async {
    await _updateTextScale(1.0);
  }

  Future<void> _updateTextScale(double value) async {
    final clamped = value
        .clamp(kChapterTextScaleMin, kChapterTextScaleMax)
        .toDouble();
    if (clamped == state.textScale) return;

    state = state.copyWith(textScale: clamped);
    await _persistTextScale(clamped);
  }

  Future<void> _loadPersistedTextScale() async {
    _prefs ??= await SharedPreferences.getInstance();
    final stored = _prefs?.getDouble(_textScaleKey);
    if (stored != null && stored != state.textScale) {
      state = state.copyWith(textScale: stored);
    }
  }

  Future<void> _persistTextScale(double value) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setDouble(_textScaleKey, value);
  }

  String _mapError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      final responseMessage = data is Map && data['message'] is String
          ? data['message'] as String
          : null;
      return responseMessage ?? error.message ?? _l10n.chapterRequestError;
    }

    return _l10n.chapterRequestError;
  }
}

final chapterReaderControllerProvider =
    NotifierProvider<ChapterReaderController, ChapterReaderState>(
      ChapterReaderController.new,
    );
