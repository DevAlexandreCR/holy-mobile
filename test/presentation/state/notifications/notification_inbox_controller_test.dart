import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/data/notifications/notification_api_client.dart';
import 'package:holyverso/data/notifications/notification_inbox_repository.dart';
import 'package:holyverso/domain/core/cursor_paged_result.dart';
import 'package:holyverso/domain/notifications/notification_inbox_item.dart';
import 'package:holyverso/presentation/state/notifications/notification_inbox_controller.dart';
import 'package:holyverso/presentation/state/notifications/notification_unread_count_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('markItemRead updates unread filter state and unread badge count', () async {
    final repository = _FakeNotificationInboxRepository();
    final container = ProviderContainer(
      overrides: [
        notificationInboxRepositoryProvider.overrideWith((ref) => repository),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(notificationInboxControllerProvider.notifier)
        .setFilter(NotificationInboxFilter.unread);

    final before = container.read(notificationInboxControllerProvider);
    expect(before.items, hasLength(1));

    await container
        .read(notificationInboxControllerProvider.notifier)
        .markItemRead(before.items.single);

    final after = container.read(notificationInboxControllerProvider);
    final unreadCount = container.read(
      notificationUnreadCountControllerProvider,
    );

    expect(after.items, isEmpty);
    expect(unreadCount.asData?.value, 0);
    expect(repository.markReadCalls, ['notif-1']);
  });
}

class _FakeNotificationInboxRepository extends NotificationInboxRepository {
  _FakeNotificationInboxRepository() : super(_NoopNotificationApiClient());

  final List<String> markReadCalls = [];

  @override
  Future<CursorPagedResult<NotificationInboxItem>> fetchInbox({
    String? cursor,
    int limit = 20,
    NotificationInboxFilter filter = NotificationInboxFilter.all,
  }) async {
    return CursorPagedResult(
      items: [
        NotificationInboxItem(
          id: 'notif-1',
          type: NotificationInboxType.devotionalComment,
          title: 'Nuevo comentario',
          body: 'Ana comentó en tu devocional.',
          aggregateCount: 1,
          actorPreview: const [
            NotificationInboxActorPreview(id: 'user-2', name: 'Ana'),
          ],
          isRead: false,
          createdAt: DateTime(2026, 4, 30, 10),
          destination: const NotificationInboxDestination(
            type: NotificationInboxDestinationType.devotional,
            devotionalId: 'devotional-1',
          ),
        ),
      ],
      nextCursor: null,
      hasMore: false,
    );
  }

  @override
  Future<int> fetchUnreadCount() async => 1;

  @override
  Future<void> markItemRead(String id, {bool opened = false}) async {
    markReadCalls.add(id);
  }

  @override
  Future<int> markAllRead() async => 1;
}

class _NoopNotificationApiClient extends NotificationApiClient {
  _NoopNotificationApiClient() : super(Dio());
}
