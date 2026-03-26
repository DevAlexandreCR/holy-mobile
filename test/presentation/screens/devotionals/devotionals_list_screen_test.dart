import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/core/theme/app_theme.dart';
import 'package:holyverso/data/devotionals/devotionals_api_client.dart';
import 'package:holyverso/data/devotionals/devotionals_repository.dart';
import 'package:holyverso/domain/devotionals/devotional.dart';
import 'package:holyverso/domain/devotionals/devotional_author.dart';
import 'package:holyverso/domain/devotionals/devotional_feed_mode.dart';
import 'package:holyverso/domain/devotionals/devotional_moderation_status.dart';
import 'package:holyverso/domain/devotionals/devotional_publication_state.dart';
import 'package:holyverso/domain/devotionals/devotional_status.dart';
import 'package:holyverso/domain/devotionals/devotional_verse_reference.dart';
import 'package:holyverso/presentation/screens/devotionals/devotionals_list_screen.dart';
import 'package:holyverso/presentation/state/devotionals/devotionals_feed_controller.dart';
import 'package:holyverso/presentation/state/devotionals/devotionals_feed_state.dart';
import 'package:holyverso/presentation/state/devotionals/devotionals_list_controller.dart';
import 'package:holyverso/presentation/state/devotionals/devotionals_list_state.dart';
import 'package:visibility_detector/visibility_detector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');

  setUpAll(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(shareChannel, null);
  });

  testWidgets('shows Para ti by default and switches top-level tabs', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        forYouState: DevotionalsFeedState(
          status: DevotionalsFeedStatus.success,
          items: [_buildDevotional(id: 'for-you', title: 'Para ti visible')],
        ),
        followingState: DevotionalsFeedState(
          status: DevotionalsFeedStatus.success,
          items: [
            _buildDevotional(id: 'following', title: 'Siguiendo visible'),
          ],
        ),
        mineState: DevotionalsListState(
          status: DevotionalsListStatus.success,
          items: [
            _buildDevotional(
              id: 'mine',
              title: 'Mi devocional',
              status: DevotionalStatus.draft,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Para ti visible'), findsOneWidget);
    expect(find.text('Siguiendo visible'), findsNothing);
    expect(find.text('Mi devocional'), findsNothing);
    expect(find.byKey(const Key('devotionals-create-fab')), findsOneWidget);

    await tester.tap(find.byKey(const Key('devotionals-tab-following')));
    await tester.pumpAndSettle();

    expect(find.text('Siguiendo visible'), findsOneWidget);
    expect(find.text('Para ti visible'), findsNothing);

    await tester.tap(find.byKey(const Key('devotionals-tab-mine')));
    await tester.pumpAndSettle();

    expect(find.text('Mi devocional'), findsOneWidget);
    expect(find.text('Editar devocional'), findsOneWidget);
    expect(find.text('Publicar'), findsOneWidget);
  });

  testWidgets('renders public actions and triggers share flow', (tester) async {
    MethodCall? capturedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(shareChannel, (call) async {
          capturedCall = call;
          return 'shared';
        });

    final devotional = _buildDevotional(id: 'share-card', title: 'Compartible');

    await tester.pumpWidget(
      _TestApp(
        forYouState: DevotionalsFeedState(
          status: DevotionalsFeedStatus.success,
          items: [devotional],
        ),
        followingState: const DevotionalsFeedState(
          status: DevotionalsFeedStatus.success,
        ),
        mineState: const DevotionalsListState(
          status: DevotionalsListStatus.success,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Leer completo ->'), findsOneWidget);
    expect(
      find.byKey(const Key('public-devotional-like-share-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('public-devotional-save-share-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('public-devotional-share-share-card')),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(const Key('public-devotional-share-share-card')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('public-devotional-share-share-card')),
    );
    await tester.pumpAndSettle();

    expect(capturedCall?.method, 'share');
    expect((capturedCall?.arguments as Map)['subject'], 'Compartir');
    expect(
      (capturedCall?.arguments as Map)['text'],
      contains('https://holyverso.com/devotionals/share-card'),
    );
  });

  testWidgets('fab opens devotional create route', (tester) async {
    await tester.pumpWidget(
      _TestApp(
        forYouState: const DevotionalsFeedState(
          status: DevotionalsFeedStatus.success,
        ),
        followingState: const DevotionalsFeedState(
          status: DevotionalsFeedStatus.success,
        ),
        mineState: const DevotionalsListState(
          status: DevotionalsListStatus.success,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('devotionals-create-fab')));
    await tester.pumpAndSettle();

    expect(find.text('create-screen'), findsOneWidget);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({
    required this.forYouState,
    required this.followingState,
    required this.mineState,
  });

  final DevotionalsFeedState forYouState;
  final DevotionalsFeedState followingState;
  final DevotionalsListState mineState;

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/devotionals',
      routes: [
        GoRoute(
          path: '/devotionals',
          builder: (context, state) => const DevotionalsListScreen(),
        ),
        GoRoute(
          path: '/devotionals/create',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('create-screen'))),
        ),
        GoRoute(
          path: '/devotionals/:id',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('detail-screen'))),
        ),
        GoRoute(
          path: '/devotionals/:id/edit',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('edit-screen'))),
        ),
        GoRoute(
          path: '/devotionals/preview',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('preview-screen'))),
        ),
        GoRoute(
          path: '/users/:id',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('user-screen'))),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        devotionalsRepositoryProvider.overrideWith(
          (ref) => DevotionalsRepository(_FakeDevotionalsApiClient()),
        ),
        forYouFeedControllerProvider.overrideWith(
          () => _StaticForYouFeedController(forYouState),
        ),
        followingFeedControllerProvider.overrideWith(
          () => _StaticFollowingFeedController(followingState),
        ),
        devotionalsListControllerProvider.overrideWith(
          () => _StaticDevotionalsListController(mineState),
        ),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        routerConfig: router,
      ),
    );
  }
}

class _FakeDevotionalsApiClient extends DevotionalsApiClient {
  _FakeDevotionalsApiClient() : super(Dio());

  @override
  Future<({int shareCount, String shareUrl})> shareDevotional(
    String devotionalId, {
    String? deliveryToken,
  }) async {
    return (
      shareCount: 1,
      shareUrl: 'https://holyverso.com/devotionals/$devotionalId',
    );
  }
}

class _StaticForYouFeedController extends ForYouFeedController {
  _StaticForYouFeedController(this.initialState);

  final DevotionalsFeedState initialState;

  @override
  DevotionalsFeedState build() => initialState;

  @override
  Future<void> loadInitial({bool forceRefresh = false}) async {}

  @override
  Future<void> refresh() async {}

  @override
  Future<void> loadMore() async {}

  @override
  Future<void> toggleLike(String devotionalId) async {}

  @override
  Future<void> toggleSave(String devotionalId) async {}

  @override
  Future<void> registerImpression(Devotional devotional) async {}

  @override
  Future<void> registerOpen(Devotional devotional) async {}

  @override
  Future<void> registerShare(Devotional devotional, {int? shareCount}) async {}

  @override
  void syncUpdatedDevotional(Devotional devotional) {}
}

class _StaticFollowingFeedController extends FollowingFeedController {
  _StaticFollowingFeedController(this.initialState);

  final DevotionalsFeedState initialState;

  @override
  DevotionalsFeedState build() => initialState;

  @override
  Future<void> loadInitial({bool forceRefresh = false}) async {}

  @override
  Future<void> refresh() async {}

  @override
  Future<void> loadMore() async {}

  @override
  Future<void> toggleLike(String devotionalId) async {}

  @override
  Future<void> toggleSave(String devotionalId) async {}

  @override
  Future<void> registerImpression(Devotional devotional) async {}

  @override
  Future<void> registerOpen(Devotional devotional) async {}

  @override
  Future<void> registerShare(Devotional devotional, {int? shareCount}) async {}

  @override
  void syncUpdatedDevotional(Devotional devotional) {}
}

class _StaticDevotionalsListController extends DevotionalsListController {
  _StaticDevotionalsListController(this.initialState);

  final DevotionalsListState initialState;

  @override
  DevotionalsListState build() => initialState;

  @override
  Future<void> loadInitial({bool forceRefresh = false}) async {}

  @override
  Future<void> refresh() async {}

  @override
  Future<void> loadMore() async {}

  @override
  void setStatusFilter(DevotionalStatus status) {
    state = state.copyWith(statusFilter: status);
  }
}

Devotional _buildDevotional({
  required String id,
  required String title,
  DevotionalStatus status = DevotionalStatus.published,
}) {
  return Devotional(
    id: id,
    title: title,
    status: status,
    publicationState: status == DevotionalStatus.archived
        ? DevotionalPublicationState.archived
        : status == DevotionalStatus.draft
        ? DevotionalPublicationState.draft
        : DevotionalPublicationState.featured,
    moderationStatus: DevotionalModerationStatus.clear,
    effectiveState: 'CLEAR',
    moderationReason: null,
    coverImageUrl: '',
    previewImageUrl: '',
    previewText: 'Texto breve para validar la jerarquía del card.',
    coverImageFocusY: 0,
    viewCount: 12,
    estimatedReadTime: 5,
    publishedAt: DateTime(2026, 3, 25),
    firstPublishedAt: DateTime(2026, 3, 25),
    createdAt: DateTime(2026, 3, 25),
    updatedAt: DateTime(2026, 3, 25),
    author: const DevotionalAuthor(
      id: 'author-1',
      name: 'Gabriel M.',
      handle: 'gabriel',
      avatarUrl: null,
      following: true,
    ),
    verseReferences: const [
      DevotionalVerseReference(
        id: 'ref-1',
        book: 'Juan',
        chapter: 3,
        verseStart: 16,
        isPrimary: true,
      ),
    ],
    likesCount: 12,
    commentsCount: 4,
    shareCount: 2,
    saveCount: 3,
    readCompleteCount: 0,
    impressionCount: 0,
    uniqueImpressionCount: 0,
    reportCount: 0,
    openReportCount: 0,
    liked: false,
    saved: false,
    isOwner: status != DevotionalStatus.published,
    canModerate: false,
    deliveryToken: 'delivery-$id',
    recommendationReason: DevotionalFeedMode.forYou.name,
    content: const [],
  );
}
