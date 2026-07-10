import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holyverso/data/auth/auth_api_client.dart';
import 'package:holyverso/data/auth/auth_repository.dart';
import 'package:holyverso/data/auth/models/auth_payload.dart';
import 'package:holyverso/data/auth/models/auth_restore_result.dart';
import 'package:holyverso/data/auth/models/user.dart';
import 'package:holyverso/data/auth/models/user_settings.dart';
import 'package:holyverso/data/auth/token_storage.dart';
import 'package:holyverso/domain/roles/user_role.dart';

void main() {
  const storedToken = 'stored-token';

  group('AuthRepository.restoreSession definitive rejection', () {
    test('401 clears the session and resolves to expired', () async {
      final tokenService = _FakeAuthTokenService(initialToken: storedToken);
      final apiClient = _FakeAuthApiClient(
        meHandler: (_) async => throw _dioError(statusCode: 401),
      );
      final repository = AuthRepository(apiClient, tokenService);

      final result = await repository.restoreSession();

      expect(result.status, AuthRestoreStatus.expired);
      expect(tokenService.clearTokenCalled, isTrue);
      expect(tokenService.clearSessionSnapshotCalled, isTrue);
      expect(await tokenService.readToken(), isNull);
      expect(apiClient.meCallCount, 1);
    });

    test('403 clears the session and resolves to expired', () async {
      final tokenService = _FakeAuthTokenService(initialToken: storedToken);
      final apiClient = _FakeAuthApiClient(
        meHandler: (_) async => throw _dioError(statusCode: 403),
      );
      final repository = AuthRepository(apiClient, tokenService);

      final result = await repository.restoreSession();

      expect(result.status, AuthRestoreStatus.expired);
      expect(tokenService.clearTokenCalled, isTrue);
      expect(await tokenService.readToken(), isNull);
      expect(apiClient.meCallCount, 1);
    });

    test(
      'account-gone USER_NOT_FOUND clears the session and resolves to expired',
      () async {
        final tokenService = _FakeAuthTokenService(initialToken: storedToken);
        final apiClient = _FakeAuthApiClient(
          meHandler: (_) async => throw _dioError(
            statusCode: 404,
            errorCode: 'USER_NOT_FOUND',
          ),
        );
        final repository = AuthRepository(apiClient, tokenService);

        final result = await repository.restoreSession();

        expect(result.status, AuthRestoreStatus.expired);
        expect(tokenService.clearTokenCalled, isTrue);
        expect(await tokenService.readToken(), isNull);
        expect(apiClient.meCallCount, 1);
      },
    );

    test(
      'account-gone ACCOUNT_DELETED clears the session and resolves to expired',
      () async {
        final tokenService = _FakeAuthTokenService(initialToken: storedToken);
        final apiClient = _FakeAuthApiClient(
          meHandler: (_) async => throw _dioError(
            statusCode: 404,
            errorCode: 'ACCOUNT_DELETED',
          ),
        );
        final repository = AuthRepository(apiClient, tokenService);

        final result = await repository.restoreSession();

        expect(result.status, AuthRestoreStatus.expired);
        expect(tokenService.clearTokenCalled, isTrue);
        expect(await tokenService.readToken(), isNull);
        expect(apiClient.meCallCount, 1);
      },
    );
  });

  group('AuthRepository.restoreSession recoverable failure', () {
    test(
      'network error with a cached snapshot resolves to authenticatedStale and keeps the token',
      () async {
        final snapshot = _snapshotJson();
        final tokenService = _FakeAuthTokenService(
          initialToken: storedToken,
          initialSnapshot: snapshot,
        );
        final apiClient = _FakeAuthApiClient(
          meHandler: (_) async =>
              throw _dioError(type: DioExceptionType.connectionError),
        );
        final repository = AuthRepository(apiClient, tokenService);

        final result = await repository.restoreSession();

        expect(result.status, AuthRestoreStatus.authenticatedStale);
        expect(result.payload, isNotNull);
        expect(tokenService.clearTokenCalled, isFalse);
        expect(await tokenService.readToken(), storedToken);
        expect(apiClient.meCallCount, 3);
      },
    );

    test(
      'timeout followed by a 5xx with a cached snapshot resolves to authenticatedStale',
      () async {
        final snapshot = _snapshotJson();
        final tokenService = _FakeAuthTokenService(
          initialToken: storedToken,
          initialSnapshot: snapshot,
        );
        final apiClient = _FakeAuthApiClient(
          meHandler: (call) async {
            if (call == 1) {
              throw _dioError(type: DioExceptionType.connectionTimeout);
            }
            throw _dioError(statusCode: 500);
          },
        );
        final repository = AuthRepository(apiClient, tokenService);

        final result = await repository.restoreSession();

        expect(result.status, AuthRestoreStatus.authenticatedStale);
        expect(tokenService.clearTokenCalled, isFalse);
        expect(await tokenService.readToken(), storedToken);
      },
    );

    test(
      'recoverable failure without a cached snapshot resolves to reconnecting and keeps the token',
      () async {
        final tokenService = _FakeAuthTokenService(initialToken: storedToken);
        final apiClient = _FakeAuthApiClient(
          meHandler: (_) async =>
              throw _dioError(type: DioExceptionType.connectionError),
        );
        final repository = AuthRepository(apiClient, tokenService);

        final result = await repository.restoreSession();

        expect(result.status, AuthRestoreStatus.reconnecting);
        expect(result.payload, isNull);
        expect(tokenService.clearTokenCalled, isFalse);
        expect(tokenService.clearSessionSnapshotCalled, isFalse);
        expect(await tokenService.readToken(), storedToken);
        expect(apiClient.meCallCount, 3);
      },
    );
  });

  group('AuthRepository.restoreSession success', () {
    test('200 resolves to authenticated and persists a snapshot', () async {
      final tokenService = _FakeAuthTokenService(initialToken: storedToken);
      final payload = _payload();
      final apiClient = _FakeAuthApiClient(
        meHandler: (_) async => payload,
      );
      final repository = AuthRepository(apiClient, tokenService);

      final result = await repository.restoreSession();

      expect(result.status, AuthRestoreStatus.authenticated);
      expect(result.payload?.user.email, payload.user.email);
      expect(tokenService.clearTokenCalled, isFalse);
      expect(await tokenService.readToken(), storedToken);
      expect(await tokenService.readSessionSnapshot(), isNotNull);
      expect(apiClient.meCallCount, 1);
    });
  });
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
  );
}

String _snapshotJson() {
  return '{"user":{"id":"1","name":"Tester","email":"tester@example.com","role":"user","moderation":{}},"settings":{"preferred_version_id":4,"timezone":"America/Bogota"}}';
}

DioException _dioError({
  int? statusCode,
  String? errorCode,
  DioExceptionType type = DioExceptionType.badResponse,
}) {
  final requestOptions = RequestOptions(path: '/auth/me');
  final response = statusCode == null
      ? null
      : Response(
          requestOptions: requestOptions,
          statusCode: statusCode,
          data: errorCode == null
              ? null
              : {
                  'error': {'code': errorCode, 'message': 'error'},
                },
        );
  return DioException(
    requestOptions: requestOptions,
    response: response,
    type: type,
  );
}

class _FakeAuthApiClient extends AuthApiClient {
  _FakeAuthApiClient({required this.meHandler}) : super(Dio());

  final Future<AuthPayload> Function(int callNumber) meHandler;
  int meCallCount = 0;

  @override
  Future<AuthPayload> me() async {
    meCallCount++;
    return meHandler(meCallCount);
  }
}

class _FakeAuthTokenService extends AuthTokenService {
  _FakeAuthTokenService({String? initialToken, String? initialSnapshot})
    : _token = initialToken,
      _snapshot = initialSnapshot;

  String? _token;
  String? _snapshot;
  bool clearTokenCalled = false;
  bool clearSessionSnapshotCalled = false;

  @override
  Future<void> saveToken(String token) async {
    _token = token;
  }

  @override
  Future<String?> readToken() async => _token;

  @override
  Future<void> saveSessionSnapshot(String snapshot) async {
    _snapshot = snapshot;
  }

  @override
  Future<String?> readSessionSnapshot() async => _snapshot;

  @override
  Future<void> clearToken() async {
    clearTokenCalled = true;
    _token = null;
  }

  @override
  Future<void> clearSessionSnapshot() async {
    clearSessionSnapshotCalled = true;
    _snapshot = null;
  }
}
