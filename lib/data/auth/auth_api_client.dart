import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/data/auth/models/auth_payload.dart';
import 'package:holyverso/data/auth/models/user_settings.dart';
import 'package:holyverso/data/network/api_client.dart';

class AuthApiClient {
  AuthApiClient(this._dio);

  final Dio _dio;

  Future<AuthPayload> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/register',
      data: {'name': name, 'email': email, 'password': password},
    );

    return AuthPayload.fromMap(response.data as Map<String, dynamic>);
  }

  Future<AuthPayload> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );

    return AuthPayload.fromMap(response.data as Map<String, dynamic>);
  }

  Future<void> forgotPassword({required String email}) {
    return _dio.post('/auth/forgot-password', data: {'email': email});
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) {
    return _dio.post(
      '/auth/reset-password',
      data: {'token': token, 'password': newPassword},
    );
  }

  Future<AuthPayload> me() async {
    final response = await _dio.get('/auth/me');
    return AuthPayload.fromMap(response.data as Map<String, dynamic>);
  }

  Future<UserSettings> updatePreferredVersion(int versionId) async {
    final response = await _dio.put(
      '/user/settings/version',
      data: {'version_id': versionId},
    );

    final rawData = response.data;
    final data = rawData is Map ? rawData['data'] ?? rawData : rawData;
    return UserSettings.fromMap(Map<String, dynamic>.from(data as Map));
  }

  Future<UserSettings> updateWidgetFontSize(String fontSize) async {
    final response = await _dio.put(
      '/user/settings/widget-font-size',
      data: {'widget_font_size': fontSize},
    );

    final rawData = response.data;
    final data = rawData is Map ? rawData['data'] ?? rawData : rawData;
    return UserSettings.fromMap(Map<String, dynamic>.from(data as Map));
  }

  Future<UserSettings> updateTimezone(String timezone) async {
    final response = await _dio.put(
      '/user/settings/timezone',
      data: {'timezone': timezone},
    );

    final rawData = response.data;
    final data = rawData is Map ? rawData['data'] ?? rawData : rawData;
    return UserSettings.fromMap(Map<String, dynamic>.from(data as Map));
  }
}

final authApiClientProvider = Provider<AuthApiClient>((ref) {
  return AuthApiClient(ref.watch(dioProvider));
});
