import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/data/verse/verse_api_client.dart';
import 'package:holyverso/data/widget/widget_verse_storage.dart';
import 'package:holyverso/domain/core/paginated.dart';
import 'package:holyverso/domain/verse/saved_verse.dart';
import 'package:holyverso/domain/verse/verse_of_the_day.dart';
import 'package:holyverso/domain/widget/widget_verse.dart';

class VerseRepository {
  VerseRepository(this._client, this._storage);

  final VerseApiClient _client;
  final WidgetVerseStorage _storage;
  VerseOfTheDay? _cache;
  final Set<int> _savedIds = <int>{};

  Set<int> get savedIds => {..._savedIds};

  void clearSession() {
    _cache = null;
    _savedIds.clear();
  }

  Future<({VerseOfTheDay verse, bool wasFromNetwork})> fetchTodayVerse({
    bool forceRefresh = false,
  }) async {
    // If not forcing a refresh, check if today's verse is already cached
    if (!forceRefresh) {
      // Check the in-memory cache first
      if (_cache != null && _cache!.libraryVerseId != null) {
        _syncCacheSavedStatus();
        return (verse: _cache!, wasFromNetwork: false);
      }

      // Then check if today's verse is persisted in storage
      final todayVerse = await _storage.getTodayVerse();
      if (todayVerse != null && todayVerse.libraryVerseId != null) {
        final verse = _widgetVerseToVerseOfTheDay(todayVerse);
        _cache = verse.copyWith(
          isSaved: verse.libraryVerseId != null &&
              _savedIds.contains(verse.libraryVerseId!),
        );
        return (verse: verse, wasFromNetwork: false);
      }
    }

    // If nothing is cached or forceRefresh is true, fetch from the backend
    try {
      final verse = await _client.getTodayVerse();
      _cache = verse;
      _applySavedStatusFromVerse(verse);
      return (verse: verse, wasFromNetwork: true);
    } catch (error) {
      if (_cache != null) {
        return (verse: _cache!, wasFromNetwork: false);
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
      libraryVerseId: widgetVerse.libraryVerseId,
      isSaved: widgetVerse.isSaved,
      theme: widgetVerse.theme,
    );
  }

  Future<void> likeVerse(int libraryVerseId) async {
    await _client.likeVerse(libraryVerseId);
  }

  Future<void> shareVerse(int libraryVerseId) async {
    await _client.shareVerse(libraryVerseId);
  }

  bool isSaved(int libraryVerseId) => _savedIds.contains(libraryVerseId);

  Future<SavedVerse> saveVerse(int libraryVerseId) async {
    final saved = await _client.saveVerse(libraryVerseId);
    _savedIds.add(libraryVerseId);
    _syncCacheSavedStatus();
    return saved;
  }

  Future<void> removeSavedVerse(int libraryVerseId) async {
    await _client.removeSavedVerse(libraryVerseId);
    _savedIds.remove(libraryVerseId);
    _syncCacheSavedStatus();
  }

  Future<Paginated<SavedVerse>> fetchSavedVerses({
    String? cursor,
    int limit = 20,
  }) async {
    final result = await _client.fetchSavedVerses(
      cursor: cursor,
      limit: limit,
    );
    _savedIds.addAll(result.items.map((item) => item.libraryVerseId));
    _syncCacheSavedStatus();
    return result;
  }

  void _applySavedStatusFromVerse(VerseOfTheDay verse) {
    final libraryVerseId = verse.libraryVerseId;
    if (libraryVerseId == null) return;

    if (verse.isSaved) {
      _savedIds.add(libraryVerseId);
    } else {
      _savedIds.remove(libraryVerseId);
    }
    _syncCacheSavedStatus();
  }

  void _syncCacheSavedStatus() {
    if (_cache == null || _cache?.libraryVerseId == null) return;
    final id = _cache!.libraryVerseId!;
    _cache = _cache!.copyWith(isSaved: _savedIds.contains(id));
  }
}

final verseRepositoryProvider = Provider<VerseRepository>((ref) {
  return VerseRepository(
    ref.watch(verseApiClientProvider),
    ref.watch(widgetVerseStorageProvider),
  );
});
