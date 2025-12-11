import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holy_mobile/data/auth/models/user.dart';
import 'package:holy_mobile/data/auth/models/user_settings.dart';
import 'package:holy_mobile/data/bible/bible_repository.dart';
import 'package:holy_mobile/data/bible/models/bible_version.dart';
import 'package:holy_mobile/presentation/state/auth/auth_controller.dart';
import 'package:holy_mobile/presentation/state/auth/auth_state.dart';
import 'package:holy_mobile/presentation/state/settings/versions_controller.dart';
import 'package:holy_mobile/presentation/state/verse/verse_controller.dart';
import 'package:holy_mobile/presentation/state/verse/verse_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VersionsController', () {
    late FakeAuthController fakeAuth;
    late FakeVerseController fakeVerse;
    late ProviderContainer container;

    setUp(() {
      fakeAuth = FakeAuthController();
      fakeVerse = FakeVerseController();
      container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(() => fakeAuth),
          verseControllerProvider.overrideWith(() => fakeVerse),
          bibleRepositoryProvider.overrideWith(
            (ref) => _StubBibleRepository(
              const [
                BibleVersion(
                  id: 1,
                  apiCode: 'rv1960',
                  name: 'Reina-Valera 1960',
                  language: 'es',
                ),
                BibleVersion(
                  id: 2,
                  apiCode: 'dhh',
                  name: 'Dios Habla Hoy',
                  language: 'es',
                ),
              ],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
    });

    test('loads versions from repository', () async {
      await container.read(versionsControllerProvider.notifier).loadVersions();

      final state = container.read(versionsControllerProvider);
      expect(state.versions.length, 2);
      expect(state.hasLoaded, isTrue);
      expect(state.isLoading, isFalse);
    });

    test('selectVersion updates auth settings and refreshes verse', () async {
      await container.read(versionsControllerProvider.notifier).loadVersions();

      final success =
          await container.read(versionsControllerProvider.notifier).selectVersion(2);

      expect(success, isTrue);
      expect(fakeAuth.updatedVersionIds, contains(2));
      expect(fakeAuth.state.settings?.preferredVersionId, 2);
      expect(fakeVerse.refreshCount, 1);
    });

    test('selectVersion surfaces auth errors', () async {
      fakeAuth.shouldFailUpdate = true;

      final success =
          await container.read(versionsControllerProvider.notifier).selectVersion(3);
      final state = container.read(versionsControllerProvider);

      expect(success, isFalse);
      expect(state.errorMessage, isNotEmpty);
    });
  });
}

class _StubBibleRepository implements BibleRepository {
  _StubBibleRepository(this._versions);

  final List<BibleVersion> _versions;

  @override
  Future<List<BibleVersion>> fetchVersions({bool forceRefresh = false}) async {
    return _versions;
  }
}

class FakeAuthController extends AuthController {
  final List<int> updatedVersionIds = [];
  bool shouldFailUpdate = false;

  @override
  AuthState build() {
    return const AuthState(
      user: User(id: '1', name: 'Tester', email: 'tester@example.com'),
      settings: UserSettings(preferredVersionId: 1, timezone: 'UTC'),
    );
  }

  @override
  Future<bool> updatePreferredVersion(int versionId) async {
    updatedVersionIds.add(versionId);

    if (shouldFailUpdate) {
      state = state.copyWith(
        isUpdatingSettings: false,
        errorMessage: 'auth-error',
      );
      return false;
    }

    state = state.copyWith(
      settings: UserSettings(
        preferredVersionId: versionId,
        timezone: state.settings?.timezone,
      ),
      isUpdatingSettings: false,
    );
    return true;
  }
}

class FakeVerseController extends VerseController {
  int refreshCount = 0;

  @override
  VerseState build() => const VerseState();

  @override
  Future<void> loadVerse({bool forceRefresh = false}) async {
    refreshCount++;
  }
}
