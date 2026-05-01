import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/data/notifications/notification_api_client.dart';
import 'package:holyverso/domain/core/cursor_paged_result.dart';
import 'package:holyverso/domain/notifications/notification_inbox_item.dart';

class NotificationInboxRepository {
  NotificationInboxRepository(this._client);

  final NotificationApiClient _client;

  Future<CursorPagedResult<NotificationInboxItem>> fetchInbox({
    String? cursor,
    int limit = 20,
    NotificationInboxFilter filter = NotificationInboxFilter.all,
  }) {
    return _client.fetchInbox(cursor: cursor, limit: limit, filter: filter);
  }

  Future<int> fetchUnreadCount() {
    return _client.fetchInboxUnreadCount();
  }

  Future<void> markItemRead(String id, {bool opened = false}) async {
    await _client.markInboxItemRead(id, opened: opened);
  }

  Future<int> markAllRead() {
    return _client.markAllInboxItemsRead();
  }
}

final notificationInboxRepositoryProvider =
    Provider<NotificationInboxRepository>((ref) {
      return NotificationInboxRepository(
        ref.watch(notificationApiClientProvider),
      );
    });
