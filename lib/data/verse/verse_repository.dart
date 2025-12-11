import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holy_mobile/data/verse/verse_api_client.dart';
import 'package:holy_mobile/domain/verse/verse_of_the_day.dart';

class VerseRepository {
  VerseRepository(this._client);

  final VerseApiClient _client;
  VerseOfTheDay? _cache;

  Future<VerseOfTheDay> fetchTodayVerse({bool forceRefresh = false}) async {
    if (!forceRefresh && _cache != null) {
      return _cache!;
    }

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
}

final verseRepositoryProvider = Provider<VerseRepository>((ref) {
  return VerseRepository(ref.watch(verseApiClientProvider));
});
