import 'dart:collection';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/data/auth/models/user.dart';
import 'package:holyverso/data/devotionals/devotionals_api_client.dart';
import 'package:holyverso/data/devotionals/devotionals_repository.dart';
import 'package:holyverso/domain/core/cursor_paged_result.dart';
import 'package:holyverso/domain/devotionals/devotional.dart';
import 'package:holyverso/domain/devotionals/devotional_author.dart';
import 'package:holyverso/domain/devotionals/devotional_daily_featured.dart';
import 'package:holyverso/domain/devotionals/devotional_feed_mode.dart';
import 'package:holyverso/domain/devotionals/devotional_feed_header.dart';
import 'package:holyverso/domain/devotionals/devotional_moderation_status.dart';
import 'package:holyverso/domain/devotionals/devotional_publication_state.dart';
import 'package:holyverso/domain/devotionals/devotional_status.dart';
import 'package:holyverso/domain/devotionals/devotional_verse_reference.dart';
import 'package:holyverso/domain/roles/user_role.dart';
import 'package:holyverso/presentation/state/auth/auth_controller.dart';
import 'package:holyverso/presentation/state/auth/auth_state.dart';
import 'package:holyverso/presentation/screens/devotionals/devotional_feed_reader_args.dart';
import 'package:holyverso/presentation/state/devotionals/devotional_feed_reader_controller.dart';
import 'package:holyverso/presentation/state/devotionals/devotionals_feed_controller.dart';
import 'package:holyverso/presentation/state/devotionals/devotionals_feed_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ForYouFeedController', () {
    late _FakeAuthController authController;
    late _FakeDevotionalsRepository repository;
    late ProviderContainer container;

    setUp(() {
      authController = _FakeAuthController('user-1');
      repository = _FakeDevotionalsRepository();
      container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(() => authController),
          devotionalsRepositoryProvider.overrideWith((ref) => repository),
        ],
      );
      addTearDown(container.dispose);
    });

    test('keeps same-user cached feed without unnecessary reset', () async {
      repository.enqueueFeed(
        CursorPagedResult(
          items: [_buildDevotional(id: 'one', token: 'token-1')],
          nextCursor: 'cursor-1',
          hasMore: true,
        ),
      );

      await container.read(forYouFeedControllerProvider.notifier).loadInitial();
      await container.read(forYouFeedControllerProvider.notifier).loadInitial();

      final state = container.read(forYouFeedControllerProvider);
      expect(repository.fetchFeedCalls, 1);
      expect(repository.fetchFeedHeaderCalls, 1);
      expect(state.ownerUserId, 'user-1');
      expect(state.items.single.id, 'one');
      expect(state.feedHeader?.currentStreak, 5);
      expect(state.feedHeader?.dailyFeatured?.id, 'featured-1');
      expect(state.feedHeader?.primaryCtaType, 'OPEN_DAILY_FEATURED');
    });

    test('reloads feed when authenticated user changes', () async {
      repository.enqueueFeed(
        CursorPagedResult(
          items: [_buildDevotional(id: 'old', token: 'token-old')],
          nextCursor: null,
          hasMore: false,
        ),
      );
      repository.enqueueFeed(
        CursorPagedResult(
          items: [_buildDevotional(id: 'new', token: 'token-new')],
          nextCursor: null,
          hasMore: false,
        ),
      );

      await container.read(forYouFeedControllerProvider.notifier).loadInitial();
      authController.setUser('user-2');
      await container.read(forYouFeedControllerProvider.notifier).loadInitial();

      final state = container.read(forYouFeedControllerProvider);
      expect(repository.fetchFeedCalls, 2);
      expect(state.ownerUserId, 'user-2');
      expect(state.items.single.id, 'new');
      expect(state.items.single.deliveryToken, 'token-new');
    });

    test(
      'invalid feed delivery token triggers silent recovery refresh',
      () async {
        repository.enqueueFeed(
          CursorPagedResult(
            items: [_buildDevotional(id: 'stale', token: 'token-stale')],
            nextCursor: null,
            hasMore: false,
          ),
        );
        repository.enqueueFeed(
          CursorPagedResult(
            items: [_buildDevotional(id: 'fresh', token: 'token-fresh')],
            nextCursor: null,
            hasMore: false,
          ),
        );

        await container
            .read(forYouFeedControllerProvider.notifier)
            .loadInitial();
        final staleItem = container
            .read(forYouFeedControllerProvider)
            .items
            .single;
        repository.recordFeedEventsError = _backendError(
          'INVALID_DELIVERY_TOKEN',
        );

        await container
            .read(forYouFeedControllerProvider.notifier)
            .registerImpression(staleItem);

        final state = container.read(forYouFeedControllerProvider);
        expect(repository.fetchFeedCalls, 2);
        expect(state.items.single.id, 'fresh');
        expect(state.items.single.deliveryToken, 'token-fresh');
      },
    );

    test('non token feed event errors do not reset cached feed', () async {
      repository.enqueueFeed(
        CursorPagedResult(
          items: [_buildDevotional(id: 'stable', token: 'token-stable')],
          nextCursor: null,
          hasMore: false,
        ),
      );

      await container.read(forYouFeedControllerProvider.notifier).loadInitial();
      final stableItem = container
          .read(forYouFeedControllerProvider)
          .items
          .single;
      repository.recordFeedEventsError = _backendError('UNEXPECTED_FAILURE');

      await container
          .read(forYouFeedControllerProvider.notifier)
          .registerOpen(stableItem);

      final state = container.read(forYouFeedControllerProvider);
      expect(repository.fetchFeedCalls, 1);
      expect(state.items.single.id, 'stable');
      expect(state.items.single.deliveryToken, 'token-stable');
    });
  });

  group('DevotionalFeedReaderController', () {
    late _FakeAuthController authController;
    late _FakeDevotionalsRepository repository;
    late _MutableForYouFeedController feedController;
    late ProviderContainer container;

    setUp(() {
      authController = _FakeAuthController('user-1');
      repository = _FakeDevotionalsRepository();
      feedController = _MutableForYouFeedController(
        DevotionalsFeedState(
          status: DevotionalsFeedStatus.success,
          items: [
            _buildDevotional(id: 'one', token: 'token-1'),
            _buildDevotional(id: 'two', token: 'token-2'),
          ],
          hasMore: false,
        ),
      );
      container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(() => authController),
          devotionalsRepositoryProvider.overrideWith((ref) => repository),
          forYouFeedControllerProvider.overrideWith(() => feedController),
        ],
      );
      addTearDown(container.dispose);
    });

    test('next devotional comes from the same feed', () async {
      repository.stubDevotional(_buildDevotional(id: 'one', token: 'token-1'));
      repository.stubDevotional(_buildDevotional(id: 'two', token: 'token-2'));

      final controller = container.read(
        devotionalFeedReaderControllerProvider.notifier,
      );
      await controller.configure(
        readerArgs: const DevotionalFeedReaderArgs(
          feedMode: DevotionalFeedMode.forYou,
          initialDevotionalId: 'one',
          initialDeliveryToken: 'token-1',
        ),
        devotionalId: 'one',
        deliveryToken: 'token-1',
        deviceId: 'device-1',
      );

      final nextIndex = await controller.resolveNextIndex();
      expect(nextIndex, 1);

      await controller.activateIndex(nextIndex!);

      final state = container.read(devotionalFeedReaderControllerProvider);
      expect(state.activeDevotionalId, 'two');
      expect(repository.getDevotionalCalls, ['one', 'two']);
    });

    test(
      'loadMore is called when scrolling beyond the last loaded item',
      () async {
        repository.stubDevotional(
          _buildDevotional(id: 'one', token: 'token-1'),
        );
        container.read(forYouFeedControllerProvider);
        feedController.replaceState(
          DevotionalsFeedState(
            status: DevotionalsFeedStatus.success,
            items: [_buildDevotional(id: 'one', token: 'token-1')],
            hasMore: true,
          ),
        );
        feedController.onLoadMore = () async {
          feedController.replaceState(
            DevotionalsFeedState(
              status: DevotionalsFeedStatus.success,
              items: [
                _buildDevotional(id: 'one', token: 'token-1'),
                _buildDevotional(id: 'two', token: 'token-2'),
              ],
              hasMore: false,
            ),
          );
        };

        final controller = container.read(
          devotionalFeedReaderControllerProvider.notifier,
        );
        await controller.configure(
          readerArgs: const DevotionalFeedReaderArgs(
            feedMode: DevotionalFeedMode.forYou,
            initialDevotionalId: 'one',
            initialDeliveryToken: 'token-1',
          ),
          devotionalId: 'one',
          deliveryToken: 'token-1',
          deviceId: 'device-1',
        );

        final nextIndex = await controller.resolveNextIndex();

        expect(nextIndex, 1);
        expect(feedController.loadMoreCalls, 1);
      },
    );

    test('direct detail mode does not auto-chain', () async {
      repository.stubDevotional(_buildDevotional(id: 'one', token: 'token-1'));

      final controller = container.read(
        devotionalFeedReaderControllerProvider.notifier,
      );
      await controller.configure(devotionalId: 'one', deviceId: 'device-1');

      final nextIndex = await controller.resolveNextIndex();

      expect(nextIndex, isNull);
    });

    test('read-complete is still reported once per devotional', () async {
      repository.stubDevotional(_buildDevotional(id: 'one', token: 'token-1'));
      repository.stubDevotional(_buildDevotional(id: 'two', token: 'token-2'));

      final controller = container.read(
        devotionalFeedReaderControllerProvider.notifier,
      );
      await controller.configure(
        readerArgs: const DevotionalFeedReaderArgs(
          feedMode: DevotionalFeedMode.forYou,
          initialDevotionalId: 'one',
          initialDeliveryToken: 'token-1',
        ),
        devotionalId: 'one',
        deliveryToken: 'token-1',
        deviceId: 'device-1',
      );

      await controller.reportReadComplete();
      await controller.reportReadComplete();
      await controller.activateIndex(1);
      await controller.reportReadComplete();

      expect(repository.markReadCompleteCalls, ['one', 'two']);
    });
  });
}

class _FakeAuthController extends AuthController {
  _FakeAuthController(String? userId) : _initialUserId = userId;

  final String? _initialUserId;

  @override
  AuthState build() => _authStateFor(_initialUserId);

  void setUser(String? userId) {
    state = _authStateFor(userId);
  }

  AuthState _authStateFor(String? userId) {
    if (userId == null) {
      return const AuthState(sessionStatus: AuthSessionStatus.guest);
    }

    return AuthState(
      user: User(
        id: userId,
        name: 'Tester $userId',
        email: '$userId@example.com',
        role: UserRole.user,
      ),
      sessionStatus: AuthSessionStatus.authenticated,
    );
  }
}

class _FakeDevotionalsRepository extends DevotionalsRepository {
  _FakeDevotionalsRepository() : super(_NoopDevotionalsApiClient());

  final Queue<CursorPagedResult<Devotional>> _feedQueue =
      Queue<CursorPagedResult<Devotional>>();
  final Map<String, Devotional> _devotionalsById = <String, Devotional>{};
  int fetchFeedCalls = 0;
  int fetchFeedHeaderCalls = 0;
  final List<String> getDevotionalCalls = <String>[];
  final List<String> markReadCompleteCalls = <String>[];
  Object? recordFeedEventsError;

  void enqueueFeed(CursorPagedResult<Devotional> result) {
    _feedQueue.add(result);
  }

  void stubDevotional(Devotional devotional) {
    _devotionalsById[devotional.id] = devotional;
  }

  @override
  Future<CursorPagedResult<Devotional>> fetchFeed({
    required DevotionalFeedMode mode,
    String? cursor,
    int limit = 20,
  }) async {
    fetchFeedCalls += 1;
    if (_feedQueue.isEmpty) {
      return const CursorPagedResult(
        items: [],
        nextCursor: null,
        hasMore: false,
      );
    }
    return _feedQueue.removeFirst();
  }

  @override
  Future<DevotionalFeedHeader> fetchFeedHeader() async {
    fetchFeedHeaderCalls += 1;
    return const DevotionalFeedHeader(
      currentStreak: 5,
      longestStreak: 8,
      streakFreezeCount: 1,
      completedToday: false,
      dailyFeatured: DevotionalDailyFeatured(
        id: 'featured-1',
        title: 'Dios sigue obrando',
        estimatedReadTime: 3,
        previewText: 'Aunque hoy parezca lento...',
        previewImageUrl: null,
      ),
      primaryCtaType: 'OPEN_DAILY_FEATURED',
      primaryCtaLabel: 'Completa tu día',
      primaryCtaDevotionalId: 'featured-1',
    );
  }

  @override
  Future<void> recordFeedEvents(List<Map<String, dynamic>> events) async {
    final error = recordFeedEventsError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<Devotional> getDevotional(
    String id, {
    String? shareToken,
    String? deviceId,
  }) async {
    getDevotionalCalls.add(id);
    return _devotionalsById[id] ?? _buildDevotional(id: id, token: 'token-$id');
  }

  @override
  Future<int> markReadComplete(
    String devotionalId, {
    String? deliveryToken,
    String? shareToken,
    String? deviceId,
  }) async {
    markReadCompleteCalls.add(devotionalId);
    return markReadCompleteCalls.where((id) => id == devotionalId).length;
  }
}

class _MutableForYouFeedController extends ForYouFeedController {
  _MutableForYouFeedController(this.initialState);

  final DevotionalsFeedState initialState;
  int loadMoreCalls = 0;
  Future<void> Function()? onLoadMore;

  @override
  DevotionalsFeedState build() => initialState;

  void replaceState(DevotionalsFeedState nextState) {
    state = nextState;
  }

  @override
  Future<void> loadInitial({bool forceRefresh = false}) async {}

  @override
  Future<void> refresh() async {}

  @override
  Future<void> refreshHeader() async {}

  @override
  Future<void> loadMore() async {
    loadMoreCalls += 1;
    await onLoadMore?.call();
  }

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

class _NoopDevotionalsApiClient extends DevotionalsApiClient {
  _NoopDevotionalsApiClient() : super(Dio());
}

DioException _backendError(String code) {
  final requestOptions = RequestOptions(path: '/devotionals/feed/events');
  return DioException(
    requestOptions: requestOptions,
    response: Response(
      requestOptions: requestOptions,
      statusCode: 400,
      data: {
        'error': {'code': code, 'message': code},
      },
    ),
    type: DioExceptionType.badResponse,
  );
}

Devotional _buildDevotional({required String id, required String token}) {
  return Devotional(
    id: id,
    title: 'Devotional $id',
    status: DevotionalStatus.published,
    publicationState: DevotionalPublicationState.featured,
    moderationStatus: DevotionalModerationStatus.clear,
    effectiveState: 'CLEAR',
    moderationReason: null,
    coverImageUrl: null,
    previewImageUrl: null,
    previewText: 'Preview',
    computedHook: 'Cuando vuelves a Dios, tu alma encuentra aire.',
    optimizedPreviewText: 'El descanso tambien puede empezar con una oracion.',
    hookSource: 'CONTENT_OPENING',
    coverImageFocusY: 0,
    viewCount: 0,
    estimatedReadTime: 1,
    publishedAt: DateTime(2026, 3, 26),
    firstPublishedAt: DateTime(2026, 3, 26),
    createdAt: DateTime(2026, 3, 26),
    updatedAt: DateTime(2026, 3, 26),
    author: const DevotionalAuthor(
      id: 'author-1',
      name: 'Author',
      handle: 'author',
      avatarUrl: null,
      following: false,
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
    likesCount: 0,
    commentsCount: 0,
    shareCount: 0,
    saveCount: 0,
    readCompleteCount: 0,
    impressionCount: 0,
    uniqueImpressionCount: 0,
    reportCount: 0,
    openReportCount: 0,
    liked: false,
    saved: false,
    isOwner: false,
    canModerate: false,
    deliveryToken: token,
    recommendationReason: DevotionalFeedMode.forYou.name,
    feedContextReason: 'FEATURED',
    content: const [],
  );
}
