import 'dart:io';

import 'package:dio/dio.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';

class AppErrorMapper {
  const AppErrorMapper._();

  static String toMessage(
    Object error, {
    required AppLocalizations l10n,
    String? fallbackMessage,
    Map<String, String>? businessCodeMessages,
    bool allowInvalidCredentials = false,
  }) {
    final fallback = fallbackMessage ?? l10n.genericError;

    if (error is SocketException) {
      return l10n.connectionUnavailableMessage;
    }

    if (error is DioException) {
      final code = _errorCode(error);
      final statusCode = error.response?.statusCode;

      if (_isNetworkError(error)) {
        return l10n.connectionUnavailableMessage;
      }

      if (allowInvalidCredentials &&
          statusCode == 401 &&
          _looksLikeInvalidCredentials(error)) {
        return l10n.authInvalidCredentials;
      }

      if (code != null && businessCodeMessages != null) {
        final mappedMessage = businessCodeMessages[code];
        if (mappedMessage != null && mappedMessage.isNotEmpty) {
          return mappedMessage;
        }
      }

      if (statusCode == 401) {
        return l10n.sessionExpiredMessage;
      }

      if (statusCode != null && statusCode >= 500) {
        return fallback;
      }
    }

    return fallback;
  }

  static bool isUnauthorized(Object error) {
    if (error is! DioException) return false;
    final statusCode = error.response?.statusCode;
    return statusCode == 401;
  }

  static bool isRecoverableSessionError(Object error) {
    if (error is SocketException) return true;
    if (error is! DioException) return false;
    if (_isNetworkError(error)) return true;

    final statusCode = error.response?.statusCode;
    return statusCode != null && statusCode >= 500;
  }

  static String? backendCode(Object error) {
    if (error is! DioException) return null;
    return _errorCode(error);
  }

  static bool _isNetworkError(DioException error) {
    return error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.unknown ||
        error.response == null;
  }

  static String? _errorCode(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['error'] is Map) {
      return data['error']['code']?.toString();
    }
    return null;
  }

  static bool _looksLikeInvalidCredentials(DioException error) {
    final data = error.response?.data;
    final backendMessage = data is Map && data['error'] is Map
        ? data['error']['message']?.toString()
        : data is Map
        ? data['message']?.toString()
        : null;

    if (backendMessage == null) return false;
    final normalized = backendMessage.toLowerCase();
    return normalized.contains('invalid') &&
        (normalized.contains('email') || normalized.contains('password'));
  }
}
