import 'package:holyverso/domain/devotionals/devotional_comment.dart';

enum DevotionalCommentsStatus { idle, loading, success, error }

class DevotionalCommentsState {
  const DevotionalCommentsState({
    this.items = const [],
    this.status = DevotionalCommentsStatus.idle,
    this.errorMessage,
    this.page = 1,
    this.limit = 50,
    this.total = 0,
    this.isFetchingMore = false,
    this.devotionalId,
  });

  final List<DevotionalComment> items;
  final DevotionalCommentsStatus status;
  final String? errorMessage;
  final int page;
  final int limit;
  final int total;
  final bool isFetchingMore;
  final String? devotionalId;

  bool get hasMore => page * limit < total;

  DevotionalCommentsState copyWith({
    List<DevotionalComment>? items,
    DevotionalCommentsStatus? status,
    String? errorMessage,
    int? page,
    int? limit,
    int? total,
    bool? isFetchingMore,
    String? devotionalId,
    bool clearError = false,
  }) {
    return DevotionalCommentsState(
      items: items ?? this.items,
      status: status ?? this.status,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      devotionalId: devotionalId ?? this.devotionalId,
    );
  }
}
