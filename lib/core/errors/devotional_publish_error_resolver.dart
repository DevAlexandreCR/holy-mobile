import 'package:dio/dio.dart';
import 'package:holyverso/core/errors/app_error_mapper.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';

String resolveDevotionalPublishErrorMessage(
  Object error, {
  required AppLocalizations l10n,
  required String fallbackMessage,
  Map<String, String> businessCodeMessages = const {},
}) {
  final backendCode = AppErrorMapper.backendCode(error);
  if (backendCode == 'DEVOTIONAL_QUALITY_GATE_FAILED' &&
      error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['error'] is Map) {
      final message = data['error']['message']?.toString().trim();
      if (message != null && message.isNotEmpty) {
        return message;
      }
    }
  }

  return AppErrorMapper.toMessage(
    error,
    l10n: l10n,
    fallbackMessage: fallbackMessage,
    businessCodeMessages: businessCodeMessages,
  );
}
