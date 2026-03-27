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
import 'package:holyverso/domain/devotionals/devotional_feed_mode.dart';
import 'package:holyverso/domain/devotionals/devotional_moderation_status.dart';
import 'package:holyverso/domain/devotionals/devotional_publication_state.dart';
import 'package:holyverso/domain/devotionals/devotional_status.dart';
import 'package:holyverso/domain/devotionals/devotional_verse_reference.dart';
import 'package:holyverso/domain/roles/user_role.dart';
import 'package:holyverso/presentation/state/auth/auth_controller.dart';
import 'package:holyverso/presentation/state/auth/auth_state.dart';
import 'package:holyverso/presentation/state/devotionals/devotionals_feed_controller.dart';

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
      expect(state.ownerUserId, 'user-1');
      expect(state.items.single.id, 'one');
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
  int fetchFeedCalls = 0;
  Object? recordFeedEventsError;

  void enqueueFeed(CursorPagedResult<Devotional> result) {
    _feedQueue.add(result);
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
  Future<void> recordFeedEvents(List<Map<String, dynamic>> events) async {
    final error = recordFeedEventsError;
    if (error != null) {
      throw error;
    }
  }
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
