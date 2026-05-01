import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/core/theme/app_theme.dart';
import 'package:holyverso/domain/devotionals/devotional.dart';
import 'package:holyverso/domain/devotionals/devotional_author.dart';
import 'package:holyverso/domain/devotionals/devotional_comment.dart';
import 'package:holyverso/domain/devotionals/devotional_feed_mode.dart';
import 'package:holyverso/domain/devotionals/devotional_moderation_status.dart';
import 'package:holyverso/domain/devotionals/devotional_publication_state.dart';
import 'package:holyverso/domain/devotionals/devotional_status.dart';
import 'package:holyverso/domain/devotionals/devotional_verse_reference.dart';
import 'package:holyverso/presentation/screens/devotionals/devotional_detail_screen.dart';
import 'package:holyverso/presentation/screens/devotionals/devotional_feed_reader_args.dart';
import 'package:holyverso/presentation/state/devotionals/devotional_comments_controller.dart';
import 'package:holyverso/presentation/state/devotionals/devotional_comments_state.dart';
import 'package:holyverso/presentation/state/devotionals/devotional_detail_controller.dart';
import 'package:holyverso/presentation/state/devotionals/devotional_detail_state.dart';
import 'package:holyverso/presentation/state/devotionals/devotional_feed_reader_controller.dart';
import 'package:holyverso/presentation/state/devotionals/devotional_feed_reader_state.dart';
import 'package:holyverso/presentation/state/devotionals/devotionals_feed_controller.dart';
import 'package:holyverso/presentation/state/devotionals/devotionals_feed_state.dart';
import 'package:holyverso/presentation/widgets/devotionals/devotional_content_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows mapped continuity copy from feed context', (tester) async {
    await tester.pumpWidget(
      _TestApp(
        devotional: _buildDevotional(feedContextReason: 'HIGH_COMPLETION'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Se está leyendo hasta el final'), findsOneWidget);
    expect(find.text('Esto es para ti'), findsNothing);
  });

  testWidgets('falls back to feed CTA only for forYou recommendation', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(devotional: _buildDevotional(recommendationReason: 'forYou')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Esto es para ti'), findsOneWidget);
  });

  testWidgets('omits continuity copy without recommendation context', (
    tester,
  ) async {
    await tester.pumpWidget(_TestApp(devotional: _buildDevotional()));
    await tester.pumpAndSettle();

    expect(find.text('Esto es para ti'), findsNothing);
    expect(find.text('Se está leyendo hasta el final'), findsNothing);
    expect(find.text('Muchos lo están guardando'), findsNothing);
  });

  testWidgets('shows reflection flow and warm empty comments state', (
    tester,
  ) async {
    await tester.pumpWidget(_TestApp(devotional: _buildDevotional()));
    await tester.pumpAndSettle();

    expect(find.text('Comentarios (0)'), findsNothing);
    expect(find.text('Comentarios'), findsOneWidget);
    expect(find.text('Sé el primero en comentar'), findsOneWidget);
    expect(find.text('Comparte tu reflexión'), findsOneWidget);
    expect(find.text('Tómate un momento para reflexionar'), findsOneWidget);

    final contentY = tester.getTopLeft(find.byType(DevotionalContentView)).dy;
    final reflectionY = tester
        .getTopLeft(find.text('Tómate un momento para reflexionar'))
        .dy;
    final saveY = tester.getTopLeft(find.text('Guardar')).dy;
    final commentsY = tester.getTopLeft(find.text('Comentarios')).dy;

    expect(contentY, lessThan(reflectionY));
    expect(reflectionY, lessThan(saveY));
    expect(saveY, lessThan(commentsY));
  });

  testWidgets('moves report action to overflow menu', (tester) async {
    await tester.pumpWidget(_TestApp(devotional: _buildDevotional()));
    await tester.pumpAndSettle();

    expect(find.text('Reportar'), findsNothing);

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Reportar'), findsOneWidget);
  });

  testWidgets('uses titleless hero header when cover image exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(devotional: _buildDevotional(withCover: true)),
    );
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    final heroLeft = tester.getTopLeft(
      find.byKey(const Key('devotional-detail-hero')),
    );
    final titleLeft = tester.getTopLeft(find.text('Un descanso para hoy'));

    expect(scaffold.extendBodyBehindAppBar, isTrue);
    expect(find.text('Detalle del devocional'), findsNothing);
    expect(find.byType(BackButton), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);
    expect(
      find.byKey(const Key('devotional-detail-hero-image')),
      findsOneWidget,
    );
    expect(heroLeft.dx, 0);
    expect(titleLeft.dx, greaterThan(0));
    expect(heroLeft.dy, lessThan(titleLeft.dy));
  });

  testWidgets(
    'falls back to a simple titleless header when cover image is absent',
    (tester) async {
      await tester.pumpWidget(
        _TestApp(devotional: _buildDevotional(withCover: false)),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      final titleLeft = tester.getTopLeft(find.text('Un descanso para hoy'));

      expect(scaffold.extendBodyBehindAppBar, isFalse);
      expect(find.text('Detalle del devocional'), findsNothing);
      expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);
      expect(find.byKey(const Key('devotional-detail-hero')), findsNothing);
      expect(titleLeft.dx, greaterThan(0));
    },
  );

  testWidgets('preserves the saved hero focus alignment when cover exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        devotional: _buildDevotional(withCover: true, coverImageFocusY: 0.45),
      ),
    );
    await tester.pumpAndSettle();

    final heroFinder = find.byKey(const Key('devotional-detail-hero'));
    final hero = tester.getSize(heroFinder);
    final heroContext = tester.element(heroFinder);
    final topInset = MediaQuery.paddingOf(heroContext).top;
    final heroImage = tester.widget<CachedNetworkImage>(
      find.byKey(const Key('devotional-detail-hero-image')),
    );

    expect(hero.height, closeTo(topInset + kToolbarHeight + 129, 0.01));
    expect(heroImage.fit, BoxFit.cover);
    expect(heroImage.alignment, const Alignment(0, 0.45));
  });

  testWidgets(
    'public reader shows action rail counters and removes inline comments',
    (tester) async {
      final devotional = _buildDevotional(withCover: true);
      final readerArgs = const DevotionalFeedReaderArgs(
        feedMode: DevotionalFeedMode.forYou,
        initialDevotionalId: 'devotional-1',
        initialDeliveryToken: 'delivery-1',
        heroTag: 'hero-1',
      );

      await tester.pumpWidget(
        _TestApp(
          devotional: devotional,
          readerArgs: readerArgs,
          readerState: DevotionalFeedReaderState(
            readerArgs: readerArgs,
            activeDevotionalId: 'devotional-1',
            activeIndex: 0,
            status: DevotionalFeedReaderStatus.success,
            loadedDevotionals: {'devotional-1': devotional},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('public-feed-reader-action-rail')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('public-feed-reader-save-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('public-feed-reader-like-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('public-feed-reader-comment-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('public-feed-reader-share-button')),
        findsOneWidget,
      );
      expect(find.text(devotional.likesCount.toString()), findsOneWidget);
      expect(find.text(devotional.shareCount.toString()), findsOneWidget);
      expect(find.text('Comentarios'), findsNothing);
      expect(find.text('Escribe un comentario...'), findsNothing);
    },
  );

  testWidgets('public reader opens comments bottom sheet', (tester) async {
    final devotional = _buildDevotional();
    final readerArgs = const DevotionalFeedReaderArgs(
      feedMode: DevotionalFeedMode.forYou,
      initialDevotionalId: 'devotional-1',
      initialDeliveryToken: 'delivery-1',
    );

    await tester.pumpWidget(
      _TestApp(
        devotional: devotional,
        readerArgs: readerArgs,
        readerState: DevotionalFeedReaderState(
          readerArgs: readerArgs,
          activeDevotionalId: 'devotional-1',
          activeIndex: 0,
          status: DevotionalFeedReaderStatus.success,
          loadedDevotionals: {'devotional-1': devotional},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('public-feed-reader-comment-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('public-feed-reader-comments-sheet')),
      findsOneWidget,
    );
    expect(find.text('Comentarios'), findsOneWidget);
  });

  testWidgets('public reader submits comments through comments controller', (
    tester,
  ) async {
    final devotional = _buildDevotional();
    final readerArgs = const DevotionalFeedReaderArgs(
      feedMode: DevotionalFeedMode.forYou,
      initialDevotionalId: 'devotional-1',
      initialDeliveryToken: 'delivery-1',
    );
    final commentsController = _TrackingCommentsController(
      const DevotionalCommentsState(
        status: DevotionalCommentsStatus.success,
        devotionalId: 'devotional-1',
      ),
    );

    await tester.pumpWidget(
      _TestApp(
        devotional: devotional,
        readerArgs: readerArgs,
        readerState: DevotionalFeedReaderState(
          readerArgs: readerArgs,
          activeDevotionalId: 'devotional-1',
          activeIndex: 0,
          status: DevotionalFeedReaderStatus.success,
          loadedDevotionals: {'devotional-1': devotional},
        ),
        commentsController: commentsController,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('public-feed-reader-comment-button')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Amén');
    await tester.tap(find.byIcon(Icons.send_rounded).last);
    await tester.pumpAndSettle();

    expect(commentsController.addCommentCalls, 1);
    expect(commentsController.lastCommentContent, 'Amén');
  });

  testWidgets(
    'public reader reveals part of next devotional during bottom drag',
    (tester) async {
      final first = _buildDevotional(
        id: 'devotional-1',
        title: 'Primer devocional',
        content: _buildLongContent('Primero'),
      );
      final second = _buildDevotional(
        id: 'devotional-2',
        title: 'Segundo devocional',
        withCover: true,
        content: _buildLongContent('Segundo'),
      );
      final readerArgs = const DevotionalFeedReaderArgs(
        feedMode: DevotionalFeedMode.forYou,
        initialDevotionalId: 'devotional-1',
        initialDeliveryToken: 'delivery-1',
      );
      final readerController = _TrackingDevotionalFeedReaderController(
        DevotionalFeedReaderState(
          readerArgs: readerArgs,
          activeDevotionalId: first.id,
          activeIndex: 0,
          status: DevotionalFeedReaderStatus.success,
          loadedDevotionals: {first.id: first, second.id: second},
        ),
        nextIndex: 1,
      );

      await tester.pumpWidget(
        _TestApp(
          devotional: first,
          feedItems: [first, second],
          readerArgs: readerArgs,
          readerController: readerController,
          initialDevotionalId: first.id,
        ),
      );
      await tester.pumpAndSettle();
      await _jumpReaderToBottom(tester, first.id);

      final gesture = await tester.startGesture(
        tester.getCenter(_scrollFinder(first.id)),
      );
      await gesture.moveBy(const Offset(0, -120));
      await tester.pump();

      final viewportHeight = _pageViewHeight(tester);
      final nextPageTop = _pageTop(tester, second.id);
      expect(nextPageTop, greaterThan(0));
      expect(nextPageTop, lessThan(viewportHeight));
      expect(readerController.activateIndexCalls, isEmpty);

      await gesture.up();
      await tester.pumpAndSettle();
    },
  );

  testWidgets('public reader settles on next devotional after sustained drag', (
    tester,
  ) async {
    final first = _buildDevotional(
      id: 'devotional-1',
      title: 'Primer devocional',
      content: _buildLongContent('Primero'),
    );
    final second = _buildDevotional(
      id: 'devotional-2',
      title: 'Segundo devocional',
      content: _buildLongContent('Segundo'),
    );
    final readerArgs = const DevotionalFeedReaderArgs(
      feedMode: DevotionalFeedMode.forYou,
      initialDevotionalId: 'devotional-1',
      initialDeliveryToken: 'delivery-1',
    );
    final readerController = _TrackingDevotionalFeedReaderController(
      DevotionalFeedReaderState(
        readerArgs: readerArgs,
        activeDevotionalId: first.id,
        activeIndex: 0,
        status: DevotionalFeedReaderStatus.success,
        loadedDevotionals: {first.id: first, second.id: second},
      ),
      nextIndex: 1,
    );

    await tester.pumpWidget(
      _TestApp(
        devotional: first,
        feedItems: [first, second],
        readerArgs: readerArgs,
        readerController: readerController,
        initialDevotionalId: first.id,
      ),
    );
    await tester.pumpAndSettle();
    await _jumpReaderToBottom(tester, first.id);

    final gesture = await tester.startGesture(
      tester.getCenter(_scrollFinder(first.id)),
    );
    await gesture.moveBy(const Offset(0, -180));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(readerController.resolveNextIndexCalls, 1);
    expect(readerController.activateIndexCalls, [1]);
    expect(readerController.state.activeDevotionalId, second.id);
  });

  testWidgets(
    'public reader reveals part of previous devotional during top drag',
    (tester) async {
      final first = _buildDevotional(
        id: 'devotional-1',
        title: 'Primer devocional',
        content: _buildLongContent('Primero'),
      );
      final second = _buildDevotional(
        id: 'devotional-2',
        title: 'Segundo devocional',
        content: _buildLongContent('Segundo'),
      );
      final readerArgs = const DevotionalFeedReaderArgs(
        feedMode: DevotionalFeedMode.forYou,
        initialDevotionalId: 'devotional-2',
        initialDeliveryToken: 'delivery-2',
      );
      final readerController = _TrackingDevotionalFeedReaderController(
        DevotionalFeedReaderState(
          readerArgs: readerArgs,
          activeDevotionalId: second.id,
          activeIndex: 1,
          status: DevotionalFeedReaderStatus.success,
          loadedDevotionals: {first.id: first, second.id: second},
        ),
        nextIndex: 1,
        previousIndex: 0,
      );

      await tester.pumpWidget(
        _TestApp(
          devotional: second,
          feedItems: [first, second],
          readerArgs: readerArgs,
          readerController: readerController,
          initialDevotionalId: second.id,
        ),
      );
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(
        tester.getCenter(_scrollFinder(second.id)),
      );
      await gesture.moveBy(const Offset(0, 100));
      await tester.pump();

      final viewportHeight = _pageViewHeight(tester);
      final previousPageTop = _pageTop(tester, first.id);
      final currentPageTop = _pageTop(tester, second.id);
      expect(previousPageTop, greaterThan(-viewportHeight));
      expect(previousPageTop, lessThan(0));
      expect(currentPageTop, greaterThan(0));
      expect(readerController.activateIndexCalls, isEmpty);

      await gesture.up();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'public reader settles on previous devotional after sustained drag',
    (tester) async {
      final first = _buildDevotional(
        id: 'devotional-1',
        title: 'Primer devocional',
        content: _buildLongContent('Primero'),
      );
      final second = _buildDevotional(
        id: 'devotional-2',
        title: 'Segundo devocional',
        content: _buildLongContent('Segundo'),
      );
      final readerArgs = const DevotionalFeedReaderArgs(
        feedMode: DevotionalFeedMode.forYou,
        initialDevotionalId: 'devotional-2',
        initialDeliveryToken: 'delivery-2',
      );
      final readerController = _TrackingDevotionalFeedReaderController(
        DevotionalFeedReaderState(
          readerArgs: readerArgs,
          activeDevotionalId: second.id,
          activeIndex: 1,
          status: DevotionalFeedReaderStatus.success,
          loadedDevotionals: {first.id: first, second.id: second},
        ),
        nextIndex: 1,
        previousIndex: 0,
      );

      await tester.pumpWidget(
        _TestApp(
          devotional: second,
          feedItems: [first, second],
          readerArgs: readerArgs,
          readerController: readerController,
          initialDevotionalId: second.id,
        ),
      );
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(
        tester.getCenter(_scrollFinder(second.id)),
      );
      await gesture.moveBy(const Offset(0, 180));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(readerController.resolvePreviousIndexCalls, 1);
      expect(readerController.activateIndexCalls, [0]);
      expect(readerController.state.activeDevotionalId, first.id);
    },
  );

  testWidgets('public reader snaps back after a short forward handoff', (
    tester,
  ) async {
    final first = _buildDevotional(
      id: 'devotional-1',
      title: 'Primer devocional',
      content: _buildLongContent('Primero'),
    );
    final second = _buildDevotional(
      id: 'devotional-2',
      title: 'Segundo devocional',
      content: _buildLongContent('Segundo'),
    );
    final readerArgs = const DevotionalFeedReaderArgs(
      feedMode: DevotionalFeedMode.forYou,
      initialDevotionalId: 'devotional-1',
      initialDeliveryToken: 'delivery-1',
    );
    final readerController = _TrackingDevotionalFeedReaderController(
      DevotionalFeedReaderState(
        readerArgs: readerArgs,
        activeDevotionalId: first.id,
        activeIndex: 0,
        status: DevotionalFeedReaderStatus.success,
        loadedDevotionals: {first.id: first, second.id: second},
      ),
      nextIndex: 1,
    );

    await tester.pumpWidget(
      _TestApp(
        devotional: first,
        feedItems: [first, second],
        readerArgs: readerArgs,
        readerController: readerController,
        initialDevotionalId: first.id,
      ),
    );
    await tester.pumpAndSettle();
    await _jumpReaderToBottom(tester, first.id);

    final gesture = await tester.startGesture(
      tester.getCenter(_scrollFinder(first.id)),
    );
    await gesture.moveBy(const Offset(0, -80));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(readerController.activateIndexCalls, isEmpty);
    expect(readerController.state.activeDevotionalId, first.id);
    expect(_pageTop(tester, first.id), 0);
  });

  testWidgets('public reader snaps back after a short reverse handoff', (
    tester,
  ) async {
    final first = _buildDevotional(
      id: 'devotional-1',
      title: 'Primer devocional',
      content: _buildLongContent('Primero'),
    );
    final second = _buildDevotional(
      id: 'devotional-2',
      title: 'Segundo devocional',
      content: _buildLongContent('Segundo'),
    );
    final readerArgs = const DevotionalFeedReaderArgs(
      feedMode: DevotionalFeedMode.forYou,
      initialDevotionalId: 'devotional-2',
      initialDeliveryToken: 'delivery-2',
    );
    final readerController = _TrackingDevotionalFeedReaderController(
      DevotionalFeedReaderState(
        readerArgs: readerArgs,
        activeDevotionalId: second.id,
        activeIndex: 1,
        status: DevotionalFeedReaderStatus.success,
        loadedDevotionals: {first.id: first, second.id: second},
      ),
      previousIndex: 0,
    );

    await tester.pumpWidget(
      _TestApp(
        devotional: second,
        feedItems: [first, second],
        readerArgs: readerArgs,
        readerController: readerController,
        initialDevotionalId: second.id,
      ),
    );
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(
      tester.getCenter(_scrollFinder(second.id)),
    );
    await gesture.moveBy(const Offset(0, 80));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(readerController.activateIndexCalls, isEmpty);
    expect(readerController.state.activeDevotionalId, second.id);
    expect(_pageTop(tester, second.id), 0);
  });

  testWidgets(
    'public reader does not move to a previous devotional from the first page',
    (tester) async {
      final first = _buildDevotional(
        id: 'devotional-1',
        title: 'Primer devocional',
        content: _buildLongContent('Primero'),
      );
      final second = _buildDevotional(
        id: 'devotional-2',
        title: 'Segundo devocional',
        content: _buildLongContent('Segundo'),
      );
      final readerArgs = const DevotionalFeedReaderArgs(
        feedMode: DevotionalFeedMode.forYou,
        initialDevotionalId: 'devotional-1',
        initialDeliveryToken: 'delivery-1',
      );
      final readerController = _TrackingDevotionalFeedReaderController(
        DevotionalFeedReaderState(
          readerArgs: readerArgs,
          activeDevotionalId: first.id,
          activeIndex: 0,
          status: DevotionalFeedReaderStatus.success,
          loadedDevotionals: {first.id: first, second.id: second},
        ),
        nextIndex: 1,
      );

      await tester.pumpWidget(
        _TestApp(
          devotional: first,
          feedItems: [first, second],
          readerArgs: readerArgs,
          readerController: readerController,
          initialDevotionalId: first.id,
        ),
      );
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(
        tester.getCenter(_scrollFinder(first.id)),
      );
      await gesture.moveBy(const Offset(0, 180));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(readerController.resolvePreviousIndexCalls, 1);
      expect(readerController.activateIndexCalls, isEmpty);
      expect(readerController.state.activeDevotionalId, first.id);
    },
  );

  testWidgets(
    'public reader stays on current devotional when no next item exists',
    (tester) async {
      final devotional = _buildDevotional(content: _buildLongContent('Unico'));
      final readerArgs = const DevotionalFeedReaderArgs(
        feedMode: DevotionalFeedMode.forYou,
        initialDevotionalId: 'devotional-1',
        initialDeliveryToken: 'delivery-1',
      );
      final readerController = _TrackingDevotionalFeedReaderController(
        DevotionalFeedReaderState(
          readerArgs: readerArgs,
          activeDevotionalId: devotional.id,
          activeIndex: 0,
          status: DevotionalFeedReaderStatus.success,
          loadedDevotionals: {devotional.id: devotional},
        ),
      );

      await tester.pumpWidget(
        _TestApp(
          devotional: devotional,
          readerArgs: readerArgs,
          readerController: readerController,
          initialDevotionalId: devotional.id,
        ),
      );
      await tester.pumpAndSettle();
      await _jumpReaderToBottom(tester, devotional.id);

      final gesture = await tester.startGesture(
        tester.getCenter(_scrollFinder(devotional.id)),
      );
      await gesture.moveBy(const Offset(0, -180));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(readerController.resolveNextIndexCalls, 1);
      expect(readerController.activateIndexCalls, isEmpty);
      expect(readerController.state.activeDevotionalId, devotional.id);
    },
  );

  testWidgets(
    'public reader waits for next-index resolution before revealing the next devotional',
    (tester) async {
      final first = _buildDevotional(
        id: 'devotional-1',
        title: 'Primer devocional',
        content: _buildLongContent('Primero'),
      );
      final second = _buildDevotional(
        id: 'devotional-2',
        title: 'Segundo devocional',
        content: _buildLongContent('Segundo'),
      );
      final readerArgs = const DevotionalFeedReaderArgs(
        feedMode: DevotionalFeedMode.forYou,
        initialDevotionalId: 'devotional-1',
        initialDeliveryToken: 'delivery-1',
      );
      final completer = Completer<int?>();
      final readerController = _TrackingDevotionalFeedReaderController(
        DevotionalFeedReaderState(
          readerArgs: readerArgs,
          activeDevotionalId: first.id,
          activeIndex: 0,
          status: DevotionalFeedReaderStatus.success,
          loadedDevotionals: {first.id: first, second.id: second},
        ),
        resolveNextIndexHandler: () => completer.future,
      );

      await tester.pumpWidget(
        _TestApp(
          devotional: first,
          feedItems: [first, second],
          readerArgs: readerArgs,
          readerController: readerController,
          initialDevotionalId: first.id,
        ),
      );
      await tester.pumpAndSettle();
      await _jumpReaderToBottom(tester, first.id);

      final gesture = await tester.startGesture(
        tester.getCenter(_scrollFinder(first.id)),
      );
      await gesture.moveBy(const Offset(0, -120));
      await tester.pump();

      final viewportHeight = _pageViewHeight(tester);
      expect(_pageTop(tester, second.id), greaterThanOrEqualTo(viewportHeight));
      expect(readerController.resolveNextIndexCalls, 1);

      completer.complete(1);
      await tester.pump();
      await gesture.moveBy(const Offset(0, -120));
      await tester.pump();

      expect(_pageTop(tester, second.id), lessThan(viewportHeight));

      await gesture.up();
      await tester.pumpAndSettle();

      expect(readerController.activateIndexCalls, [1]);
    },
  );

  testWidgets('public reader still reports read complete after 75 percent', (
    tester,
  ) async {
    final devotional = _buildDevotional(content: _buildLongContent('Lectura'));
    final readerArgs = const DevotionalFeedReaderArgs(
      feedMode: DevotionalFeedMode.forYou,
      initialDevotionalId: 'devotional-1',
      initialDeliveryToken: 'delivery-1',
    );
    final readerController = _TrackingDevotionalFeedReaderController(
      DevotionalFeedReaderState(
        readerArgs: readerArgs,
        activeDevotionalId: devotional.id,
        activeIndex: 0,
        status: DevotionalFeedReaderStatus.success,
        loadedDevotionals: {devotional.id: devotional},
      ),
    );

    await tester.pumpWidget(
      _TestApp(
        devotional: devotional,
        readerArgs: readerArgs,
        readerController: readerController,
        initialDevotionalId: devotional.id,
      ),
    );
    await tester.pumpAndSettle();
    await _jumpReaderToProgress(tester, devotional.id, 0.72);

    final gesture = await tester.startGesture(
      tester.getCenter(_scrollFinder(devotional.id)),
    );
    await gesture.moveBy(const Offset(0, -140));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(readerController.reportReadCompleteCalls, 1);
    expect(readerController.resolveNextIndexCalls, 0);
  });

  testWidgets(
    'public reader ignores duplicate edge drags while next-index resolution is pending',
    (tester) async {
      final first = _buildDevotional(
        id: 'devotional-1',
        title: 'Primer devocional',
        content: _buildLongContent('Primero'),
      );
      final second = _buildDevotional(
        id: 'devotional-2',
        title: 'Segundo devocional',
        content: _buildLongContent('Segundo'),
      );
      final readerArgs = const DevotionalFeedReaderArgs(
        feedMode: DevotionalFeedMode.forYou,
        initialDevotionalId: 'devotional-1',
        initialDeliveryToken: 'delivery-1',
      );
      final completer = Completer<int?>();
      final readerController = _TrackingDevotionalFeedReaderController(
        DevotionalFeedReaderState(
          readerArgs: readerArgs,
          activeDevotionalId: first.id,
          activeIndex: 0,
          status: DevotionalFeedReaderStatus.success,
          loadedDevotionals: {first.id: first, second.id: second},
        ),
        resolveNextIndexHandler: () => completer.future,
      );

      await tester.pumpWidget(
        _TestApp(
          devotional: first,
          feedItems: [first, second],
          readerArgs: readerArgs,
          readerController: readerController,
          initialDevotionalId: first.id,
        ),
      );
      await tester.pumpAndSettle();
      await _jumpReaderToBottom(tester, first.id);

      final firstGesture = await tester.startGesture(
        tester.getCenter(_scrollFinder(first.id)),
      );
      await firstGesture.moveBy(const Offset(0, -120));
      await tester.pump();
      await firstGesture.up();
      await tester.pump();

      final secondGesture = await tester.startGesture(
        tester.getCenter(_scrollFinder(first.id)),
      );
      await secondGesture.moveBy(const Offset(0, -120));
      await tester.pump();
      await secondGesture.up();
      await tester.pump();

      expect(readerController.resolveNextIndexCalls, 1);

      completer.complete(1);
      await tester.pumpAndSettle();
    },
  );
}

class _TestApp extends StatelessWidget {
  const _TestApp({
    required this.devotional,
    this.feedItems,
    this.readerArgs,
    this.readerState,
    this.commentsController,
    this.readerController,
    this.initialDevotionalId,
  });

  final Devotional devotional;
  final List<Devotional>? feedItems;
  final DevotionalFeedReaderArgs? readerArgs;
  final DevotionalFeedReaderState? readerState;
  final DevotionalCommentsController? commentsController;
  final DevotionalFeedReaderController? readerController;
  final String? initialDevotionalId;

  @override
  Widget build(BuildContext context) {
    final effectiveFeedItems = feedItems ?? [devotional];
    final effectiveReaderState =
        readerState ??
        DevotionalFeedReaderState(
          readerArgs: readerArgs,
          activeDevotionalId: effectiveFeedItems.first.id,
          activeIndex: 0,
          status: DevotionalFeedReaderStatus.success,
          loadedDevotionals: {
            for (final devotional in effectiveFeedItems)
              devotional.id: devotional,
          },
        );
    final commentsOverride =
        commentsController ??
        _StaticDevotionalCommentsController(
          const DevotionalCommentsState(
            status: DevotionalCommentsStatus.success,
            devotionalId: 'devotional-1',
          ),
        );

    return ProviderScope(
      overrides: [
        devotionalDetailControllerProvider.overrideWith(
          () => _StaticDevotionalDetailController(
            DevotionalDetailState(
              status: DevotionalDetailStatus.success,
              devotional: devotional,
            ),
          ),
        ),
        devotionalCommentsControllerProvider.overrideWith(
          () => commentsOverride,
        ),
        devotionalFeedReaderControllerProvider.overrideWith(
          () =>
              readerController ??
              _StaticDevotionalFeedReaderController(effectiveReaderState),
        ),
        forYouFeedControllerProvider.overrideWith(
          () => _StaticForYouFeedController(
            DevotionalsFeedState(
              status: DevotionalsFeedStatus.success,
              items: effectiveFeedItems,
            ),
          ),
        ),
        followingFeedControllerProvider.overrideWith(
          () => _StaticFollowingFeedController(
            DevotionalsFeedState(
              status: DevotionalsFeedStatus.success,
              items: effectiveFeedItems,
            ),
          ),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: DevotionalDetailScreen(
          devotionalId:
              initialDevotionalId ??
              readerArgs?.initialDevotionalId ??
              devotional.id,
          readerArgs: readerArgs,
        ),
      ),
    );
  }
}

class _StaticDevotionalDetailController extends DevotionalDetailController {
  _StaticDevotionalDetailController(this._initialState);

  final DevotionalDetailState _initialState;

  @override
  DevotionalDetailState build() => _initialState;

  @override
  Future<void> load(
    String devotionalId, {
    String? deliveryToken,
    String? shareToken,
    String? deviceId,
  }) async {}

  @override
  Future<void> toggleLike() async {}

  @override
  Future<void> toggleSave() async {}

  @override
  Future<void> registerShare({int? shareCount}) async {}

  @override
  Future<void> reportReadComplete() async {}

  @override
  Future<bool> report({required String reason, String? details}) async => true;

  @override
  Future<bool> approveReview() async => true;

  @override
  Future<bool> restrictReview(String reason) async => true;
}

class _StaticDevotionalCommentsController extends DevotionalCommentsController {
  _StaticDevotionalCommentsController(this._initialState);

  final DevotionalCommentsState _initialState;

  @override
  DevotionalCommentsState build() => _initialState;

  @override
  Future<void> load(String devotionalId) async {}

  @override
  Future<void> refresh() async {}

  @override
  Future<void> loadMore() async {}

  @override
  Future<void> addComment(String content) async {}

  @override
  Future<void> deleteComment(DevotionalComment comment) async {}
}

class _TrackingCommentsController extends DevotionalCommentsController {
  _TrackingCommentsController(this._initialState);

  final DevotionalCommentsState _initialState;
  int addCommentCalls = 0;
  String? lastCommentContent;

  @override
  DevotionalCommentsState build() => _initialState;

  @override
  Future<void> load(String devotionalId) async {}

  @override
  Future<void> refresh() async {}

  @override
  Future<void> loadMore() async {}

  @override
  Future<void> addComment(String content) async {
    addCommentCalls += 1;
    lastCommentContent = content;
    state = state.copyWith(
      items: [
        _buildComment(id: 'comment-$addCommentCalls', content: content),
        ...state.items,
      ],
      total: state.total + 1,
    );
  }

  @override
  Future<void> deleteComment(DevotionalComment comment) async {}
}

class _StaticDevotionalFeedReaderController
    extends DevotionalFeedReaderController {
  _StaticDevotionalFeedReaderController(this._initialState);

  final DevotionalFeedReaderState _initialState;

  @override
  DevotionalFeedReaderState build() => _initialState;

  @override
  Future<void> configure({
    DevotionalFeedReaderArgs? readerArgs,
    required String devotionalId,
    String? deliveryToken,
    required String deviceId,
  }) async {}

  @override
  Future<void> activateIndex(int index) async {}

  @override
  Future<int?> resolveNextIndex() async => null;

  @override
  int? resolvePreviousIndex() => null;

  @override
  Future<void> reloadActive() async {}

  @override
  Future<void> toggleLike() async {}

  @override
  Future<void> toggleSave() async {}

  @override
  Future<void> registerShare({int? shareCount}) async {}

  @override
  Future<bool> report({required String reason, String? details}) async => true;

  @override
  Future<void> reportReadComplete() async {}

  @override
  void acknowledgeReadComplete() {}

  @override
  void syncCommentCount(int count) {}
}

class _TrackingDevotionalFeedReaderController
    extends DevotionalFeedReaderController {
  _TrackingDevotionalFeedReaderController(
    this._initialState, {
    this.nextIndex,
    this.previousIndex,
    this.resolveNextIndexHandler,
  });

  final DevotionalFeedReaderState _initialState;
  final int? nextIndex;
  final int? previousIndex;
  final Future<int?> Function()? resolveNextIndexHandler;
  int resolveNextIndexCalls = 0;
  int resolvePreviousIndexCalls = 0;
  int reportReadCompleteCalls = 0;
  final List<int> activateIndexCalls = <int>[];

  @override
  DevotionalFeedReaderState build() => _initialState;

  @override
  Future<void> configure({
    DevotionalFeedReaderArgs? readerArgs,
    required String devotionalId,
    String? deliveryToken,
    required String deviceId,
  }) async {}

  @override
  Future<void> activateIndex(int index) async {
    activateIndexCalls.add(index);
    final readerArgs = state.readerArgs;
    final devotionalIds = state.loadedDevotionals.keys.toList();
    final activeDevotionalId = index >= 0 && index < devotionalIds.length
        ? devotionalIds[index]
        : state.activeDevotionalId;
    state = state.copyWith(
      activeIndex: index,
      activeDevotionalId: activeDevotionalId,
      status: DevotionalFeedReaderStatus.success,
    );
  }

  @override
  Future<int?> resolveNextIndex() async {
    resolveNextIndexCalls += 1;
    if (resolveNextIndexHandler != null) {
      return resolveNextIndexHandler!();
    }
    return nextIndex;
  }

  @override
  int? resolvePreviousIndex() {
    resolvePreviousIndexCalls += 1;
    return previousIndex;
  }

  @override
  Future<void> reloadActive() async {}

  @override
  Future<void> toggleLike() async {}

  @override
  Future<void> toggleSave() async {}

  @override
  Future<void> registerShare({int? shareCount}) async {}

  @override
  Future<bool> report({required String reason, String? details}) async => true;

  @override
  Future<void> reportReadComplete() async {
    reportReadCompleteCalls += 1;
  }

  @override
  void acknowledgeReadComplete() {}

  @override
  void syncCommentCount(int count) {}
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
  Future<void> refreshHeader() async {}

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

Devotional _buildDevotional({
  String id = 'devotional-1',
  String title = 'Un descanso para hoy',
  String? feedContextReason,
  String? recommendationReason,
  bool withCover = false,
  double coverImageFocusY = 0,
  List<dynamic>? content,
}) {
  return Devotional(
    id: id,
    title: title,
    status: DevotionalStatus.published,
    publicationState: DevotionalPublicationState.publishedLowReach,
    moderationStatus: DevotionalModerationStatus.clear,
    effectiveState: 'PUBLISHED',
    moderationReason: null,
    coverImageUrl: withCover
        ? 'https://images.example.com/devotional-cover.jpg'
        : null,
    previewImageUrl: withCover
        ? 'https://images.example.com/devotional-preview.jpg'
        : null,
    previewText: 'Dios sigue hablando en lo sencillo.',
    computedHook: 'Dios sigue hablando en lo sencillo.',
    optimizedPreviewText: 'Dios sigue hablando en lo sencillo.',
    hookSource: null,
    coverImageFocusY: coverImageFocusY,
    viewCount: 12,
    estimatedReadTime: 2,
    publishedAt: DateTime(2026, 1, 2),
    firstPublishedAt: DateTime(2026, 1, 2),
    createdAt: DateTime(2026, 1, 2),
    updatedAt: DateTime(2026, 1, 2),
    author: const DevotionalAuthor(id: 'author-1', name: 'Ana', handle: 'ana'),
    verseReferences: const [
      DevotionalVerseReference(
        id: 'ref-1',
        book: 'Salmos',
        chapter: 23,
        verseStart: 1,
        isPrimary: true,
      ),
    ],
    likesCount: 2,
    commentsCount: 0,
    shareCount: 1,
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
    deliveryToken: 'delivery-1',
    recommendationReason: recommendationReason,
    feedContextReason: feedContextReason,
    content:
        content ??
        const [
          {'insert': 'Primer párrafo de apertura.\nSegundo párrafo final.\n'},
        ],
  );
}

Finder _scrollFinder(String devotionalId) {
  return find.byKey(Key('public-feed-reader-scroll-$devotionalId'));
}

double _pageTop(WidgetTester tester, String devotionalId) {
  return tester
      .getTopLeft(find.byKey(Key('public-feed-reader-page-$devotionalId')))
      .dy;
}

double _pageViewHeight(WidgetTester tester) {
  return tester
      .getSize(find.byKey(const Key('public-feed-reader-page-view')))
      .height;
}

Future<void> _jumpReaderToBottom(
  WidgetTester tester,
  String devotionalId,
) async {
  final controller = tester
      .widget<SingleChildScrollView>(_scrollFinder(devotionalId))
      .controller!;
  controller.jumpTo(controller.position.maxScrollExtent);
  await tester.pump();
}

Future<void> _jumpReaderToProgress(
  WidgetTester tester,
  String devotionalId,
  double progress,
) async {
  final controller = tester
      .widget<SingleChildScrollView>(_scrollFinder(devotionalId))
      .controller!;
  controller.jumpTo(controller.position.maxScrollExtent * progress);
  await tester.pump();
}

List<dynamic> _buildLongContent(String prefix) {
  final buffer = StringBuffer();
  for (var index = 0; index < 48; index += 1) {
    buffer.writeln(
      '$prefix ${index + 1}. Dios sigue obrando en medio de cada detalle de nuestra vida diaria para sostenernos y guiarnos.',
    );
    buffer.writeln();
  }
  return [
    {'insert': buffer.toString()},
  ];
}

DevotionalComment _buildComment({required String id, required String content}) {
  return DevotionalComment(
    id: id,
    devotionalId: 'devotional-1',
    content: content,
    createdAt: DateTime(2026, 4, 30),
    updatedAt: DateTime(2026, 4, 30),
    author: const DevotionalAuthor(
      id: 'comment-author',
      name: 'Ana',
      handle: 'ana',
      avatarUrl: null,
      following: false,
    ),
  );
}
