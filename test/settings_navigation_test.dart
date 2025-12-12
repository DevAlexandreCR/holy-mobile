import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holy_mobile/data/auth/models/user.dart';
import 'package:holy_mobile/data/auth/models/user_settings.dart';
import 'package:holy_mobile/data/bible/bible_repository.dart';
import 'package:holy_mobile/data/bible/bible_api_client.dart';
import 'package:holy_mobile/data/bible/models/bible_version.dart';
import 'package:holy_mobile/domain/verse/verse_of_the_day.dart';
import 'package:holy_mobile/presentation/state/auth/auth_controller.dart';
import 'package:holy_mobile/presentation/state/auth/auth_state.dart';
import 'package:holy_mobile/presentation/screens/settings/settings_screen.dart';
import 'package:holy_mobile/presentation/state/verse/verse_controller.dart';
import 'package:holy_mobile/presentation/state/verse/verse_state.dart';
import 'package:holy_mobile/main.dart';

class _FakeAuthController extends AuthController {
  @override
  AuthState build() {
    return const AuthState(
      user: User(id: '1', name: 'Test User', email: 'test@example.com'),
      settings: UserSettings(preferredVersionId: 4),
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
    state = const AuthState();
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
      BibleVersion(id: 4, apiCode: 'dhh', name: 'Dios Habla Hoy', language: 'es'),
      BibleVersion(id: 6, apiCode: 'kjv', name: 'King James', language: 'en'),
    ];
  }
}

class _FakeBibleApiClient implements BibleApiClient {
  @override
  Future<List<BibleVersion>> getVersions() async => const [];
}

void main() {
  testWidgets('navigating to settings builds without errors', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_FakeAuthController.new),
          verseControllerProvider.overrideWith(_FakeVerseController.new),
          bibleRepositoryProvider.overrideWith((ref) => _FakeBibleRepository()),
        ],
        child: const HolyVersoApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);

  });
}
