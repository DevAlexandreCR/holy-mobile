import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/data/auth/auth_api_client.dart';
import 'package:holyverso/data/auth/models/auth_payload.dart';
import 'package:holyverso/data/auth/models/user_settings.dart';
import 'package:holyverso/data/auth/token_storage.dart';

class AuthRepository {
  AuthRepository(this._client, this._tokenService);

  final AuthApiClient _client;
  final AuthTokenService _tokenService;

  Future<AuthPayload> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final payload = await _client.register(
      name: name,
      email: email,
      password: password,
    );
    await _persistToken(payload.accessToken);
    return payload;
  }

  Future<AuthPayload> login({
    required String email,
    required String password,
  }) async {
    final payload = await _client.login(email: email, password: password);
    await _persistToken(payload.accessToken);
    return payload;
  }

  Future<void> forgotPassword(String email) {
    return _client.forgotPassword(email: email);
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) {
    return _client.resetPassword(token: token, newPassword: newPassword);
  }

  Future<AuthPayload?> restoreSession() async {
    final token = await _tokenService.readToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final profile = await _client.me();
      return AuthPayload(
        user: profile.user,
        settings: profile.settings,
        accessToken: token,
      );
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status == 401 || status == 403) {
        await _tokenService.clearToken();
        return null;
      }
      rethrow;
    }
  }

  Future<void> logout() {
    return _tokenService.clearToken();
  }

  Future<void> deleteAccount() async {
    await _client.deleteAccount();
    await _tokenService.clearToken();
  }

  Future<UserSettings> updatePreferredVersion(int versionId) {
    return _client.updatePreferredVersion(versionId);
  }

  Future<UserSettings> updateWidgetFontSize(String fontSize) {
    return _client.updateWidgetFontSize(fontSize);
  }

  Future<UserSettings> updateTimezone(String timezone) {
    return _client.updateTimezone(timezone);
  }

  Future<void> _persistToken(String? token) async {
    if (token == null || token.isEmpty) {
      throw StateError('El servidor no retornó un token de acceso.');
    }
    await _tokenService.saveToken(token);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(authApiClientProvider),
    ref.watch(authTokenServiceProvider),
  );
});
