import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/data/auth/auth_api_client.dart';
import 'package:holyverso/data/auth/auth_repository.dart';
import 'package:holyverso/data/auth/models/auth_payload.dart';
import 'package:holyverso/data/auth/models/auth_restore_result.dart';
import 'package:holyverso/data/auth/models/user.dart';
import 'package:holyverso/data/auth/models/user_settings.dart';
import 'package:holyverso/data/auth/token_storage.dart';
import 'package:holyverso/domain/roles/user_role.dart';
import 'package:holyverso/presentation/state/auth/auth_controller.dart';
import 'package:holyverso/presentation/state/auth/auth_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthController bootstrap', () {
    test('token missing resolves to guest', () async {
      final container = _buildContainer(AuthRestoreResult.missing());
      addTearDown(container.dispose);

      container.read(authControllerProvider);
      await _flushAsyncWork();

      final state = container.read(authControllerProvider);
      expect(state.sessionStatus, AuthSessionStatus.guest);
      expect(state.isAuthenticated, isFalse);
    });

    test('validated session resolves to authenticated', () async {
      final container = _buildContainer(
        AuthRestoreResult.authenticated(_payload()),
      );
      addTearDown(container.dispose);

      container.read(authControllerProvider);
      await _flushAsyncWork();

      final state = container.read(authControllerProvider);
      expect(state.sessionStatus, AuthSessionStatus.authenticated);
      expect(state.isAuthenticated, isTrue);
      expect(state.user?.email, 'tester@example.com');
    });

    test('expired session resolves to expired state', () async {
      final container = _buildContainer(AuthRestoreResult.expired());
      addTearDown(container.dispose);

      container.read(authControllerProvider);
      await _flushAsyncWork();

      final state = container.read(authControllerProvider);
      expect(state.sessionStatus, AuthSessionStatus.expired);
      expect(state.isAuthenticated, isFalse);
      expect(state.infoMessage, isNotEmpty);
    });

    test(
      'offline with cached snapshot resolves to authenticatedStale',
      () async {
        final container = _buildContainer(
          AuthRestoreResult.authenticatedStale(_payload()),
        );
        addTearDown(container.dispose);

        container.read(authControllerProvider);
        await _flushAsyncWork();

        final state = container.read(authControllerProvider);
        expect(state.sessionStatus, AuthSessionStatus.authenticatedStale);
        expect(state.isAuthenticated, isTrue);
        expect(state.infoMessage, isNotEmpty);
      },
    );

    test('offline without snapshot resolves to guest', () async {
      final container = _buildContainer(AuthRestoreResult.missing());
      addTearDown(container.dispose);

      container.read(authControllerProvider);
      await _flushAsyncWork();

      final state = container.read(authControllerProvider);
      expect(state.sessionStatus, AuthSessionStatus.guest);
      expect(state.isAuthenticated, isFalse);
    });
  });
}

ProviderContainer _buildContainer(AuthRestoreResult restoreResult) {
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWith(
        (ref) => _FakeAuthRepository(restoreResult),
      ),
    ],
  );
}

Future<void> _flushAsyncWork() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(const Duration(milliseconds: 10));
}

AuthPayload _payload() {
  return const AuthPayload(
    user: User(
      id: '1',
      name: 'Tester',
      email: 'tester@example.com',
      role: UserRole.user,
    ),
    settings: UserSettings(preferredVersionId: 4, timezone: 'America/Bogota'),
    accessToken: 'token',
  );
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository(this._restoreResult)
    : super(AuthApiClient(Dio()), AuthTokenService());

  final AuthRestoreResult _restoreResult;

  @override
  Future<AuthRestoreResult> restoreSession() async => _restoreResult;

  @override
  Future<void> persistSessionSnapshot({
    required User user,
    UserSettings? settings,
  }) async {}

  @override
  Future<void> clearSession() async {}
}
