import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_theme.dart';
import 'package:holyverso/data/auth/models/user.dart';
import 'package:holyverso/data/devotionals/devotionals_api_client.dart';
import 'package:holyverso/data/devotionals/devotionals_repository.dart';
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
import 'package:holyverso/presentation/screens/devotionals/devotional_feed_reader_args.dart';
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

  testWidgets('honors tab query parameter and falls back to Para ti', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        initialLocation: '/devotionals?tab=following',
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
        mineState: const DevotionalsListState(
          status: DevotionalsListStatus.success,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Siguiendo visible'), findsOneWidget);
    expect(find.text('Para ti visible'), findsNothing);

    await tester.pumpWidget(
      _TestApp(
        initialLocation: '/devotionals?tab=nope',
        forYouState: DevotionalsFeedState(
          status: DevotionalsFeedStatus.success,
          items: [_buildDevotional(id: 'for-you', title: 'Para ti visible')],
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

    expect(find.text('Para ti visible'), findsOneWidget);
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
        reviewState: const DevotionalsListState(
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

  testWidgets('renders daily featured devotional inside the For You header', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        forYouState: DevotionalsFeedState(
          status: DevotionalsFeedStatus.success,
          feedHeader: const DevotionalFeedHeader(
            currentStreak: 5,
            longestStreak: 8,
            streakFreezeCount: 1,
            completedToday: false,
            dailyFeatured: DevotionalDailyFeatured(
              id: 'featured-header',
              title: 'Dios sigue obrando',
              estimatedReadTime: 3,
              previewText: 'Aunque hoy parezca lento, Dios sigue presente.',
              previewImageUrl: 'https://example.com/featured-header.jpg',
            ),
            primaryCtaType: 'OPEN_DAILY_FEATURED',
            primaryCtaLabel: 'Completa tu día',
            primaryCtaDevotionalId: 'featured-header',
          ),
          items: [_buildDevotional(id: 'feed-item', title: 'Feed item')],
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

    expect(find.text('Tu ritual de hoy'), findsOneWidget);
    expect(find.text('Devocional de hoy'), findsOneWidget);
    expect(find.text('Dios sigue obrando'), findsOneWidget);
    expect(
      find.text('Aunque hoy parezca lento, Dios sigue presente.'),
      findsOneWidget,
    );
    expect(find.text('3 min'), findsOneWidget);
    expect(find.text('Completa tu día'), findsOneWidget);
    expect(
      find.byKey(const Key('daily-featured-card-featured-header')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('daily-featured-image-featured-header')),
      findsOneWidget,
    );
  });

  testWidgets('daily featured CTA opens devotional detail route', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        forYouState: const DevotionalsFeedState(
          status: DevotionalsFeedStatus.success,
          feedHeader: DevotionalFeedHeader(
            currentStreak: 2,
            longestStreak: 4,
            streakFreezeCount: 0,
            completedToday: false,
            dailyFeatured: DevotionalDailyFeatured(
              id: 'featured-detail',
              title: 'Abre el detalle',
              estimatedReadTime: 4,
              previewText: 'Este es el devocional fijo del día.',
              previewImageUrl: null,
            ),
            primaryCtaType: 'OPEN_DAILY_FEATURED',
            primaryCtaLabel: 'Leer de una vez',
            primaryCtaDevotionalId: 'featured-detail',
          ),
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

    await tester.tap(find.text('Leer de una vez'));
    await tester.pumpAndSettle();

    expect(find.text('detail-screen'), findsOneWidget);
  });

  testWidgets(
    'completed state does not render the inline ritual header, even when the feed is empty',
    (tester) async {
      await tester.pumpWidget(
        _TestApp(
          forYouState: const DevotionalsFeedState(
            status: DevotionalsFeedStatus.success,
            feedHeader: DevotionalFeedHeader(
              currentStreak: 7,
              longestStreak: 9,
              streakFreezeCount: 0,
              completedToday: true,
              dailyFeatured: DevotionalDailyFeatured(
                id: 'featured-completed-empty',
                title: 'No deberia aparecer',
                estimatedReadTime: 4,
                previewText: 'Tampoco deberia aparecer en completado.',
                previewImageUrl: null,
              ),
              primaryCtaType: 'OPEN_DAILY_FEATURED',
              primaryCtaLabel: 'Leer',
              primaryCtaDevotionalId: 'featured-completed-empty',
            ),
          ),
          followingState: const DevotionalsFeedState(
            status: DevotionalsFeedStatus.success,
          ),
          mineState: const DevotionalsListState(
            status: DevotionalsListStatus.success,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));

      expect(find.text('Tu ritual de hoy'), findsNothing);
      expect(find.text('Devocional de hoy'), findsNothing);
      expect(
        find.byKey(const Key('daily-featured-card-featured-completed-empty')),
        findsNothing,
      );
      expect(find.text('Racha: 7 días'), findsOneWidget);
      expect(find.text('Completado hoy'), findsOneWidget);
      expect(
        find.text('Todavía no hay devocionales en el feed'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'completed state renders a floating streak badge with dismiss affordance',
    (tester) async {
      await tester.pumpWidget(
        _TestApp(
          forYouState: DevotionalsFeedState(
            status: DevotionalsFeedStatus.success,
            feedHeader: const DevotionalFeedHeader(
              currentStreak: 3,
              longestStreak: 5,
              streakFreezeCount: 0,
              completedToday: true,
              dailyFeatured: null,
              primaryCtaType: 'BROWSE_FEED',
              primaryCtaLabel: 'Explorar',
              primaryCtaDevotionalId: null,
            ),
            items: [_buildDevotional(id: 'completed-item', title: 'Feed item')],
          ),
          followingState: const DevotionalsFeedState(
            status: DevotionalsFeedStatus.success,
          ),
          mineState: const DevotionalsListState(
            status: DevotionalsListStatus.success,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));

      expect(find.byKey(const Key('completed-streak-badge')), findsOneWidget);
      expect(find.text('Racha: 3 días'), findsOneWidget);
      expect(find.text('Completado hoy'), findsOneWidget);
      expect(find.byTooltip('Ocultar indicador de racha'), findsOneWidget);
      expect(find.text('Feed item'), findsOneWidget);
    },
  );

  testWidgets('closing the badge hides only the overlay', (tester) async {
    await tester.pumpWidget(
      _TestApp(
        forYouState: DevotionalsFeedState(
          status: DevotionalsFeedStatus.success,
          feedHeader: const DevotionalFeedHeader(
            currentStreak: 4,
            longestStreak: 6,
            streakFreezeCount: 1,
            completedToday: true,
            dailyFeatured: null,
            primaryCtaType: 'BROWSE_FEED',
            primaryCtaLabel: 'Explorar',
            primaryCtaDevotionalId: null,
          ),
          items: [
            _buildDevotional(id: 'visible-item', title: 'Visible debajo'),
          ],
        ),
        followingState: const DevotionalsFeedState(
          status: DevotionalsFeedStatus.success,
        ),
        mineState: const DevotionalsListState(
          status: DevotionalsListStatus.success,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(find.byKey(const Key('completed-streak-badge')), findsOneWidget);
    expect(find.text('Visible debajo'), findsOneWidget);

    await tester.tap(find.byKey(const Key('completed-streak-badge-close')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    final opacity = tester.widget<AnimatedOpacity>(
      find.descendant(
        of: find.byKey(const Key('completed-streak-badge')),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    expect(opacity.opacity, 0);
    expect(find.text('Visible debajo'), findsOneWidget);
  });

  testWidgets(
    'badge becomes visible again after a pending to completed transition',
    (tester) async {
      final controller = _MutableForYouFeedController(
        DevotionalsFeedState(
          status: DevotionalsFeedStatus.success,
          feedHeader: const DevotionalFeedHeader(
            currentStreak: 2,
            longestStreak: 4,
            streakFreezeCount: 0,
            completedToday: true,
            dailyFeatured: null,
            primaryCtaType: 'BROWSE_FEED',
            primaryCtaLabel: 'Explorar',
            primaryCtaDevotionalId: null,
          ),
          items: [_buildDevotional(id: 'transition-item', title: 'Transition')],
        ),
      );

      await tester.pumpWidget(
        _TestApp(
          forYouState: controller.initialState,
          forYouController: controller,
          followingState: const DevotionalsFeedState(
            status: DevotionalsFeedStatus.success,
          ),
          mineState: const DevotionalsListState(
            status: DevotionalsListStatus.success,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));

      await tester.tap(find.byKey(const Key('completed-streak-badge-close')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));

      var opacity = tester.widget<AnimatedOpacity>(
        find.descendant(
          of: find.byKey(const Key('completed-streak-badge')),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(opacity.opacity, 0);

      controller.replaceState(
        DevotionalsFeedState(
          status: DevotionalsFeedStatus.success,
          feedHeader: const DevotionalFeedHeader(
            currentStreak: 2,
            longestStreak: 4,
            streakFreezeCount: 0,
            completedToday: false,
            dailyFeatured: null,
            primaryCtaType: 'BROWSE_FEED',
            primaryCtaLabel: 'Explorar',
            primaryCtaDevotionalId: null,
          ),
          items: [_buildDevotional(id: 'transition-item', title: 'Transition')],
        ),
      );
      await tester.pump();

      controller.replaceState(
        DevotionalsFeedState(
          status: DevotionalsFeedStatus.success,
          feedHeader: const DevotionalFeedHeader(
            currentStreak: 2,
            longestStreak: 4,
            streakFreezeCount: 0,
            completedToday: true,
            dailyFeatured: null,
            primaryCtaType: 'BROWSE_FEED',
            primaryCtaLabel: 'Explorar',
            primaryCtaDevotionalId: null,
          ),
          items: [_buildDevotional(id: 'transition-item', title: 'Transition')],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));

      opacity = tester.widget<AnimatedOpacity>(
        find.descendant(
          of: find.byKey(const Key('completed-streak-badge')),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(opacity.opacity, 1);
      expect(find.text('Racha: 2 días'), findsOneWidget);
    },
  );

  testWidgets('completed badge exposes accessible semantics', (tester) async {
    final semanticsHandle = tester.ensureSemantics();

    await tester.pumpWidget(
      _TestApp(
        forYouState: DevotionalsFeedState(
          status: DevotionalsFeedStatus.success,
          feedHeader: const DevotionalFeedHeader(
            currentStreak: 1,
            longestStreak: 3,
            streakFreezeCount: 0,
            completedToday: true,
            dailyFeatured: null,
            primaryCtaType: 'BROWSE_FEED',
            primaryCtaLabel: 'Explorar',
            primaryCtaDevotionalId: null,
          ),
          items: [_buildDevotional(id: 'semantics-item', title: 'Semantics')],
        ),
        followingState: const DevotionalsFeedState(
          status: DevotionalsFeedStatus.success,
        ),
        mineState: const DevotionalsListState(
          status: DevotionalsListStatus.success,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(
      find.bySemanticsLabel('Completado hoy. Racha: 1 día.'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Ocultar indicador de racha'), findsOneWidget);
    semanticsHandle.dispose();
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
      previewImageUrl: 'https://example.com/share-card.jpg',
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

    expect(find.text('Muchos lo están guardando ->'), findsOneWidget);
    expect(find.text('Recomendado'), findsOneWidget);
    expect(find.text('Destacado en HolyVerso'), findsNothing);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('Guardar'), findsOneWidget);
    expect(
      find.byKey(const Key('public-devotional-overlay-bar-share-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('public-devotional-overlay-stats-share-card')),
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
    expect(
      find.byKey(const Key('public-devotional-overlay-actions-share-card')),
      findsOneWidget,
    );

    final imageFinder = find.byKey(
      const Key('public-devotional-image-share-card'),
    );
    final saveFinder = find.byKey(
      const Key('public-devotional-save-share-card'),
    );
    final shareFinder = find.byKey(
      const Key('public-devotional-share-share-card'),
    );
    final imageTop = tester.getTopLeft(imageFinder).dy;
    final imageBottom = tester.getBottomLeft(imageFinder).dy;
    final imageHeight = tester.getSize(imageFinder).height;
    final likesCenter = tester
        .getCenter(find.byKey(const Key('public-devotional-likes')))
        .dy;
    final commentsCenter = tester
        .getCenter(find.byKey(const Key('public-devotional-comments')))
        .dy;
    final viewsCenter = tester
        .getCenter(find.byKey(const Key('public-devotional-views')))
        .dy;
    final saveCenter = tester.getCenter(saveFinder).dy;
    final shareCenter = tester.getCenter(shareFinder).dy;

    expect(find.byKey(const Key('public-devotional-likes')), findsOneWidget);
    expect(find.byKey(const Key('public-devotional-comments')), findsOneWidget);
    expect(find.byKey(const Key('public-devotional-views')), findsOneWidget);
    expect(likesCenter, greaterThan(imageTop));
    expect(likesCenter, lessThan(imageBottom));
    expect(commentsCenter, greaterThan(imageTop));
    expect(commentsCenter, lessThan(imageBottom));
    expect(viewsCenter, greaterThan(imageTop));
    expect(viewsCenter, lessThan(imageBottom));
    expect(saveCenter, greaterThan(imageTop));
    expect(saveCenter, lessThan(imageBottom));
    expect(shareCenter, greaterThan(imageTop));
    expect(shareCenter, lessThan(imageBottom));
    expect(saveCenter, lessThan(imageTop + (imageHeight * 0.42)));
    expect(shareCenter, lessThan(imageTop + (imageHeight * 0.42)));
    expect((likesCenter - saveCenter).abs(), lessThan(2));
    expect((commentsCenter - shareCenter).abs(), lessThan(2));

    await tester.ensureVisible(
      find.byKey(const Key('public-devotional-share-share-card')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('public-devotional-share-share-card')),
    );
    await tester.pumpAndSettle();

    expect(find.text('detail-screen'), findsNothing);
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
    expect(find.text('Esto es para ti ->'), findsNothing);
  });

  testWidgets('save button uses the softened inactive footprint and styling', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        forYouState: DevotionalsFeedState(
          status: DevotionalsFeedStatus.success,
          items: [_buildDevotional(id: 'save-style', title: 'Guardar suave')],
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

    final saveButton = find.byKey(
      const Key('public-devotional-save-save-style'),
    );
    final icon = tester.widget<Icon>(
      find.descendant(of: saveButton, matching: find.byType(Icon)).first,
    );
    final container = tester.widget<AnimatedContainer>(
      find.descendant(of: saveButton, matching: find.byType(AnimatedContainer)),
    );
    final decoration = container.decoration! as BoxDecoration;
    final gradient = decoration.gradient! as LinearGradient;

    expect(
      find.descendant(
        of: saveButton,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Padding &&
              widget.padding ==
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
      findsOneWidget,
    );
    expect(icon.icon, Icons.bookmark_border_rounded);
    expect(icon.size, 17);
    expect(icon.color, AppColors.holyGold.withValues(alpha: 0.88));
    expect(
      find.descendant(
        of: saveButton,
        matching: find.byWidgetPredicate(
          (widget) => widget is SizedBox && widget.width == 6,
        ),
      ),
      findsOneWidget,
    );
    expect(
      decoration.border!.top.color,
      AppColors.holyGold.withValues(alpha: 0.12),
    );
    expect(gradient.colors, [
      AppColors.holyGold.withValues(alpha: 0.16),
      AppColors.holyGold.withValues(alpha: 0.10),
    ]);
  });

  testWidgets('save button keeps the stronger active saved treatment', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        forYouState: DevotionalsFeedState(
          status: DevotionalsFeedStatus.success,
          items: [
            _buildDevotional(
              id: 'saved-style',
              title: 'Guardado activo',
              saved: true,
            ),
          ],
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

    final saveButton = find.byKey(
      const Key('public-devotional-save-saved-style'),
    );
    final icon = tester.widget<Icon>(
      find.descendant(of: saveButton, matching: find.byType(Icon)).first,
    );
    final container = tester.widget<AnimatedContainer>(
      find.descendant(of: saveButton, matching: find.byType(AnimatedContainer)),
    );
    final decoration = container.decoration! as BoxDecoration;
    final gradient = decoration.gradient! as LinearGradient;

    expect(find.text('Guardado'), findsOneWidget);
    expect(icon.icon, Icons.bookmark_rounded);
    expect(icon.color, AppColors.midnightFaithDark);
    expect(
      decoration.border!.top.color,
      AppColors.holyGold.withValues(alpha: 0.24),
    );
    expect(gradient.colors, [
      AppColors.holyGold.withValues(alpha: 0.94),
      const Color(0xFFE7C565),
    ]);
  });

  testWidgets('hides stats cluster when likes and comments are zero', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        forYouState: DevotionalsFeedState(
          status: DevotionalsFeedStatus.success,
          items: [
            _buildDevotional(
              id: 'no-stats',
              title: 'Sin estadisticas',
              likesCount: 0,
              commentsCount: 0,
              viewCount: 0,
            ),
          ],
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

    expect(find.byKey(const Key('public-devotional-likes')), findsNothing);
    expect(find.byKey(const Key('public-devotional-comments')), findsNothing);
    expect(find.byKey(const Key('public-devotional-views')), findsNothing);
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

  testWidgets('opens public feed entries with feed reader args', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        forYouState: DevotionalsFeedState(
          status: DevotionalsFeedStatus.success,
          items: [
            _buildDevotional(
              id: 'detail-card',
              title: 'Detalle',
              feedContextReason: '',
            ),
          ],
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

    await tester.ensureVisible(find.text('Esto es para ti ->'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Esto es para ti ->'));
    await tester.pumpAndSettle();

    expect(find.text('public-reader-screen'), findsOneWidget);
    expect(find.text('reader:forYou:detail-card:true'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('following tab also uses the public reader transition path', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        forYouState: const DevotionalsFeedState(
          status: DevotionalsFeedStatus.success,
        ),
        followingState: DevotionalsFeedState(
          status: DevotionalsFeedStatus.success,
          items: [
            _buildDevotional(
              id: 'following-card',
              title: 'Siguiendo detalle',
              feedContextReason: 'FOLLOWED_AUTHOR',
            ),
          ],
        ),
        mineState: const DevotionalsListState(
          status: DevotionalsListStatus.success,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('devotionals-tab-following')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Viene de alguien que sigues ->'));
    await tester.pumpAndSettle();

    expect(find.text('public-reader-screen'), findsOneWidget);
    expect(find.text('reader:following:following-card:true'), findsOneWidget);
  });

  testWidgets('prioritizes hook and keeps title as secondary metadata', (
    tester,
  ) async {
    const hook = 'Dios no te esta pidiendo perfeccion para acercarte hoy.';
    const title = 'Un titulo menos fuerte';

    await tester.pumpWidget(
      _TestApp(
        forYouState: DevotionalsFeedState(
          status: DevotionalsFeedStatus.success,
          items: [
            _buildDevotional(
              id: 'hierarchy-card',
              title: title,
              computedHook: hook,
            ),
          ],
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

    expect(find.text(hook), findsOneWidget);
    expect(find.text(title), findsOneWidget);
    expect(find.text('Juan 3:16'), findsOneWidget);
  });

  testWidgets('shows subtle interpretation and inline fallback trend marker', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        forYouState: DevotionalsFeedState(
          status: DevotionalsFeedStatus.success,
          items: [
            _buildDevotional(
              id: 'quiet-card',
              title: 'Silencio',
              publicationState: DevotionalPublicationState.trending,
              feedContextReason: 'FOLLOWED_AUTHOR',
              following: true,
            ),
          ],
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

    expect(find.textContaining('Lo sigues'), findsOneWidget);
    expect(find.text('Viene de alguien que sigues ->'), findsOneWidget);
    expect(find.text('En tendencia'), findsOneWidget);
    expect(find.byKey(const Key('public-devotional-likes')), findsOneWidget);
    expect(find.byKey(const Key('public-devotional-comments')), findsOneWidget);
    expect(find.byKey(const Key('public-devotional-views')), findsOneWidget);
  });

  testWidgets('renders recommended badge over the image when available', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        forYouState: DevotionalsFeedState(
          status: DevotionalsFeedStatus.success,
          items: [
            _buildDevotional(
              id: 'overlay-card',
              title: 'Con overlay',
              previewImageUrl: 'https://example.com/overlay-card.jpg',
              publicationState: DevotionalPublicationState.featured,
              feedContextReason: 'FEATURED',
            ),
          ],
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

    expect(find.text('Recomendado'), findsOneWidget);
    expect(find.text('Destacado en HolyVerso'), findsNothing);

    final badgeY = tester.getTopLeft(find.text('Recomendado')).dy;
    final imageTop = tester
        .getTopLeft(
          find.byKey(const Key('public-devotional-image-overlay-card')),
        )
        .dy;
    final imageBottom = tester
        .getBottomLeft(
          find.byKey(const Key('public-devotional-image-overlay-card')),
        )
        .dy;
    expect(badgeY, greaterThan(imageTop));
    expect(badgeY, lessThan(imageBottom));
  });

  testWidgets('renders reduced image height below actions', (tester) async {
    await tester.pumpWidget(
      _TestApp(
        forYouState: DevotionalsFeedState(
          status: DevotionalsFeedStatus.success,
          items: [
            _buildDevotional(
              id: 'image-card',
              title: 'Con imagen',
              previewImageUrl: 'https://example.com/devotional.jpg',
            ),
          ],
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

    final imageSize = tester.getSize(
      find.byKey(const Key('public-devotional-image-image-card')),
    );
    expect(imageSize.height, 164);
  });

  testWidgets('keeps inline actions row when the public card has no image', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        forYouState: DevotionalsFeedState(
          status: DevotionalsFeedStatus.success,
          items: [
            _buildDevotional(
              id: 'no-image-actions',
              title: 'Sin imagen',
              previewImageUrl: '',
              coverImageUrl: '',
            ),
          ],
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

    expect(
      find.byKey(const Key('public-devotional-image-no-image-actions')),
      findsNothing,
    );
    expect(
      find.byKey(
        const Key('public-devotional-overlay-actions-no-image-actions'),
      ),
      findsNothing,
    );
    expect(
      find.byKey(const Key('public-devotional-overlay-stats-no-image-actions')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('public-devotional-save-no-image-actions')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('public-devotional-share-no-image-actions')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('public-devotional-likes')), findsOneWidget);
    expect(find.byKey(const Key('public-devotional-comments')), findsOneWidget);
    expect(find.byKey(const Key('public-devotional-views')), findsOneWidget);
  });

  testWidgets('uses fallback contextual text when there is no interpretation', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        forYouState: DevotionalsFeedState(
          status: DevotionalsFeedStatus.success,
          items: [
            _buildDevotional(
              id: 'fallback-copy',
              title: 'Fallback',
              feedContextReason: '',
            ),
          ],
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

    expect(find.text('Esto es para ti ->'), findsOneWidget);
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
    this.initialLocation = '/devotionals',
    this.reviewState = const DevotionalsListState(
      status: DevotionalsListStatus.success,
    ),
    this.authState = const AuthState(sessionStatus: AuthSessionStatus.guest),
    this.apiClient,
    this.forYouController,
  });

  final DevotionalsFeedState forYouState;
  final DevotionalsFeedState followingState;
  final DevotionalsListState mineState;
  final String initialLocation;
  final DevotionalsListState reviewState;
  final AuthState authState;
  final DevotionalsApiClient? apiClient;
  final ForYouFeedController? forYouController;

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/devotionals',
          builder: (context, state) => DevotionalsListScreen(
            initialTab: DevotionalsTopTab.fromQueryValue(
              state.uri.queryParameters['tab'],
            ),
          ),
        ),
        GoRoute(
          path: '/devotionals/create',
          builder: (context, state) =>
              const Scaffold(appBar: HolyChildAppBar(title: 'create-screen')),
        ),
        GoRoute(
          path: '/devotionals/:id',
          builder: (context, state) {
            final extra = state.extra;
            if (extra is DevotionalFeedReaderArgs) {
              return Scaffold(
                appBar: const HolyChildAppBar(title: 'public-reader-screen'),
                body: Center(
                  child: Text(
                    'reader:${extra.feedMode == DevotionalFeedMode.forYou ? 'forYou' : 'following'}:${extra.initialDevotionalId}:${extra.heroTag != null}',
                  ),
                ),
              );
            }

            return const Scaffold(
              appBar: HolyChildAppBar(title: 'detail-screen'),
            );
          },
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
          () => forYouController ?? _StaticForYouFeedController(forYouState),
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

class _MutableForYouFeedController extends ForYouFeedController {
  _MutableForYouFeedController(this.initialState);

  final DevotionalsFeedState initialState;

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
  bool saved = false,
  bool following = true,
  int likesCount = 12,
  int commentsCount = 4,
  int viewCount = 21,
  String feedContextReason = 'SAVED_BY_OTHERS',
  DevotionalPublicationState? publicationState,
  String coverImageUrl = '',
  String previewImageUrl = '',
}) {
  final resolvedPublicationState =
      publicationState ??
      (status == DevotionalStatus.archived
          ? DevotionalPublicationState.archived
          : status == DevotionalStatus.draft
          ? DevotionalPublicationState.draft
          : DevotionalPublicationState.featured);
  final author = DevotionalAuthor(
    id: 'author-1',
    name: 'Gabriel M.',
    handle: 'gabriel',
    avatarUrl: null,
    following: following,
  );

  return Devotional(
    id: id,
    title: title,
    status: status,
    publicationState: resolvedPublicationState,
    moderationStatus: DevotionalModerationStatus.clear,
    effectiveState: 'CLEAR',
    moderationReason: null,
    coverImageUrl: coverImageUrl,
    previewImageUrl: previewImageUrl,
    previewText: 'Texto breve para validar la jerarquía del card.',
    computedHook:
        computedHook ?? 'Hay dias en los que volver a Dios es respirar.',
    optimizedPreviewText:
        'Su gracia no te exige fingir fuerza; te invita a seguir desde la verdad.',
    hookSource: 'CONTENT_OPENING',
    coverImageFocusY: 0,
    viewCount: viewCount,
    estimatedReadTime: 5,
    publishedAt: DateTime(2026, 3, 25),
    firstPublishedAt: DateTime(2026, 3, 25),
    createdAt: DateTime(2026, 3, 25),
    updatedAt: DateTime(2026, 3, 25),
    author: author,
    verseReferences: const [
      DevotionalVerseReference(
        id: 'ref-1',
        book: 'Juan',
        chapter: 3,
        verseStart: 16,
        isPrimary: true,
      ),
    ],
    likesCount: likesCount,
    commentsCount: commentsCount,
    shareCount: 2,
    saveCount: 3,
    readCompleteCount: 0,
    impressionCount: 0,
    uniqueImpressionCount: 0,
    reportCount: 0,
    openReportCount: 0,
    liked: false,
    saved: saved,
    isOwner: status != DevotionalStatus.published,
    canModerate: false,
    deliveryToken: 'delivery-$id',
    recommendationReason: DevotionalFeedMode.forYou.name,
    feedContextReason: feedContextReason,
    content: const [],
  );
}
