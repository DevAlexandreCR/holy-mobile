import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holy_mobile/core/l10n/app_localizations.dart';

class AppConfig {
  final String baseApiUrl;
  final Duration requestTimeout;
  final String genericErrorMessage;
  final String networkErrorMessage;

  const AppConfig({
    required this.baseApiUrl,
    required this.requestTimeout,
    required this.genericErrorMessage,
    required this.networkErrorMessage,
  });

  /// Load configuration from .env files (dotenv must be loaded first in main)
  static AppConfig load() {
    const l10n = AppLocalizations(Locale('es'));

    return AppConfig(
      baseApiUrl: dotenv.get('API_URL', fallback: 'http://localhost:3000'),
      requestTimeout: Duration(
        seconds: int.parse(dotenv.get('REQUEST_TIMEOUT', fallback: '15')),
      ),
      genericErrorMessage: l10n.genericError,
      networkErrorMessage: l10n.networkError,
    );
  }
}

final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.load();
});
