import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/data/bible/bible_repository.dart';
import 'package:holyverso/domain/verse/book_suggestion.dart';

final autocompleteProvider = FutureProvider.autoDispose
    .family<List<BookSuggestion>, String>((ref, query) async {
  final trimmed = query.trim();
  if (trimmed.length < 2) return const [];
  final repository = ref.read(bibleRepositoryProvider);
  return repository.getAutocompleteSuggestions(trimmed);
});
