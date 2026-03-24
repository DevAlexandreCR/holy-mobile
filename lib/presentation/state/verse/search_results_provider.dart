import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/data/bible/bible_repository.dart';
import 'package:holyverso/domain/verse/search_result.dart';

final searchResultsProvider = FutureProvider.autoDispose
    .family<SearchResult?, String>((ref, query) async {
      final trimmed = query.trim();
      if (trimmed.isEmpty) return null;
      final repository = ref.read(bibleRepositoryProvider);
      return repository.searchVerses(trimmed);
    });
