import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/data/auth/auth_api_client.dart';
import 'package:holyverso/data/auth/models/auth_restore_result.dart';
import 'package:holyverso/data/auth/models/auth_payload.dart';
import 'package:holyverso/data/auth/models/user.dart';
import 'package:holyverso/data/auth/models/user_settings.dart';
import 'package:holyverso/data/auth/token_storage.dart';
import 'package:holyverso/core/errors/app_error_mapper.dart';

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
    await persistSessionSnapshot(
      user: payload.user,
      settings: payload.settings,
    );
    return payload;
  }

  Future<AuthPayload> login({
    required String email,
    required String password,
  }) async {
    final payload = await _client.login(email: email, password: password);
    await _persistToken(payload.accessToken);
    await persistSessionSnapshot(
      user: payload.user,
      settings: payload.settings,
    );
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

  Future<AuthRestoreResult> restoreSession() async {
    final token = await _tokenService.readToken();
    if (token == null || token.isEmpty) {
      return AuthRestoreResult.missing();
    }

    try {
      final profile = await _client.me();
      final payload = AuthPayload(
        user: profile.user,
        settings: profile.settings,
        accessToken: token,
      );
      await persistSessionSnapshot(
        user: payload.user,
        settings: payload.settings,
      );
      return AuthRestoreResult.authenticated(payload);
    } on DioException catch (error) {
      if (AppErrorMapper.isUnauthorized(error)) {
        await clearSession();
        return AuthRestoreResult.expired();
      }

      final snapshot = await _readSessionSnapshot(token);
      if (snapshot != null && AppErrorMapper.isRecoverableSessionError(error)) {
        return AuthRestoreResult.authenticatedStale(snapshot);
      }

      if (AppErrorMapper.isRecoverableSessionError(error)) {
        return AuthRestoreResult.missing();
      }

      rethrow;
    }
  }

  Future<void> logout() {
    return clearSession();
  }

  Future<void> deleteAccount() async {
    await _client.deleteAccount();
    await clearSession();
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

  Future<UserSettings> getNotificationPreferences() {
    return _client.getNotificationPreferences();
  }

  Future<UserSettings> updateNotificationPreferences({
    required bool devotionalNotificationsEnabled,
    required bool followedCreatorNotificationsEnabled,
    required bool featuredDevotionalNotificationsEnabled,
    required bool authorModerationNotificationsEnabled,
    required bool editorReviewNotificationsEnabled,
  }) {
    return _client.updateNotificationPreferences(
      devotionalNotificationsEnabled: devotionalNotificationsEnabled,
      followedCreatorNotificationsEnabled:
          followedCreatorNotificationsEnabled,
      featuredDevotionalNotificationsEnabled:
          featuredDevotionalNotificationsEnabled,
      authorModerationNotificationsEnabled:
          authorModerationNotificationsEnabled,
      editorReviewNotificationsEnabled: editorReviewNotificationsEnabled,
    );
  }

  Future<void> persistSessionSnapshot({
    required User user,
    UserSettings? settings,
  }) async {
    final snapshot = jsonEncode(
      AuthPayload(
        user: user,
        settings: settings,
      ).toMap(includeAccessToken: false),
    );
    await _tokenService.saveSessionSnapshot(snapshot);
  }

  Future<void> clearSession() async {
    await _tokenService.clearToken();
    await _tokenService.clearSessionSnapshot();
  }

  Future<void> _persistToken(String? token) async {
    if (token == null || token.isEmpty) {
      throw StateError('El servidor no retornó un token de acceso.');
    }
    await _tokenService.saveToken(token);
  }

  Future<AuthPayload?> _readSessionSnapshot(String token) async {
    final rawSnapshot = await _tokenService.readSessionSnapshot();
    if (rawSnapshot == null || rawSnapshot.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawSnapshot);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      return AuthPayload.fromMap(decoded).copyWith(accessToken: token);
    } catch (_) {
      return null;
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(authApiClientProvider),
    ref.watch(authTokenServiceProvider),
  );
});
