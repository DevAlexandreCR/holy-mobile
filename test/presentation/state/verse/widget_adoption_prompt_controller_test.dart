import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holyverso/core/services/app_runtime_storage.dart';
import 'package:holyverso/data/auth/models/user.dart';
import 'package:holyverso/data/widget/models/widget_install_status.dart';
import 'package:holyverso/data/widget/widget_verse_storage.dart';
import 'package:holyverso/domain/roles/user_role.dart';
import 'package:holyverso/presentation/state/auth/auth_controller.dart';
import 'package:holyverso/presentation/state/auth/auth_state.dart';
import 'package:holyverso/presentation/state/verse/widget_adoption_prompt_controller.dart';

void main() {
  test(
    'shows prompt when authenticated, not installed, and dismissal expired',
    () async {
      final container = _createContainer(
        installStatus: const WidgetInstallStatus(
          isInstalled: false,
          isHeuristic: false,
        ),
        dismissedUntil: DateTime.now().subtract(const Duration(days: 1)),
      );

      await container
          .read(widgetAdoptionPromptControllerProvider.notifier)
          .refreshStatus();

      final state = container.read(widgetAdoptionPromptControllerProvider);
      expect(state.shouldShowPrompt, isTrue);
    },
  );

  test('hides prompt when Android reports an installed widget', () async {
    final container = _createContainer(
      installStatus: const WidgetInstallStatus(
        isInstalled: true,
        isHeuristic: false,
        widgetCount: 1,
      ),
    );

    await container
        .read(widgetAdoptionPromptControllerProvider.notifier)
        .refreshStatus();

    final state = container.read(widgetAdoptionPromptControllerProvider);
    expect(state.shouldShowPrompt, isFalse);
  });

  test('hides prompt when iOS heuristic heartbeat is fresh', () async {
    final container = _createContainer(
      installStatus: WidgetInstallStatus(
        isInstalled: true,
        isHeuristic: true,
        detectedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    );

    await container
        .read(widgetAdoptionPromptControllerProvider.notifier)
        .refreshStatus();

    final state = container.read(widgetAdoptionPromptControllerProvider);
    expect(state.shouldShowPrompt, isFalse);
    expect(state.installStatus?.isHeuristic, isTrue);
  });

  test('shows prompt again when iOS heartbeat is stale', () async {
    final container = _createContainer(
      installStatus: WidgetInstallStatus(
        isInstalled: false,
        isHeuristic: true,
        detectedAt: DateTime.now().subtract(const Duration(hours: 72)),
      ),
    );

    await container
        .read(widgetAdoptionPromptControllerProvider.notifier)
        .refreshStatus();

    final state = container.read(widgetAdoptionPromptControllerProvider);
    expect(state.shouldShowPrompt, isTrue);
  });

  test('hides prompt while dismissal window is active', () async {
    final container = _createContainer(
      installStatus: const WidgetInstallStatus(
        isInstalled: false,
        isHeuristic: false,
      ),
      dismissedUntil: DateTime.now().add(const Duration(days: 3)),
    );

    await container
        .read(widgetAdoptionPromptControllerProvider.notifier)
        .refreshStatus();

    final state = container.read(widgetAdoptionPromptControllerProvider);
    expect(state.shouldShowPrompt, isFalse);
  });

  test('hides prompt for guests', () async {
    final container = _createContainer(
      installStatus: const WidgetInstallStatus(
        isInstalled: false,
        isHeuristic: false,
      ),
      isAuthenticated: false,
    );

    await container
        .read(widgetAdoptionPromptControllerProvider.notifier)
        .refreshStatus();

    final state = container.read(widgetAdoptionPromptControllerProvider);
    expect(state.shouldShowPrompt, isFalse);
  });
}

ProviderContainer _createContainer({
  required WidgetInstallStatus installStatus,
  DateTime? dismissedUntil,
  bool isAuthenticated = true,
}) {
  final widgetStorage = _FakeWidgetVerseStorage(installStatus);
  final runtimeStorage = _FakeAppRuntimeStorage(dismissedUntil);

  return ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith(
        isAuthenticated
            ? _AuthenticatedAuthController.new
            : _GuestAuthController.new,
      ),
      widgetVerseStorageProvider.overrideWithValue(widgetStorage),
      appRuntimeStorageProvider.overrideWithValue(runtimeStorage),
    ],
  );
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

  @override
  Future<void> clearWidgetPromptDismissedUntil() async {
    dismissedUntil = null;
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

class _GuestAuthController extends AuthController {
  @override
  AuthState build() {
    return const AuthState(sessionStatus: AuthSessionStatus.guest);
  }
}
