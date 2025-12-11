import 'package:flutter/material.dart';
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

  /// In the future this could pull from env files, remote config, or platform
  /// channels. For now we return a static configuration.
  static Future<AppConfig> load() async {
    const l10n = AppLocalizations(Locale('es'));
    return AppConfig(
      baseApiUrl: 'https://api.ejemplo.com',
      requestTimeout: Duration(seconds: 15),
      genericErrorMessage: l10n.genericError,
      networkErrorMessage: l10n.networkError,
    );
  }
}

final appConfigProvider = FutureProvider<AppConfig>((ref) async {
  return AppConfig.load();
});
