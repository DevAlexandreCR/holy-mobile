import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holyverso/data/auth/models/user.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/core/theme/app_theme.dart';
import 'package:holyverso/domain/roles/user_role.dart';
import 'package:holyverso/domain/verse/verse_of_the_day.dart';
import 'package:holyverso/presentation/screens/verse/verse_of_the_day_screen.dart';
import 'package:holyverso/presentation/state/auth/auth_controller.dart';
import 'package:holyverso/presentation/state/auth/auth_state.dart';
import 'package:holyverso/presentation/state/verse/saved_verses_controller.dart';
import 'package:holyverso/presentation/state/verse/saved_verses_state.dart';
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
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    expect(find.byIcon(Icons.ios_share), findsAtLeastNWidgets(1));
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
