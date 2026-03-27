import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/core/theme/app_theme.dart';
import 'package:holyverso/data/devotionals/devotionals_api_client.dart';
import 'package:holyverso/data/devotionals/devotionals_repository.dart';
import 'package:holyverso/domain/devotionals/devotional.dart';
import 'package:holyverso/domain/devotionals/devotional_author.dart';
import 'package:holyverso/domain/devotionals/devotional_moderation_status.dart';
import 'package:holyverso/domain/devotionals/devotional_publication_state.dart';
import 'package:holyverso/domain/devotionals/devotional_status.dart';
import 'package:holyverso/domain/devotionals/devotional_verse_reference.dart';
import 'package:holyverso/presentation/screens/devotionals/devotional_editor_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows publish helper when the content is still too short', (
    tester,
  ) async {
    final client = _FakeEditorDevotionalsApiClient(
      loadedDevotional: _buildDevotional(
        contentText: 'Hola',
        status: DevotionalStatus.draft,
      ),
    );

    await tester.pumpWidget(_EditorTestApp(apiClient: client));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Para publicarlo, desarrolla un poco más la reflexión. Necesitas al menos 45 palabras y 3 oraciones o 2 párrafos con contenido.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'blocks publish locally for short content and does not call publish endpoint',
    (tester) async {
      final client = _FakeEditorDevotionalsApiClient(
        loadedDevotional: _buildDevotional(
          contentText: 'Hola',
          status: DevotionalStatus.draft,
        ),
      );

      await tester.pumpWidget(_EditorTestApp(apiClient: client));
      await tester.pumpAndSettle();

      final publishButton = find.widgetWithText(ElevatedButton, 'Publicar');
      await tester.scrollUntilVisible(
        publishButton,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(publishButton);
      await tester.pump();

      expect(
        find.text(
          'Aún no está listo para publicar. Desarrolla un poco más la reflexión: necesitas al menos 45 palabras y 3 oraciones o 2 párrafos con contenido.',
        ),
        findsOneWidget,
      );
      expect(client.publishCalls, 0);
      expect(client.updateCalls, 0);
    },
  );

  testWidgets(
    'shows backend quality gate message instead of generic save error',
    (tester) async {
      final client = _FakeEditorDevotionalsApiClient(
        loadedDevotional: _buildDevotional(
          contentText: _readyContent,
          status: DevotionalStatus.draft,
        ),
        publishError: _buildPublishError(
          code: 'DEVOTIONAL_QUALITY_GATE_FAILED',
          message: 'Agrega un poco más de reflexión antes de publicarlo.',
        ),
      );

      await tester.pumpWidget(_EditorTestApp(apiClient: client));
      await tester.pumpAndSettle();

      final publishButton = find.widgetWithText(ElevatedButton, 'Publicar');
      await tester.scrollUntilVisible(
        publishButton,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(publishButton);
      await tester.pump();

      expect(
        find.text('Agrega un poco más de reflexión antes de publicarlo.'),
        findsOneWidget,
      );
      expect(find.text('No pudimos guardar el devocional.'), findsNothing);
      expect(client.publishCalls, 1);
    },
  );

  testWidgets('allows saving a short draft', (tester) async {
    final client = _FakeEditorDevotionalsApiClient(
      loadedDevotional: _buildDevotional(
        contentText: 'Hola',
        status: DevotionalStatus.draft,
      ),
    );

    await tester.pumpWidget(_EditorTestApp(apiClient: client));
    await tester.pumpAndSettle();

    final saveDraftButton = find.widgetWithText(
      OutlinedButton,
      'Guardar borrador',
    );
    await tester.scrollUntilVisible(
      saveDraftButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(saveDraftButton);
    await tester.pumpAndSettle();

    expect(client.updateCalls, 1);
    expect(find.text('list-screen'), findsOneWidget);
  });
}

class _EditorTestApp extends StatelessWidget {
  const _EditorTestApp({required this.apiClient});

  final DevotionalsApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/devotionals/draft-1/edit',
      routes: [
        GoRoute(
          path: '/devotionals',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('list-screen'))),
        ),
        GoRoute(
          path: '/devotionals/:id/edit',
          builder: (context, state) =>
              DevotionalEditorScreen(devotionalId: state.pathParameters['id']),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        devotionalsRepositoryProvider.overrideWith(
          (ref) => DevotionalsRepository(apiClient),
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

class _FakeEditorDevotionalsApiClient extends DevotionalsApiClient {
  _FakeEditorDevotionalsApiClient({
    required this.loadedDevotional,
    this.publishError,
  }) : super(Dio());

  final Devotional loadedDevotional;
  final Object? publishError;
  int publishCalls = 0;
  int updateCalls = 0;

  @override
  Future<Devotional> getDevotional(
    String id, {
    String? shareToken,
    String? deviceId,
  }) async {
    return loadedDevotional;
  }

  @override
  Future<Devotional> updateDevotional({
    required String devotionalId,
    String? title,
    List<dynamic>? content,
    List<DevotionalVerseReference>? verseReferences,
    String? imageAssetId,
    double? coverImageFocusY,
    bool clearImageAsset = false,
  }) async {
    updateCalls += 1;
    return loadedDevotional.copyWith(content: content);
  }

  @override
  Future<Devotional> publishDevotional(String devotionalId) async {
    publishCalls += 1;
    if (publishError != null) {
      throw publishError!;
    }
    return loadedDevotional;
  }
}

DioException _buildPublishError({
  required String code,
  required String message,
}) {
  return DioException(
    requestOptions: RequestOptions(path: '/devotionals/draft-1/publish'),
    response: Response(
      requestOptions: RequestOptions(path: '/devotionals/draft-1/publish'),
      statusCode: 400,
      data: {
        'error': {'code': code, 'message': message},
      },
    ),
  );
}

Devotional _buildDevotional({
  required String contentText,
  required DevotionalStatus status,
}) {
  final now = DateTime(2026, 3, 26);
  return Devotional(
    id: 'draft-1',
    title: 'Un nuevo comienzo',
    status: status,
    publicationState: DevotionalPublicationState.draft,
    moderationStatus: DevotionalModerationStatus.clear,
    effectiveState: 'CLEAR',
    moderationReason: null,
    coverImageUrl: null,
    previewImageUrl: null,
    previewText: 'Vista previa',
    computedHook: 'Dios sigue obrando.',
    optimizedPreviewText: 'Dios sigue obrando aun cuando no lo ves.',
    hookSource: 'CONTENT_OPENING',
    coverImageFocusY: 0,
    viewCount: 0,
    estimatedReadTime: 1,
    publishedAt: null,
    firstPublishedAt: null,
    createdAt: now,
    updatedAt: now,
    author: const DevotionalAuthor(
      id: 'author-1',
      name: 'Autor',
      handle: 'autor',
      avatarUrl: null,
      following: false,
    ),
    verseReferences: const [
      DevotionalVerseReference(
        id: 'ref-1',
        book: 'Ezequiel',
        chapter: 6,
        verseStart: 8,
        verseEnd: null,
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
    isOwner: true,
    canModerate: false,
    deliveryToken: null,
    recommendationReason: null,
    feedContextReason: null,
    content: [
      {'insert': '$contentText\n'},
    ],
  );
}

const _readyContent =
    'Cuando el cansancio pesa sobre el alma, Dios sigue acercandose con paciencia para recordarte que su gracia no depende de tu fuerza, sino de su fidelidad constante en medio del proceso. '
    'Aun en los dias donde no entiendes el rumbo, su palabra abre espacio para respirar, ordenar el corazon y volver a escuchar la verdad que sostiene tu fe. '
    'Si hoy avanzas despacio, camina igual, porque el Senor tambien trabaja en silencio y transforma tu historia mientras aprendes a confiar otra vez.';
