import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/core/router/app_router.dart';
import 'package:holyverso/core/theme/app_theme.dart';
import 'package:holyverso/data/auth/models/user.dart';
import 'package:holyverso/data/auth/models/user_settings.dart';
import 'package:holyverso/data/notifications/notification_api_client.dart';
import 'package:holyverso/data/notifications/notification_inbox_repository.dart';
import 'package:holyverso/data/roles/role_repository.dart';
import 'package:holyverso/data/roles/roles_api_client.dart';
import 'package:holyverso/domain/core/cursor_paged_result.dart';
import 'package:holyverso/domain/notifications/notification_inbox_item.dart';
import 'package:holyverso/domain/verse/verse_of_the_day.dart';
import 'package:holyverso/domain/roles/user_role.dart';
import 'package:holyverso/presentation/providers/whats_new_provider.dart';
import 'package:holyverso/presentation/screens/auth/login_screen.dart';
import 'package:holyverso/presentation/screens/devotionals/devotionals_list_screen.dart';
import 'package:holyverso/presentation/screens/notifications/notification_inbox_screen.dart';
import 'package:holyverso/presentation/screens/settings/settings_screen.dart';
import 'package:holyverso/presentation/screens/search/search_screen.dart';
import 'package:holyverso/presentation/screens/users/users_list_screen.dart';
import 'package:holyverso/presentation/state/devotionals/devotional_review_queue_controller.dart';
import 'package:holyverso/presentation/state/devotionals/devotionals_feed_controller.dart';
import 'package:holyverso/presentation/state/devotionals/devotionals_feed_state.dart';
import 'package:holyverso/presentation/state/devotionals/devotionals_list_controller.dart';
import 'package:holyverso/presentation/state/devotionals/devotionals_list_state.dart';
import 'package:holyverso/presentation/screens/verse/saved_verses_screen.dart';
import 'package:holyverso/presentation/screens/verse/verse_of_the_day_screen.dart';
import 'package:holyverso/presentation/state/auth/auth_controller.dart';
import 'package:holyverso/presentation/state/auth/auth_state.dart';
import 'package:holyverso/presentation/state/devotionals/saved_devotionals_controller.dart';
import 'package:holyverso/presentation/state/devotionals/saved_devotionals_state.dart';
import 'package:holyverso/presentation/state/verse/saved_verses_controller.dart';
import 'package:holyverso/presentation/state/verse/saved_verses_state.dart';
import 'package:holyverso/presentation/state/verse/verse_controller.dart';
import 'package:holyverso/presentation/state/verse/verse_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('guest can access home and search', (tester) async {
    final container = _buildContainer(
      const AuthState(sessionStatus: AuthSessionStatus.guest),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const _TestApp()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(VerseOfTheDayScreen), findsOneWidget);

    container.read(appRouterProvider).go('/search');
    await tester.pumpAndSettle();

    expect(find.byType(SearchScreen), findsOneWidget);
  });

  testWidgets('authenticated users boot into devotionals feed', (tester) async {
    final container = _buildContainer(
      const AuthState(
        user: _user,
        sessionStatus: AuthSessionStatus.authenticated,
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const _TestApp()),
    );
    await tester.pumpAndSettle();

    final router = container.read(appRouterProvider);

    expect(find.byType(DevotionalsListScreen), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/devotionals');
  });

  testWidgets('guest is redirected from protected routes', (tester) async {
    final container = _buildContainer(
      const AuthState(sessionStatus: AuthSessionStatus.guest),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const _TestApp()),
    );
    await tester.pumpAndSettle();

    for (final route in ['/saved', '/settings', '/devotionals', '/notifications']) {
      container.read(appRouterProvider).go(route);
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    }
  });

  testWidgets('authenticated users can open notification inbox', (tester) async {
    final container = _buildContainer(
      const AuthState(
        user: _user,
        sessionStatus: AuthSessionStatus.authenticated,
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const _TestApp()),
    );
    await tester.pumpAndSettle();

    container.read(appRouterProvider).go('/notifications');
    await tester.pumpAndSettle();

    expect(find.byType(NotificationInboxScreen), findsOneWidget);
  });

  testWidgets('authenticatedStale can remain on protected routes', (
    tester,
  ) async {
    final container = _buildContainer(
      const AuthState(
        user: _user,
        sessionStatus: AuthSessionStatus.authenticatedStale,
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const _TestApp()),
    );
    await tester.pumpAndSettle();

    container.read(appRouterProvider).go('/saved');
    await tester.pumpAndSettle();

    expect(find.byType(SavedVersesScreen), findsOneWidget);
    expect(find.text('Versículos'), findsWidgets);
    expect(find.text('Devocionales'), findsWidgets);
  });

  testWidgets('saved route honors tab query parameter', (tester) async {
    final container = _buildContainer(
      const AuthState(
        user: _user,
        sessionStatus: AuthSessionStatus.authenticated,
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const _TestApp()),
    );
    await tester.pumpAndSettle();

    container.read(appRouterProvider).go('/saved?tab=devotionals');
    await tester.pumpAndSettle();

    expect(find.byType(SavedVersesScreen), findsOneWidget);
    expect(find.text('Aún no tienes devocionales guardados'), findsOneWidget);
  });

  testWidgets('expired session redirects to login with message', (
    tester,
  ) async {
    final container = _buildContainer(
      const AuthState(sessionStatus: AuthSessionStatus.expired),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const _TestApp()),
    );
    await tester.pumpAndSettle();

    final router = container.read(appRouterProvider);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/login');
    expect(
      router.routeInformationProvider.value.uri.queryParameters['message'],
      isNotEmpty,
    );
  });

  testWidgets(
    'authenticated users are redirected from auth routes to devotionals',
    (tester) async {
      final container = _buildContainer(
        const AuthState(
          user: _user,
          sessionStatus: AuthSessionStatus.authenticated,
        ),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const _TestApp(),
        ),
      );
      await tester.pumpAndSettle();

      container.read(appRouterProvider).go('/login');
      await tester.pumpAndSettle();

      final router = container.read(appRouterProvider);
      expect(find.byType(DevotionalsListScreen), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, '/devotionals');
    },
  );

  testWidgets(
    'bottom navigation shows Devotionals before Palabra with star icon',
    (tester) async {
      final container = _buildContainer(
        const AuthState(
          user: _user,
          sessionStatus: AuthSessionStatus.authenticated,
        ),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const _TestApp(),
        ),
      );
      await tester.pumpAndSettle();

      final bottomNav = find.byType(BottomNavigationBar);
      final devotionalsLabel = find.descendant(
        of: bottomNav,
        matching: find.text('Devocionales'),
      );
      final palabraLabel = find.descendant(
        of: bottomNav,
        matching: find.text('Palabra'),
      );

      expect(devotionalsLabel, findsOneWidget);
      expect(palabraLabel, findsOneWidget);
      expect(
        tester.getTopLeft(devotionalsLabel).dx,
        lessThan(tester.getTopLeft(palabraLabel).dx),
      );
      expect(find.byIcon(Icons.auto_awesome_rounded), findsWidgets);
      expect(find.byIcon(Icons.home_rounded), findsNothing);
    },
  );

  testWidgets('manager can access users route', (tester) async {
    final container = _buildContainer(
      const AuthState(
        user: _leadUser,
        sessionStatus: AuthSessionStatus.authenticated,
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const _TestApp()),
    );
    await tester.pumpAndSettle();

    container.read(appRouterProvider).go('/users');
    await tester.pumpAndSettle();

    expect(find.byType(UsersListScreen), findsOneWidget);
  });

  testWidgets('non manager is redirected from users route to profile', (
    tester,
  ) async {
    final container = _buildContainer(
      const AuthState(
        user: _user,
        settings: UserSettings(preferredVersionId: 4),
        sessionStatus: AuthSessionStatus.authenticated,
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const _TestApp()),
    );
    await tester.pumpAndSettle();

    container.read(appRouterProvider).go('/users');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      container.read(appRouterProvider).routeInformationProvider.value.uri.path,
      '/profile',
    );
  });

  testWidgets('profile settings remains visible after async role resolution', (
    tester,
  ) async {
    final roleCompleter = Completer<UserRole>();
    final container = _buildContainer(
      const AuthState(
        user: _adminUser,
        settings: UserSettings(preferredVersionId: 4),
        sessionStatus: AuthSessionStatus.authenticated,
      ),
      roleRepository: _DelayedRoleRepository(roleCompleter.future),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const _TestApp()),
    );
    await tester.pumpAndSettle();

    container.read(appRouterProvider).go('/profile/settings');
    await tester.pump();
    expect(find.byType(SettingsScreen), findsOneWidget);

    roleCompleter.complete(UserRole.admin);
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(
      container.read(appRouterProvider).routeInformationProvider.value.uri.path,
      '/profile/settings',
    );
  });
}

const _user = User(
  id: '1',
  name: 'Tester',
  email: 'tester@example.com',
  role: UserRole.user,
);

const _leadUser = User(
  id: '2',
  name: 'Lead',
  email: 'lead@example.com',
  role: UserRole.lead,
);

const _adminUser = User(
  id: '3',
  name: 'Admin',
  email: 'admin@example.com',
  role: UserRole.admin,
);

ProviderContainer _buildContainer(
  AuthState authState, {
  RoleRepository? roleRepository,
}) {
  return ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith(
        () => _StaticAuthController(authState),
      ),
      verseControllerProvider.overrideWith(_StaticVerseController.new),
      savedVersesControllerProvider.overrideWith(
        _StaticSavedVersesController.new,
      ),
      savedDevotionalsControllerProvider.overrideWith(
        _StaticSavedDevotionalsController.new,
      ),
      forYouFeedControllerProvider.overrideWith(
        _StaticForYouFeedController.new,
      ),
      followingFeedControllerProvider.overrideWith(
        _StaticFollowingFeedController.new,
      ),
      devotionalsListControllerProvider.overrideWith(
        _StaticDevotionalsListController.new,
      ),
      devotionalReviewQueueControllerProvider.overrideWith(
        _StaticDevotionalReviewQueueController.new,
      ),
      roleRepositoryProvider.overrideWith(
        (ref) => roleRepository ?? _StaticRoleRepository(authState.user?.role),
      ),
      notificationInboxRepositoryProvider.overrideWith(
        (ref) => _StaticNotificationInboxRepository(),
      ),
      whatsNewProvider.overrideWith((ref) async => null),
    ],
  );
}

class _TestApp extends ConsumerWidget {
  const _TestApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('es'),
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}

class _StaticAuthController extends AuthController {
  _StaticAuthController(this.initialState);

  final AuthState initialState;

  @override
  AuthState build() => initialState;
}

class _StaticVerseController extends VerseController {
  @override
  VerseState build() {
    return const VerseState(
      verse: VerseOfTheDay(
        date: '2024-01-01',
        versionCode: 'rv1960',
        versionName: 'Reina-Valera 1960',
        reference: 'Juan 3:16',
        text: 'Porque de tal manera amó Dios al mundo...',
      ),
    );
  }

  @override
  Future<void> loadVerse({bool forceRefresh = false}) async {}
}

class _StaticSavedVersesController extends SavedVersesController {
  @override
  SavedVersesState build() => const SavedVersesState();

  @override
  Future<void> loadInitialSaved() async {}
}

class _StaticSavedDevotionalsController extends SavedDevotionalsController {
  @override
  SavedDevotionalsState build() => const SavedDevotionalsState(
    status: SavedDevotionalsStatus.success,
    items: [],
    hasMore: false,
  );

  @override
  Future<void> loadInitial({bool forceRefresh = false}) async {}
}

class _StaticForYouFeedController extends ForYouFeedController {
  @override
  DevotionalsFeedState build() => const DevotionalsFeedState(
    status: DevotionalsFeedStatus.success,
    hasMore: false,
  );

  @override
  Future<void> loadInitial({bool forceRefresh = false}) async {}

  @override
  Future<void> refresh() async {}
}

class _StaticFollowingFeedController extends FollowingFeedController {
  @override
  DevotionalsFeedState build() => const DevotionalsFeedState(
    status: DevotionalsFeedStatus.success,
    hasMore: false,
  );

  @override
  Future<void> loadInitial({bool forceRefresh = false}) async {}

  @override
  Future<void> refresh() async {}
}

class _StaticDevotionalsListController extends DevotionalsListController {
  @override
  DevotionalsListState build() =>
      const DevotionalsListState(status: DevotionalsListStatus.success);

  @override
  Future<void> loadInitial({bool forceRefresh = false}) async {}

  @override
  Future<void> refresh() async {}
}

class _StaticDevotionalReviewQueueController
    extends DevotionalReviewQueueController {
  @override
  DevotionalsListState build() =>
      const DevotionalsListState(status: DevotionalsListStatus.success);

  @override
  Future<void> loadInitial({bool forceRefresh = false}) async {}

  @override
  Future<void> refresh() async {}
}

class _StaticRoleRepository extends RoleRepository {
  _StaticRoleRepository(this._role) : super(_NoopRolesApiClient());

  final UserRole? _role;

  @override
  Future<UserRole> getMyRole() async => _role ?? UserRole.user;
}

class _StaticNotificationInboxRepository extends NotificationInboxRepository {
  _StaticNotificationInboxRepository() : super(_StaticNotificationApiClient());

  @override
  Future<CursorPagedResult<NotificationInboxItem>> fetchInbox({
    String? cursor,
    int limit = 20,
    NotificationInboxFilter filter = NotificationInboxFilter.all,
  }) async {
    return const CursorPagedResult(
      items: [],
      nextCursor: null,
      hasMore: false,
    );
  }

  @override
  Future<int> fetchUnreadCount() async => 0;
}

class _StaticNotificationApiClient extends NotificationApiClient {
  _StaticNotificationApiClient() : super(Dio());
}

class _DelayedRoleRepository extends RoleRepository {
  _DelayedRoleRepository(this._futureRole) : super(_NoopRolesApiClient());

  final Future<UserRole> _futureRole;

  @override
  Future<UserRole> getMyRole() => _futureRole;
}

class _NoopRolesApiClient extends RolesApiClient {
  _NoopRolesApiClient() : super(Dio());
}
