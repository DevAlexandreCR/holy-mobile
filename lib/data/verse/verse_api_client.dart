import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/data/network/api_client.dart';
import 'package:holyverso/domain/verse/verse_of_the_day.dart';

class VerseApiClient {
  VerseApiClient(this._dio);

  final Dio _dio;

  Future<VerseOfTheDay> getTodayVerse() async {
    final response = await _dio.get('/verse/today');
    final rawData = response.data;
    final data = rawData is Map ? rawData['data'] ?? rawData : rawData;

    if (data is Map) {
      return VerseOfTheDay.fromMap(Map<String, dynamic>.from(data));
    }

    const l10n = AppLocalizations(Locale('es'));
    throw StateError(l10n.unexpectedVerseFormat);
  }
}

final verseApiClientProvider = Provider<VerseApiClient>((ref) {
  return VerseApiClient(ref.watch(dioProvider));
});
