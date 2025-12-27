import 'package:holyverso/domain/verse/saved_verse.dart';

enum SavedVersesStatus { idle, loading, success, error }

class SavedVersesState {
  const SavedVersesState({
    this.status = SavedVersesStatus.idle,
    this.items = const [],
    this.nextCursor,
    this.isFetchingMore = false,
    this.error,
    this.savedIds = const {},
    this.pendingIds = const {},
  });

  final SavedVersesStatus status;
  final List<SavedVerse> items;
  final String? nextCursor;
  final bool isFetchingMore;
  final String? error;
  final Set<int> savedIds;
  final Set<int> pendingIds;

  bool get isLoading => status == SavedVersesStatus.loading;
  bool get hasError => error != null;

  SavedVersesState copyWith({
    SavedVersesStatus? status,
    List<SavedVerse>? items,
    String? nextCursor,
    bool? isFetchingMore,
    String? error,
    Set<int>? savedIds,
    Set<int>? pendingIds,
    bool clearError = false,
  }) {
    return SavedVersesState(
      status: status ?? this.status,
      items: items ?? this.items,
      nextCursor: nextCursor ?? this.nextCursor,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      error: clearError ? null : error ?? this.error,
      savedIds: savedIds ?? this.savedIds,
      pendingIds: pendingIds ?? this.pendingIds,
    );
  }
}
