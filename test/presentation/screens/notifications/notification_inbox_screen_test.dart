import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:holyverso/data/notifications/notification_api_client.dart';
import 'package:holyverso/data/notifications/notification_inbox_repository.dart';
import 'package:holyverso/domain/core/cursor_paged_result.dart';
import 'package:holyverso/domain/notifications/notification_inbox_item.dart';
import 'package:holyverso/presentation/screens/notifications/notification_inbox_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'opening an inbox notification navigates with go and marks it opened',
    (tester) async {
      final repository = _FakeNotificationInboxRepository();
      final router = GoRouter(
        initialLocation: '/notifications',
        routes: [
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationInboxScreen(),
          ),
          GoRoute(
            path: '/users/:id',
            builder: (context, state) =>
                Scaffold(body: Text('user:${state.pathParameters['id']}')),
          ),
          GoRoute(
            path: '/devotionals/:id',
            builder: (context, state) => Scaffold(
              body: Text('devotional:${state.pathParameters['id']}'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationInboxRepositoryProvider.overrideWith(
              (ref) => repository,
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nuevo seguidor'), findsOneWidget);

      await tester.tap(find.text('Nuevo seguidor'));
      await tester.pumpAndSettle();

      expect(find.text('user:creator-1'), findsOneWidget);
      expect(repository.markReadCalls, [('notif-1', true)]);
    },
  );
}

class _FakeNotificationInboxRepository extends NotificationInboxRepository {
  _FakeNotificationInboxRepository() : super(_NoopNotificationApiClient());

  final List<(String, bool)> markReadCalls = [];

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
          type: NotificationInboxType.newFollower,
          title: 'Nuevo seguidor',
          body: 'Ana ahora te sigue.',
          aggregateCount: 1,
          actorPreview: const [
            NotificationInboxActorPreview(id: 'user-2', name: 'Ana'),
          ],
          creator: const NotificationInboxCreatorSummary(
            id: 'creator-1',
            name: 'Ana',
          ),
          destination: const NotificationInboxDestination(
            type: NotificationInboxDestinationType.creatorProfile,
            creatorId: 'creator-1',
          ),
          isRead: false,
          createdAt: DateTime(2026, 4, 30, 21, 30),
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
    markReadCalls.add((id, opened));
  }

  @override
  Future<int> markAllRead() async => 1;
}

class _NoopNotificationApiClient extends NotificationApiClient {
  _NoopNotificationApiClient() : super(Dio());
}
