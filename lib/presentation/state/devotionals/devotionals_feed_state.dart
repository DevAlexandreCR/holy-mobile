import 'package:holyverso/domain/devotionals/devotional.dart';

enum DevotionalsFeedStatus { idle, loading, success, error }

class DevotionalsFeedState {
  const DevotionalsFeedState({
    this.items = const [],
    this.status = DevotionalsFeedStatus.idle,
    this.errorMessage,
    this.nextCursor,
    this.hasMore = true,
    this.isFetchingMore = false,
    this.likingDevotionalId,
    this.savingDevotionalId,
  });

  final List<Devotional> items;
  final DevotionalsFeedStatus status;
  final String? errorMessage;
  final String? nextCursor;
  final bool hasMore;
  final bool isFetchingMore;
  final String? likingDevotionalId;
  final String? savingDevotionalId;

  DevotionalsFeedState copyWith({
    List<Devotional>? items,
    DevotionalsFeedStatus? status,
    String? errorMessage,
    String? nextCursor,
    bool? hasMore,
    bool? isFetchingMore,
    String? likingDevotionalId,
    String? savingDevotionalId,
    bool clearError = false,
    bool clearNextCursor = false,
  }) {
    return DevotionalsFeedState(
      items: items ?? this.items,
      status: status ?? this.status,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      nextCursor: clearNextCursor ? null : nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      likingDevotionalId: likingDevotionalId ?? this.likingDevotionalId,
      savingDevotionalId: savingDevotionalId ?? this.savingDevotionalId,
    );
  }
}
