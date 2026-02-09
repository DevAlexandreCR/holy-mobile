import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchHistoryNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => const [];

  void addSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final updated = [
      trimmed,
      ...state.where((item) => item.toLowerCase() != trimmed.toLowerCase()),
    ];

    state = updated.take(8).toList();
  }

  void clear() {
    state = const [];
  }
}

final searchHistoryProvider =
    NotifierProvider<SearchHistoryNotifier, List<String>>(
  SearchHistoryNotifier.new,
);
