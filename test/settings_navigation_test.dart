import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/data/auth/models/user.dart';
import 'package:holyverso/data/auth/models/user_settings.dart';
import 'package:holyverso/data/bible/bible_repository.dart';
import 'package:holyverso/data/bible/bible_api_client.dart';
import 'package:holyverso/data/bible/models/bible_version.dart';
import 'package:holyverso/domain/roles/user_role.dart';
import 'package:holyverso/domain/verse/bible_book.dart';
import 'package:holyverso/domain/verse/book_suggestion.dart';
import 'package:holyverso/domain/verse/chapter.dart';
import 'package:holyverso/domain/verse/search_result.dart';
import 'package:holyverso/domain/verse/verse_of_the_day.dart';
import 'package:holyverso/presentation/state/auth/auth_controller.dart';
import 'package:holyverso/presentation/state/auth/auth_state.dart';
import 'package:holyverso/presentation/screens/settings/settings_screen.dart';
import 'package:holyverso/presentation/state/verse/saved_verses_controller.dart';
import 'package:holyverso/presentation/state/verse/saved_verses_state.dart';
import 'package:holyverso/presentation/state/verse/verse_controller.dart';
import 'package:holyverso/presentation/state/verse/verse_state.dart';

class _FakeAuthController extends AuthController {
  @override
  AuthState build() {
    return const AuthState(
      user: User(
        id: '1',
        name: 'Test User',
        email: 'test@example.com',
        role: UserRole.user,
      ),
      settings: UserSettings(preferredVersionId: 4),
      sessionStatus: AuthSessionStatus.authenticated,
    );
  }

  @override
  Future<bool> updatePreferredVersion(int versionId) async {
    state = state.copyWith(isUpdatingSettings: true, clearError: true);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    state = state.copyWith(
      settings: UserSettings(preferredVersionId: versionId),
      isUpdatingSettings: false,
    );
    return true;
  }

  @override
  Future<void> logout() async {
    state = const AuthState(sessionStatus: AuthSessionStatus.guest);
  }
}

class _FakeVerseController extends VerseController {
  @override
  VerseState build() {
    return VerseState(
      verse: const VerseOfTheDay(
        date: '2024-01-01',
        versionCode: 'kjv',
        versionName: 'King James',
        reference: 'Jn 3:16',
        text: 'For God so loved the world...',
      ),
    );
  }

  @override
  Future<void> loadVerse({bool forceRefresh = false}) async {}
}

class _FakeBibleRepository extends BibleRepository {
  _FakeBibleRepository() : super(_FakeBibleApiClient());

  @override
  Future<List<BibleVersion>> fetchVersions({bool forceRefresh = false}) async {
    return const [
      BibleVersion(
        id: 4,
        apiCode: 'dhh',
        name: 'Dios Habla Hoy',
        language: 'es',
      ),
      BibleVersion(id: 6, apiCode: 'kjv', name: 'King James', language: 'en'),
    ];
  }
}

class _FakeBibleApiClient implements BibleApiClient {
  @override
  Future<List<BibleVersion>> getVersions() async => const [];

  @override
  Future<List<BibleBook>> getBooks() async => const [];

  @override
  Future<SearchResult?> searchVerses(String query, {int? versionId}) async {
    return null;
  }

  @override
  Future<List<BookSuggestion>> getAutocompleteSuggestions(String query) async {
    return const [];
  }

  @override
  Future<Chapter> getChapter({required String book, required int chapter}) {
    throw UnimplementedError();
  }
}

class _FakeSavedVersesController extends SavedVersesController {
  @override
  SavedVersesState build() => const SavedVersesState();

  @override
  Future<void> loadInitialSaved() async {}
}

void main() {
  testWidgets('settings screen builds without errors', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_FakeAuthController.new),
          verseControllerProvider.overrideWith(_FakeVerseController.new),
          savedVersesControllerProvider.overrideWith(
            _FakeSavedVersesController.new,
          ),
          bibleRepositoryProvider.overrideWith((ref) => _FakeBibleRepository()),
        ],
        child: MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const SettingsScreen(showBackButton: true),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Cerrar sesión'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Cerrar sesión'), findsOneWidget);
  });
}
