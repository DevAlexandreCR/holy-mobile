import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/core/theme/app_theme.dart';
import 'package:holyverso/data/auth/models/user.dart';
import 'package:holyverso/data/devotionals/devotionals_api_client.dart';
import 'package:holyverso/data/devotionals/devotionals_repository.dart';
import 'package:holyverso/domain/devotionals/devotional.dart';
import 'package:holyverso/domain/devotionals/devotional_author.dart';
import 'package:holyverso/domain/devotionals/devotional_feed_mode.dart';
import 'package:holyverso/domain/devotionals/devotional_moderation_status.dart';
import 'package:holyverso/domain/devotionals/devotional_publication_state.dart';
import 'package:holyverso/domain/devotionals/devotional_status.dart';
import 'package:holyverso/domain/devotionals/devotional_verse_reference.dart';
import 'package:holyverso/domain/roles/user_role.dart';
import 'package:holyverso/presentation/screens/devotionals/devotionals_list_screen.dart';
import 'package:holyverso/presentation/state/auth/auth_controller.dart';
import 'package:holyverso/presentation/state/auth/auth_state.dart';
import 'package:holyverso/presentation/state/devotionals/devotionals_feed_controller.dart';
import 'package:holyverso/presentation/state/devotionals/devotionals_feed_state.dart';
import 'package:holyverso/presentation/state/devotionals/devotional_review_queue_controller.dart';
import 'package:holyverso/presentation/state/devotionals/devotionals_list_controller.dart';
import 'package:holyverso/presentation/state/devotionals/devotionals_list_state.dart';
import 'package:holyverso/presentation/widgets/common/holy_child_app_bar.dart';
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

    expect(find.text('Devocionales'), findsOneWidget);
    expect(find.text('Para ti visible'), findsOneWidget);
    expect(find.text('Siguiendo visible'), findsNothing);
    expect(find.text('Mi devocional'), findsNothing);
    expect(find.byKey(const Key('devotionals-create-fab')), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);

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

  testWidgets('keeps full tab labels visible on narrow layouts', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 760));

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
        authState: AuthState(
          sessionStatus: AuthSessionStatus.authenticated,
          user: _testUser(UserRole.editor),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mis devocionales'), findsOneWidget);
    expect(find.text('En revisión'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('devotionals-tab-review')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('devotionals-tab-review')));
    await tester.pumpAndSettle();

    expect(find.text('No hay devocionales pendientes'), findsOneWidget);
  });

  testWidgets('renders public actions and triggers share flow', (tester) async {
    MethodCall? capturedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(shareChannel, (call) async {
          capturedCall = call;
          return 'shared';
        });

    final devotional = _buildDevotional(
      id: 'share-card',
      title: 'Compartible',
      computedHook: 'No cargues solo con lo que Dios quiere sostener contigo.',
    );

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

    expect(find.text('Recibe este mensaje →'), findsOneWidget);
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
      startsWith('No cargues solo con lo que Dios quiere sostener contigo.'),
    );
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
    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('opens devotional detail with secondary navigation app bar', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        forYouState: DevotionalsFeedState(
          status: DevotionalsFeedStatus.success,
          items: [_buildDevotional(id: 'detail-card', title: 'Detalle')],
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

    await tester.ensureVisible(find.text('Recibe este mensaje →'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recibe este mensaje →'));
    await tester.pumpAndSettle();

    expect(find.text('detail-screen'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('publish from mine tab preserves backend quality gate message', (
    tester,
  ) async {
    final apiClient = _FakeDevotionalsApiClient(
      publishError: DioException(
        requestOptions: RequestOptions(path: '/devotionals/mine/publish'),
        response: Response(
          requestOptions: RequestOptions(path: '/devotionals/mine/publish'),
          statusCode: 400,
          data: {
            'error': {
              'code': 'DEVOTIONAL_QUALITY_GATE_FAILED',
              'message': 'Agrega un poco más de reflexión antes de publicarlo.',
            },
          },
        ),
      ),
    );

    await tester.pumpWidget(
      _TestApp(
        apiClient: apiClient,
        forYouState: const DevotionalsFeedState(
          status: DevotionalsFeedStatus.success,
        ),
        followingState: const DevotionalsFeedState(
          status: DevotionalsFeedStatus.success,
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

    await tester.tap(find.byKey(const Key('devotionals-tab-mine')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Publicar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Publicar'));
    await tester.pumpAndSettle();

    expect(
      find.text('Agrega un poco más de reflexión antes de publicarlo.'),
      findsOneWidget,
    );
    expect(apiClient.publishCalls, 1);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({
    required this.forYouState,
    required this.followingState,
    required this.mineState,
    this.reviewState = const DevotionalsListState(
      status: DevotionalsListStatus.success,
    ),
    this.authState = const AuthState(sessionStatus: AuthSessionStatus.guest),
    this.apiClient,
  });

  final DevotionalsFeedState forYouState;
  final DevotionalsFeedState followingState;
  final DevotionalsListState mineState;
  final DevotionalsListState reviewState;
  final AuthState authState;
  final DevotionalsApiClient? apiClient;

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
              const Scaffold(appBar: HolyChildAppBar(title: 'create-screen')),
        ),
        GoRoute(
          path: '/devotionals/:id',
          builder: (context, state) =>
              const Scaffold(appBar: HolyChildAppBar(title: 'detail-screen')),
        ),
        GoRoute(
          path: '/devotionals/:id/edit',
          builder: (context, state) =>
              const Scaffold(appBar: HolyChildAppBar(title: 'edit-screen')),
        ),
        GoRoute(
          path: '/devotionals/preview',
          builder: (context, state) =>
              const Scaffold(appBar: HolyChildAppBar(title: 'preview-screen')),
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
          (ref) =>
              DevotionalsRepository(apiClient ?? _FakeDevotionalsApiClient()),
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
        devotionalReviewQueueControllerProvider.overrideWith(
          () => _StaticReviewQueueController(reviewState),
        ),
        authControllerProvider.overrideWith(
          () => _StaticAuthController(authState),
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
  _FakeDevotionalsApiClient({this.publishError}) : super(Dio());

  final Object? publishError;
  int publishCalls = 0;

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

  @override
  Future<Devotional> publishDevotional(String devotionalId) async {
    publishCalls += 1;
    if (publishError != null) {
      throw publishError!;
    }

    return _buildDevotional(
      id: devotionalId,
      title: 'Publicado',
      status: DevotionalStatus.published,
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
  Future<bool> toggleSave(String devotionalId) async => true;

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
  Future<bool> toggleSave(String devotionalId) async => true;

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

class _StaticReviewQueueController extends DevotionalReviewQueueController {
  _StaticReviewQueueController(this.initialState);

  final DevotionalsListState initialState;

  @override
  DevotionalsListState build() => initialState;

  @override
  Future<void> loadInitial({bool forceRefresh = false}) async {}

  @override
  Future<void> refresh() async {}

  @override
  Future<void> loadMore() async {}
}

class _StaticAuthController extends AuthController {
  _StaticAuthController(this.initialState);

  final AuthState initialState;

  @override
  AuthState build() => initialState;
}

User _testUser(UserRole role) {
  return User(
    id: 'user-1',
    name: 'Alexandre',
    email: 'alexandre@example.com',
    role: role,
  );
}

Devotional _buildDevotional({
  required String id,
  required String title,
  DevotionalStatus status = DevotionalStatus.published,
  String? computedHook,
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
    computedHook:
        computedHook ?? 'Hay dias en los que volver a Dios es respirar.',
    optimizedPreviewText:
        'Su gracia no te exige fingir fuerza; te invita a seguir desde la verdad.',
    hookSource: 'CONTENT_OPENING',
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
    feedContextReason: 'SAVED_BY_OTHERS',
    content: const [],
  );
}
