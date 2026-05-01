import 'package:holyverso/domain/notifications/notification_inbox_item.dart';

class NotificationInboxState {
  const NotificationInboxState({
    this.items = const [],
    this.nextCursor,
    this.hasMore = true,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isMarkingAllRead = false,
    this.filter = NotificationInboxFilter.all,
    this.errorMessage,
  });

  final List<NotificationInboxItem> items;
  final String? nextCursor;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isMarkingAllRead;
  final NotificationInboxFilter filter;
  final String? errorMessage;

  NotificationInboxState copyWith({
    List<NotificationInboxItem>? items,
    String? nextCursor,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isMarkingAllRead,
    NotificationInboxFilter? filter,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotificationInboxState(
      items: items ?? this.items,
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isMarkingAllRead: isMarkingAllRead ?? this.isMarkingAllRead,
      filter: filter ?? this.filter,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
