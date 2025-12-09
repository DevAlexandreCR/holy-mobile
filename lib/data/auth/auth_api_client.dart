import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holy_mobile/data/auth/models/auth_payload.dart';
import 'package:holy_mobile/data/network/api_client.dart';

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
      data: {
        'name': name,
        'email': email,
        'password': password,
      },
    );

    return AuthPayload.fromMap(response.data as Map<String, dynamic>);
  }

  Future<AuthPayload> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    return AuthPayload.fromMap(response.data as Map<String, dynamic>);
  }

  Future<void> forgotPassword({required String email}) {
    return _dio.post(
      '/auth/forgot-password',
      data: {'email': email},
    );
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) {
    return _dio.post(
      '/auth/reset-password',
      data: {
        'token': token,
        'password': newPassword,
      },
    );
  }

  Future<AuthPayload> me() async {
    final response = await _dio.get('/auth/me');
    return AuthPayload.fromMap(response.data as Map<String, dynamic>);
  }
}

final authApiClientProvider = Provider<AuthApiClient>((ref) {
  return AuthApiClient(ref.watch(dioProvider));
});
