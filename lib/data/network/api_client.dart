import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holy_mobile/core/config/app_config.dart';
import 'package:holy_mobile/data/auth/token_storage.dart';

final dioProvider = Provider<Dio>((ref) {
  final configAsync = ref.watch(appConfigProvider);
  final config = configAsync.when(
    data: (config) => config,
    loading: () => throw StateError('App configuration is loading'),
    error: (err, stack) => throw StateError('Failed to load app config: $err'),
  );
  final tokenService = ref.watch(authTokenServiceProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: config.baseApiUrl,
      connectTimeout: config.requestTimeout,
      receiveTimeout: config.requestTimeout,
      sendTimeout: config.requestTimeout,
      contentType: 'application/json',
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenService.readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: false,
      ),
    );
  }

  return dio;
});
