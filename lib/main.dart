import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/core/router/app_router.dart';
import 'package:holyverso/core/theme/app_theme.dart';
import 'package:holyverso/data/auth/token_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file before app starts
  final envFile = kReleaseMode ? '.env.production' : '.env.development';
  await dotenv.load(fileName: envFile);

  // Inicializar configuración nativa con la API_URL del .env
  final apiUrl = dotenv.get('API_URL', fallback: 'https://api.holyverso.com');
  final authTokenService = AuthTokenService();
  await authTokenService.initializeNativeConfig(apiUrl);

  runApp(const ProviderScope(child: HolyVersoApp()));
}

class HolyVersoApp extends ConsumerWidget {
  const HolyVersoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      locale: const Locale('es'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
