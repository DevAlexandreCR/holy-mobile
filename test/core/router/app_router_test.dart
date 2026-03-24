import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/core/router/app_router.dart';
import 'package:holyverso/core/theme/app_theme.dart';
import 'package:holyverso/data/auth/models/user.dart';
import 'package:holyverso/domain/verse/verse_of_the_day.dart';
import 'package:holyverso/domain/roles/user_role.dart';
import 'package:holyverso/presentation/providers/whats_new_provider.dart';
import 'package:holyverso/presentation/screens/auth/login_screen.dart';
import 'package:holyverso/presentation/screens/search/search_screen.dart';
import 'package:holyverso/presentation/screens/verse/saved_verses_screen.dart';
import 'package:holyverso/presentation/screens/verse/verse_of_the_day_screen.dart';
import 'package:holyverso/presentation/state/auth/auth_controller.dart';
import 'package:holyverso/presentation/state/auth/auth_state.dart';
import 'package:holyverso/presentation/state/roles/role_provider.dart';
import 'package:holyverso/presentation/state/verse/saved_verses_controller.dart';
import 'package:holyverso/presentation/state/verse/saved_verses_state.dart';
import 'package:holyverso/presentation/state/verse/verse_controller.dart';
import 'package:holyverso/presentation/state/verse/verse_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('guest can access home and search', (tester) async {
    final container = _buildContainer(
      const AuthState(sessionStatus: AuthSessionStatus.guest),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const _TestApp()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(VerseOfTheDayScreen), findsOneWidget);

    container.read(appRouterProvider).go('/search');
    await tester.pumpAndSettle();

    expect(find.byType(SearchScreen), findsOneWidget);
  });

  testWidgets('guest is redirected from protected routes', (tester) async {
    final container = _buildContainer(
      const AuthState(sessionStatus: AuthSessionStatus.guest),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const _TestApp()),
    );
    await tester.pumpAndSettle();

    for (final route in ['/saved', '/settings', '/devotionals']) {
      container.read(appRouterProvider).go(route);
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    }
  });

  testWidgets('authenticatedStale can remain on protected routes', (
    tester,
  ) async {
    final container = _buildContainer(
      const AuthState(
        user: _user,
        sessionStatus: AuthSessionStatus.authenticatedStale,
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const _TestApp()),
    );
    await tester.pumpAndSettle();

    container.read(appRouterProvider).go('/saved');
    await tester.pumpAndSettle();

    expect(find.byType(SavedVersesScreen), findsOneWidget);
  });

  testWidgets('expired session redirects to login with message', (
    tester,
  ) async {
    final container = _buildContainer(
      const AuthState(sessionStatus: AuthSessionStatus.expired),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const _TestApp()),
    );
    await tester.pumpAndSettle();

    final router = container.read(appRouterProvider);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/login');
    expect(
      router.routeInformationProvider.value.uri.queryParameters['message'],
      isNotEmpty,
    );
  });
}

const _user = User(
  id: '1',
  name: 'Tester',
  email: 'tester@example.com',
  role: UserRole.user,
);

ProviderContainer _buildContainer(AuthState authState) {
  return ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith(
        () => _StaticAuthController(authState),
      ),
      verseControllerProvider.overrideWith(_StaticVerseController.new),
      savedVersesControllerProvider.overrideWith(
        _StaticSavedVersesController.new,
      ),
      canManageUsersProvider.overrideWith((ref) => false),
      whatsNewProvider.overrideWith((ref) async => null),
    ],
  );
}

class _TestApp extends ConsumerWidget {
  const _TestApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('es'),
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}

class _StaticAuthController extends AuthController {
  _StaticAuthController(this.initialState);

  final AuthState initialState;

  @override
  AuthState build() => initialState;
}

class _StaticVerseController extends VerseController {
  @override
  VerseState build() {
    return const VerseState(
      verse: VerseOfTheDay(
        date: '2024-01-01',
        versionCode: 'rv1960',
        versionName: 'Reina-Valera 1960',
        reference: 'Juan 3:16',
        text: 'Porque de tal manera amó Dios al mundo...',
      ),
    );
  }

  @override
  Future<void> loadVerse({bool forceRefresh = false}) async {}
}

class _StaticSavedVersesController extends SavedVersesController {
  @override
  SavedVersesState build() => const SavedVersesState();

  @override
  Future<void> loadInitialSaved() async {}
}
