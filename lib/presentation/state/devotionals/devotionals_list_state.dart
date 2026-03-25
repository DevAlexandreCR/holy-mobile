import 'package:holyverso/domain/devotionals/devotional.dart';
import 'package:holyverso/domain/devotionals/devotional_status.dart';

enum DevotionalsListStatus { idle, loading, success, error }

class DevotionalsListState {
  const DevotionalsListState({
    this.items = const [],
    this.status = DevotionalsListStatus.idle,
    this.errorMessage,
    this.page = 1,
    this.limit = 20,
    this.total = 0,
    this.isFetchingMore = false,
    this.statusFilter = DevotionalStatus.published,
  });

  final List<Devotional> items;
  final DevotionalsListStatus status;
  final String? errorMessage;
  final int page;
  final int limit;
  final int total;
  final bool isFetchingMore;
  final DevotionalStatus statusFilter;

  bool get hasMore => page * limit < total;

  DevotionalsListState copyWith({
    List<Devotional>? items,
    DevotionalsListStatus? status,
    String? errorMessage,
    int? page,
    int? limit,
    int? total,
    bool? isFetchingMore,
    DevotionalStatus? statusFilter,
    bool clearError = false,
  }) {
    return DevotionalsListState(
      items: items ?? this.items,
      status: status ?? this.status,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}
