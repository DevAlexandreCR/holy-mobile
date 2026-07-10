import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holyverso/core/errors/app_error_mapper.dart';

void main() {
  group('AppErrorMapper.isDefinitiveRejection', () {
    test('401 is definitive', () {
      expect(
        AppErrorMapper.isDefinitiveRejection(_statusError(401)),
        isTrue,
      );
    });

    test('403 is definitive', () {
      expect(
        AppErrorMapper.isDefinitiveRejection(_statusError(403)),
        isTrue,
      );
    });

    test('account-gone USER_NOT_FOUND is definitive', () {
      expect(
        AppErrorMapper.isDefinitiveRejection(
          _statusError(404, code: 'USER_NOT_FOUND'),
        ),
        isTrue,
      );
    });

    test('account-gone ACCOUNT_DELETED is definitive', () {
      expect(
        AppErrorMapper.isDefinitiveRejection(
          _statusError(404, code: 'ACCOUNT_DELETED'),
        ),
        isTrue,
      );
    });

    test('network error is not definitive', () {
      expect(
        AppErrorMapper.isDefinitiveRejection(_networkError()),
        isFalse,
      );
    });

    test('timeout is not definitive', () {
      expect(
        AppErrorMapper.isDefinitiveRejection(_timeoutError()),
        isFalse,
      );
    });

    test('5xx is not definitive', () {
      expect(
        AppErrorMapper.isDefinitiveRejection(_statusError(500)),
        isFalse,
      );
    });

    test('other codes without account-gone are not definitive', () {
      expect(
        AppErrorMapper.isDefinitiveRejection(_statusError(400)),
        isFalse,
      );
      expect(
        AppErrorMapper.isDefinitiveRejection(_statusError(422)),
        isFalse,
      );
      expect(
        AppErrorMapper.isDefinitiveRejection(
          _statusError(404, code: 'DEVOTIONAL_NOT_FOUND'),
        ),
        isFalse,
      );
    });

    test('non-DioException is not definitive', () {
      expect(
        AppErrorMapper.isDefinitiveRejection(const SocketException('down')),
        isFalse,
      );
      expect(
        AppErrorMapper.isDefinitiveRejection(Exception('boom')),
        isFalse,
      );
    });
  });

  group('AppErrorMapper.isRecoverableSessionError', () {
    test('network error is recoverable', () {
      expect(
        AppErrorMapper.isRecoverableSessionError(_networkError()),
        isTrue,
      );
    });

    test('timeout is recoverable', () {
      expect(
        AppErrorMapper.isRecoverableSessionError(_timeoutError()),
        isTrue,
      );
    });

    test('5xx is recoverable', () {
      expect(
        AppErrorMapper.isRecoverableSessionError(_statusError(500)),
        isTrue,
      );
    });

    test('SocketException is recoverable', () {
      expect(
        AppErrorMapper.isRecoverableSessionError(const SocketException('down')),
        isTrue,
      );
    });

    test('401/403 are not recoverable', () {
      expect(
        AppErrorMapper.isRecoverableSessionError(_statusError(401)),
        isFalse,
      );
      expect(
        AppErrorMapper.isRecoverableSessionError(_statusError(403)),
        isFalse,
      );
    });

    test('other 4xx codes are not recoverable', () {
      expect(
        AppErrorMapper.isRecoverableSessionError(_statusError(400)),
        isFalse,
      );
      expect(
        AppErrorMapper.isRecoverableSessionError(_statusError(422)),
        isFalse,
      );
    });
  });
}

DioException _statusError(int statusCode, {String? code}) {
  final requestOptions = RequestOptions(path: '/auth/me');
  return DioException(
    requestOptions: requestOptions,
    response: Response(
      requestOptions: requestOptions,
      statusCode: statusCode,
      data: code == null
          ? null
          : {
              'error': {'code': code, 'message': code},
            },
    ),
    type: DioExceptionType.badResponse,
  );
}

DioException _networkError() {
  final requestOptions = RequestOptions(path: '/auth/me');
  return DioException(
    requestOptions: requestOptions,
    type: DioExceptionType.connectionError,
  );
}

DioException _timeoutError() {
  final requestOptions = RequestOptions(path: '/auth/me');
  return DioException(
    requestOptions: requestOptions,
    type: DioExceptionType.connectionTimeout,
  );
}
