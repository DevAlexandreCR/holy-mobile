import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/core/router/app_router.dart';
import 'package:holyverso/core/theme/app_theme.dart';
import 'package:holyverso/data/auth/token_storage.dart';
import 'package:holyverso/data/widget/widget_verse_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file before app starts
  final envFile = kReleaseMode ? '.env.production' : '.env.development';
  await dotenv.load(fileName: envFile);

  // Initialize native configuration with the API_URL from the .env file
  final apiUrl = dotenv.get('API_URL', fallback: 'https://api.holyverso.com');
  final authTokenService = AuthTokenService();
  await authTokenService.initializeNativeConfig(apiUrl);

  runApp(const ProviderScope(child: HolyVersoApp()));
}

class HolyVersoApp extends ConsumerStatefulWidget {
  const HolyVersoApp({super.key});

  @override
  ConsumerState<HolyVersoApp> createState() => _HolyVersoAppState();
}

class _HolyVersoAppState extends ConsumerState<HolyVersoApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Refresh the widget when the app returns to the foreground
    if (state == AppLifecycleState.resumed) {
      debugPrint('[AppLifecycle] App resumed, refreshing widgets...');
      ref.read(widgetVerseStorageProvider).refreshWidgets();
    }
  }

  @override
  Widget build(BuildContext context) {
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
