import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/data/notifications/notification_inbox_repository.dart';
import 'package:holyverso/domain/notifications/notification_inbox_item.dart';
import 'package:holyverso/presentation/state/notifications/notification_inbox_state.dart';
import 'package:holyverso/presentation/state/notifications/notification_unread_count_controller.dart';

class NotificationInboxController extends Notifier<NotificationInboxState> {
  @override
  NotificationInboxState build() {
    return const NotificationInboxState();
  }

  NotificationInboxRepository get _repository =>
      ref.read(notificationInboxRepositoryProvider);

  Future<void> load({bool force = false}) async {
    if (state.isLoading && !force) {
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _repository.fetchInbox(filter: state.filter);
      state = state.copyWith(
        items: result.items,
        nextCursor: result.nextCursor,
        hasMore: result.hasMore,
        isLoading: false,
      );
      await ref
          .read(notificationUnreadCountControllerProvider.notifier)
          .refresh();
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudieron cargar las notificaciones.',
      );
    }
  }

  Future<void> refresh() {
    return load(force: true);
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.nextCursor == null) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, clearError: true);

    try {
      final result = await _repository.fetchInbox(
        filter: state.filter,
        cursor: state.nextCursor,
      );
      state = state.copyWith(
        items: [...state.items, ...result.items],
        nextCursor: result.nextCursor,
        hasMore: result.hasMore,
        isLoadingMore: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: 'No se pudieron cargar más notificaciones.',
      );
    }
  }

  Future<void> setFilter(NotificationInboxFilter filter) async {
    if (state.filter == filter) {
      return;
    }

    state = state.copyWith(
      filter: filter,
      items: const [],
      nextCursor: null,
      hasMore: true,
      clearError: true,
    );
    await load(force: true);
  }

  Future<void> markItemRead(
    NotificationInboxItem item, {
    bool opened = false,
  }) async {
    if (item.isRead && !opened) {
      return;
    }

    await _repository.markItemRead(item.id, opened: opened);
    final updatedItem = item.copyWith(
      isRead: true,
      readAt: item.readAt ?? DateTime.now(),
      openedAt: opened ? (item.openedAt ?? DateTime.now()) : item.openedAt,
    );

    final nextItems = state.filter == NotificationInboxFilter.unread
        ? state.items.where((entry) => entry.id != item.id).toList()
        : state.items
              .map((entry) => entry.id == item.id ? updatedItem : entry)
              .toList();

    state = state.copyWith(items: nextItems);

    if (!item.isRead) {
      ref.read(notificationUnreadCountControllerProvider.notifier).decrement();
    }
  }

  Future<void> markAllRead() async {
    if (state.isMarkingAllRead || state.items.isEmpty) {
      return;
    }

    state = state.copyWith(isMarkingAllRead: true, clearError: true);

    try {
      await _repository.markAllRead();
      state = state.copyWith(
        items: state.filter == NotificationInboxFilter.unread
            ? const []
            : state.items
                  .map(
                    (item) => item.copyWith(
                      isRead: true,
                      readAt: item.readAt ?? DateTime.now(),
                    ),
                  )
                  .toList(),
        hasMore: state.filter == NotificationInboxFilter.unread
            ? false
            : state.hasMore,
        isMarkingAllRead: false,
      );
      ref.read(notificationUnreadCountControllerProvider.notifier).clear();
    } catch (error) {
      state = state.copyWith(
        isMarkingAllRead: false,
        errorMessage: 'No se pudieron marcar como leídas.',
      );
    }
  }
}

final notificationInboxControllerProvider =
    NotifierProvider<NotificationInboxController, NotificationInboxState>(
      NotificationInboxController.new,
    );
