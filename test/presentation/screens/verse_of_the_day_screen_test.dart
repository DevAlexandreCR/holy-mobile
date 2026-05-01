import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holyverso/core/services/app_runtime_storage.dart';
import 'package:holyverso/data/auth/models/user.dart';
import 'package:holyverso/data/widget/models/widget_install_status.dart';
import 'package:holyverso/data/widget/widget_verse_storage.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/core/theme/app_theme.dart';
import 'package:holyverso/domain/roles/user_role.dart';
import 'package:holyverso/domain/verse/verse_of_the_day.dart';
import 'package:holyverso/presentation/screens/verse/verse_of_the_day_screen.dart';
import 'package:holyverso/presentation/state/auth/auth_controller.dart';
import 'package:holyverso/presentation/state/auth/auth_state.dart';
import 'package:holyverso/presentation/state/verse/saved_verses_controller.dart';
import 'package:holyverso/presentation/state/verse/saved_verses_state.dart';
import 'package:holyverso/presentation/state/verse/widget_adoption_prompt_controller.dart';
import 'package:holyverso/presentation/state/verse/verse_controller.dart';
import 'package:holyverso/presentation/state/verse/verse_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders verse content using localized labels', (tester) async {
    final verse = VerseOfTheDay(
      date: '2024-06-01',
      versionCode: 'rv1960',
      versionName: 'Reina-Valera 1960',
      reference: 'Juan 3:16',
      text: 'Porque de tal manera amó Dios al mundo...',
    );

    final fakeController = _FakeVerseController(VerseState(verse: verse));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          verseControllerProvider.overrideWith(() => fakeController),
          authControllerProvider.overrideWith(_AuthenticatedAuthController.new),
          savedVersesControllerProvider.overrideWith(_FakeSavedController.new),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: const VerseOfTheDayScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.textContaining(verse.text), findsOneWidget);
    expect(find.text(verse.reference), findsOneWidget);
    expect(find.textContaining(verse.versionName), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    expect(find.byIcon(Icons.share_outlined), findsOneWidget);
    expect(find.byTooltip('Compartir'), findsOneWidget);
    expect(fakeController.loadCalls, 1);
  });

  testWidgets('keeps cached verse visible and shows soft message on fallback', (
    tester,
  ) async {
    final fakeController = _FallbackVerseController(
      VerseState(verse: _verseFixture),
      const VerseState(
        verse: _verseFixture,
        errorMessage: 'No pudimos actualizar la información en este momento.',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          verseControllerProvider.overrideWith(() => fakeController),
          authControllerProvider.overrideWith(_AuthenticatedAuthController.new),
          savedVersesControllerProvider.overrideWith(_FakeSavedController.new),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: const VerseOfTheDayScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.textContaining(_verseFixture.text), findsOneWidget);
    expect(
      find.text('No pudimos actualizar la información en este momento.'),
      findsOneWidget,
    );
  });

  testWidgets('shows friendly inline error when no verse is available', (
    tester,
  ) async {
    final fakeController = _FallbackVerseController(
      const VerseState(),
      const VerseState(errorMessage: 'No pudimos cargar el versículo de hoy.'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          verseControllerProvider.overrideWith(() => fakeController),
          authControllerProvider.overrideWith(_AuthenticatedAuthController.new),
          savedVersesControllerProvider.overrideWith(_FakeSavedController.new),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: const VerseOfTheDayScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('No pudimos cargar el versículo de hoy.'), findsOneWidget);
  });

  testWidgets('shows widget adoption prompt for authenticated users', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        verseControllerProvider.overrideWith(
          () => _FakeVerseController(VerseState(verse: _verseFixture)),
        ),
        authControllerProvider.overrideWith(_AuthenticatedAuthController.new),
        savedVersesControllerProvider.overrideWith(_FakeSavedController.new),
        widgetVerseStorageProvider.overrideWithValue(
          _FakeWidgetVerseStorage(
            const WidgetInstallStatus(isInstalled: false, isHeuristic: false),
          ),
        ),
        appRuntimeStorageProvider.overrideWithValue(
          _FakeAppRuntimeStorage(null),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: const VerseOfTheDayScreen(),
        ),
      ),
    );

    await tester.pump();
    await container
        .read(widgetAdoptionPromptControllerProvider.notifier)
        .refreshStatus();
    await tester.pump();
    expect(
      container.read(widgetAdoptionPromptControllerProvider).shouldShowPrompt,
      isTrue,
    );
    await tester.scrollUntilVisible(
      find.text('Lleva este versículo a tu pantalla de inicio'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(
      find.text('Lleva este versículo a tu pantalla de inicio'),
      findsOneWidget,
    );
    expect(find.text('Cómo agregarlo'), findsOneWidget);
  });

  testWidgets('dismisses widget adoption prompt from the verse screen', (
    tester,
  ) async {
    final runtimeStorage = _FakeAppRuntimeStorage(null);
    final container = ProviderContainer(
      overrides: [
        verseControllerProvider.overrideWith(
          () => _FakeVerseController(VerseState(verse: _verseFixture)),
        ),
        authControllerProvider.overrideWith(_AuthenticatedAuthController.new),
        savedVersesControllerProvider.overrideWith(_FakeSavedController.new),
        widgetVerseStorageProvider.overrideWithValue(
          _FakeWidgetVerseStorage(
            const WidgetInstallStatus(isInstalled: false, isHeuristic: false),
          ),
        ),
        appRuntimeStorageProvider.overrideWithValue(runtimeStorage),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: const VerseOfTheDayScreen(),
        ),
      ),
    );

    await tester.pump();
    await container
        .read(widgetAdoptionPromptControllerProvider.notifier)
        .refreshStatus();
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Recordármelo en 7 días'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Recordármelo en 7 días'));
    await tester.pump();
    await tester.tap(find.text('Recordármelo en 7 días'));
    await tester.pump();

    expect(
      container.read(widgetAdoptionPromptControllerProvider).shouldShowPrompt,
      isFalse,
    );
    expect(runtimeStorage.dismissedUntil, isNotNull);
  });
}

const _verseFixture = VerseOfTheDay(
  date: '2024-06-01',
  versionCode: 'rv1960',
  versionName: 'Reina-Valera 1960',
  reference: 'Juan 3:16',
  text: 'Porque de tal manera amó Dios al mundo...',
);

class _FakeVerseController extends VerseController {
  _FakeVerseController(this.initialState);

  final VerseState initialState;
  int loadCalls = 0;

  @override
  VerseState build() => initialState;

  @override
  Future<void> loadVerse({bool forceRefresh = false}) async {
    loadCalls++;
  }
}

class _FallbackVerseController extends VerseController {
  _FallbackVerseController(this.initialState, this.nextState);

  final VerseState initialState;
  final VerseState nextState;

  @override
  VerseState build() => initialState;

  @override
  Future<void> loadVerse({bool forceRefresh = false}) async {
    state = nextState;
  }
}

class _AuthenticatedAuthController extends AuthController {
  @override
  AuthState build() {
    return const AuthState(
      user: User(
        id: '1',
        name: 'Tester',
        email: 'tester@example.com',
        role: UserRole.user,
      ),
      sessionStatus: AuthSessionStatus.authenticated,
    );
  }
}

class _FakeSavedController extends SavedVersesController {
  @override
  SavedVersesState build() => const SavedVersesState();
}

class _FakeWidgetVerseStorage extends WidgetVerseStorage {
  _FakeWidgetVerseStorage(this.installStatus);

  final WidgetInstallStatus installStatus;

  @override
  Future<WidgetInstallStatus> readInstallStatus() async => installStatus;
}

class _FakeAppRuntimeStorage extends AppRuntimeStorage {
  _FakeAppRuntimeStorage(this.dismissedUntil);

  DateTime? dismissedUntil;

  @override
  Future<DateTime?> readWidgetPromptDismissedUntil() async => dismissedUntil;

  @override
  Future<void> saveWidgetPromptDismissedUntil(DateTime value) async {
    dismissedUntil = value;
  }
}
