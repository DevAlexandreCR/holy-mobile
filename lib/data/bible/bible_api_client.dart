import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/data/bible/models/bible_version.dart';
import 'package:holyverso/domain/verse/book_suggestion.dart';
import 'package:holyverso/domain/verse/search_result.dart';
import 'package:holyverso/data/network/api_client.dart';

class BibleApiClient {
  BibleApiClient(this._dio);

  final Dio _dio;

  Future<List<BibleVersion>> getVersions() async {
    final response = await _dio.get('/bible/versions');
    final rawData = response.data;
    final data = rawData is Map ? rawData['data'] ?? rawData : rawData;

    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => BibleVersion.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    }

    return const [];
  }

  Future<SearchResult?> searchVerses(String query, {int? versionId}) async {
    final response = await _dio.post(
      '/bible/search',
      data: {
        'query': query,
        if (versionId != null) 'versionId': versionId,
      },
    );

    final rawData = response.data;
    final data = rawData is Map ? rawData['data'] ?? rawData : rawData;
    if (data is Map) {
      return SearchResult.fromMap(Map<String, dynamic>.from(data));
    }
    return null;
  }

  Future<List<BookSuggestion>> getAutocompleteSuggestions(String query) async {
    final response = await _dio.get(
      '/bible/autocomplete',
      queryParameters: {'q': query},
    );

    final rawData = response.data;
    final data = rawData is Map ? rawData['data'] ?? rawData : rawData;
    final suggestionsRaw = data is Map ? data['suggestions'] : null;

    if (suggestionsRaw is List) {
      return suggestionsRaw
          .whereType<Map>()
          .map((item) => BookSuggestion.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    }

    return const [];
  }
}

final bibleApiClientProvider = Provider<BibleApiClient>((ref) {
  return BibleApiClient(ref.watch(dioProvider));
});
