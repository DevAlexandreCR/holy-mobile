import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/data/network/api_client.dart';
import 'package:holyverso/domain/core/paginated.dart';
import 'package:holyverso/domain/verse/saved_verse.dart';
import 'package:holyverso/domain/verse/chapter.dart';
import 'package:holyverso/domain/verse/verse_of_the_day.dart';

class VerseApiClient {
  VerseApiClient(this._dio);

  final Dio _dio;
  static const _l10n = AppLocalizations(Locale('es'));

  Map<String, dynamic> _unwrapData(
    dynamic rawData, {
    String? errorMessage,
  }) {
    final data = rawData is Map ? rawData['data'] ?? rawData : rawData;

    if (data is Map<String, dynamic>) {
      return data;
    }

    throw StateError(errorMessage ?? _l10n.unexpectedVerseFormat);
  }

  Future<VerseOfTheDay> getTodayVerse() async {
    final response = await _dio.get('/verse/today');
    final data = _unwrapData(
      response.data,
      errorMessage: _l10n.unexpectedVerseFormat,
    );

    return VerseOfTheDay.fromMap(Map<String, dynamic>.from(data));
  }

  Future<Chapter> getTodayChapter() async {
    final response = await _dio.get('/verse/today/chapter');
    final data = _unwrapData(
      response.data,
      errorMessage: _l10n.unexpectedChapterFormat,
    );

    return Chapter.fromMap(Map<String, dynamic>.from(data));
  }

  Future<Chapter> getSavedVerseChapter(int libraryVerseId) async {
    final response = await _dio.get('/verse/$libraryVerseId/chapter');
    final data = _unwrapData(
      response.data,
      errorMessage: _l10n.unexpectedChapterFormat,
    );

    return Chapter.fromMap(Map<String, dynamic>.from(data));
  }

  Future<void> likeVerse(int libraryVerseId) async {
    await _dio.post('/verse/$libraryVerseId/like');
  }

  Future<void> shareVerse(int libraryVerseId) async {
    await _dio.post('/verse/$libraryVerseId/share');
  }

  Future<SavedVerse> saveVerse(int libraryVerseId) async {
    final response = await _dio.post('/verse/$libraryVerseId/save');
    final data = _unwrapData(response.data);
    return SavedVerse.fromMap(Map<String, dynamic>.from(data));
  }

  Future<void> removeSavedVerse(int libraryVerseId) async {
    await _dio.delete('/verse/$libraryVerseId/save');
  }

  Future<Paginated<SavedVerse>> fetchSavedVerses({
    String? cursor,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      '/verse/saved',
      queryParameters: {
        if (cursor != null) 'cursor': cursor,
        'limit': limit,
      },
    );

    final data = _unwrapData(response.data);
    final rawItems = data['items'] as List<dynamic>? ?? [];

    final items = rawItems
        .whereType<Map>()
        .map(
          (item) => SavedVerse.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();

    final nextCursor = data['next_cursor']?.toString();

    return Paginated<SavedVerse>(
      items: items,
      nextCursor: nextCursor?.isEmpty == true ? null : nextCursor,
    );
  }
}

final verseApiClientProvider = Provider<VerseApiClient>((ref) {
  return VerseApiClient(ref.watch(dioProvider));
});
