import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/core/config/app_config.dart';
import 'package:holyverso/data/auth/token_storage.dart';
import 'package:holyverso/presentation/state/auth/auth_controller.dart';

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
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
      onError: (error, handler) async {
        final hasAuthHeader =
            error.requestOptions.headers['Authorization'] != null;
        final deferAuthStateHandling =
            error.requestOptions.extra['deferAuthStateHandling'] == true;
        final statusCode = error.response?.statusCode;

        if (hasAuthHeader &&
            !deferAuthStateHandling &&
            (statusCode == 401 || statusCode == 403)) {
          final authNotifier = ref.read(authControllerProvider.notifier);
          await authNotifier.markSessionExpired();
        }
        handler.next(error);
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
