import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/data/verse/verse_api_client.dart';
import 'package:holyverso/domain/verse/chapter.dart';

class ChapterRequest {
  const ChapterRequest.today()
    : book = null,
      chapter = null,
      libraryVerseId = null,
      versionCode = null,
      isToday = true;

  const ChapterRequest.saved({
    required this.libraryVerseId,
    this.versionCode,
  })  : book = null,
        chapter = null,
        isToday = false;

  const ChapterRequest({
    required this.book,
    required this.chapter,
    this.versionCode,
  })  : libraryVerseId = null,
        isToday = false;

  final String? book;
  final int? chapter;
  final int? libraryVerseId;
  final String? versionCode;
  final bool isToday;
}

class ChapterRepository {
  ChapterRepository(this._client);

  final VerseApiClient _client;
  Chapter? _todayCache;

  Future<Chapter> fetchChapter({
    ChapterRequest request = const ChapterRequest.today(),
    bool forceRefresh = false,
  }) async {
    if (request.isToday) {
      if (_todayCache != null && !forceRefresh) return _todayCache!;
      final chapter = await _client.getTodayChapter();
      _todayCache = chapter;
      return chapter;
    }

    if (request.libraryVerseId != null) {
      return _client.getSavedVerseChapter(request.libraryVerseId!);
    }

    throw UnsupportedError('Custom chapter fetching is not implemented yet.');
  }

  void clearTodayCache() {
    _todayCache = null;
  }
}

final chapterRepositoryProvider = Provider<ChapterRepository>((ref) {
  return ChapterRepository(ref.watch(verseApiClientProvider));
});
