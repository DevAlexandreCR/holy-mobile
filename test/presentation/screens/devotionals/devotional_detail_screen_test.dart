import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/core/theme/app_theme.dart';
import 'package:holyverso/domain/devotionals/devotional.dart';
import 'package:holyverso/domain/devotionals/devotional_author.dart';
import 'package:holyverso/domain/devotionals/devotional_comment.dart';
import 'package:holyverso/domain/devotionals/devotional_moderation_status.dart';
import 'package:holyverso/domain/devotionals/devotional_publication_state.dart';
import 'package:holyverso/domain/devotionals/devotional_status.dart';
import 'package:holyverso/domain/devotionals/devotional_verse_reference.dart';
import 'package:holyverso/presentation/screens/devotionals/devotional_detail_screen.dart';
import 'package:holyverso/presentation/state/devotionals/devotional_comments_controller.dart';
import 'package:holyverso/presentation/state/devotionals/devotional_comments_state.dart';
import 'package:holyverso/presentation/state/devotionals/devotional_detail_controller.dart';
import 'package:holyverso/presentation/state/devotionals/devotional_detail_state.dart';
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
}

class _TestApp extends StatelessWidget {
  const _TestApp({
    required this.devotional,
    this.commentsState = const DevotionalCommentsState(
      status: DevotionalCommentsStatus.success,
      devotionalId: 'devotional-1',
    ),
  });

  final Devotional devotional;
  final DevotionalCommentsState commentsState;

  @override
  Widget build(BuildContext context) {
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
          () => _StaticDevotionalCommentsController(commentsState),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: const DevotionalDetailScreen(devotionalId: 'devotional-1'),
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

Devotional _buildDevotional({
  String? feedContextReason,
  String? recommendationReason,
}) {
  return Devotional(
    id: 'devotional-1',
    title: 'Un descanso para hoy',
    status: DevotionalStatus.published,
    publicationState: DevotionalPublicationState.publishedLowReach,
    moderationStatus: DevotionalModerationStatus.clear,
    effectiveState: 'PUBLISHED',
    moderationReason: null,
    coverImageUrl: null,
    previewImageUrl: null,
    previewText: 'Dios sigue hablando en lo sencillo.',
    computedHook: 'Dios sigue hablando en lo sencillo.',
    optimizedPreviewText: 'Dios sigue hablando en lo sencillo.',
    hookSource: null,
    coverImageFocusY: 0,
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
    content: const [
      {'insert': 'Primer párrafo de apertura.\nSegundo párrafo final.\n'},
    ],
  );
}
