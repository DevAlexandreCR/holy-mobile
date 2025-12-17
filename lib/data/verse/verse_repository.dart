import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/data/verse/verse_api_client.dart';
import 'package:holyverso/data/widget/widget_verse_storage.dart';
import 'package:holyverso/domain/verse/verse_of_the_day.dart';
import 'package:holyverso/domain/widget/widget_verse.dart';

class VerseRepository {
  VerseRepository(this._client, this._storage);

  final VerseApiClient _client;
  final WidgetVerseStorage _storage;
  VerseOfTheDay? _cache;

  Future<VerseOfTheDay> fetchTodayVerse({bool forceRefresh = false}) async {
    // Si no es forceRefresh, verificar primero si hay un verso del día actual guardado
    if (!forceRefresh) {
      // Primero verificar el cache en memoria
      if (_cache != null) {
        return _cache!;
      }

      // Luego verificar si hay un verso del día actual en el storage
      final todayVerse = await _storage.getTodayVerse();
      if (todayVerse != null) {
        final verse = _widgetVerseToVerseOfTheDay(todayVerse);
        _cache = verse;
        return verse;
      }
    }

    // Si no hay verso guardado o es forceRefresh, pedir al backend
    try {
      final verse = await _client.getTodayVerse();
      _cache = verse;
      return verse;
    } catch (error) {
      if (_cache != null) {
        return _cache!;
      }
      rethrow;
    }
  }

  VerseOfTheDay _widgetVerseToVerseOfTheDay(WidgetVerse widgetVerse) {
    return VerseOfTheDay(
      date: widgetVerse.date,
      versionCode: widgetVerse.versionCode,
      versionName: widgetVerse.versionName,
      reference: widgetVerse.reference,
      text: widgetVerse.text,
    );
  }
}

final verseRepositoryProvider = Provider<VerseRepository>((ref) {
  return VerseRepository(
    ref.watch(verseApiClientProvider),
    ref.watch(widgetVerseStorageProvider),
  );
});
