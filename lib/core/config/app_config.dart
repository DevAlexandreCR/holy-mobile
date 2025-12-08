import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    return const AppConfig(
      baseApiUrl: 'https://api.ejemplo.com',
      requestTimeout: Duration(seconds: 15),
      genericErrorMessage: 'Ocurrió un error inesperado. Inténtalo nuevamente.',
      networkErrorMessage: 'Verifica tu conexión a internet.',
    );
  }
}

final appConfigProvider = FutureProvider<AppConfig>((ref) async {
  return AppConfig.load();
});
