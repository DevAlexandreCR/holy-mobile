import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:holy_mobile/core/config/app_config.dart';
import 'package:holy_mobile/presentation/screens/auth/forgot_password_screen.dart';
import 'package:holy_mobile/presentation/screens/auth/login_screen.dart';
import 'package:holy_mobile/presentation/screens/auth/register_screen.dart';
import 'package:holy_mobile/presentation/screens/settings/settings_screen.dart';
import 'package:holy_mobile/presentation/screens/splash/splash_screen.dart';
import 'package:holy_mobile/presentation/screens/verse/verse_of_the_day_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final configState = ref.watch(appConfigProvider);

  return configState.when(
    data: (config) => _buildRouter(config: config),
    loading: () => _buildRouter(),
    error: (error, _) => _buildRouter(
      splashMessage: 'Error al cargar configuración',
      errorDetails: error.toString(),
    ),
  );
});

GoRouter _buildRouter({
  AppConfig? config,
  String splashMessage = 'Cargando configuración...',
  String? errorDetails,
}) {
  final isReady = config != null;

  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => SplashScreen(
          message: splashMessage,
          errorDetails: errorDetails,
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verse',
        builder: (context, state) => const VerseOfTheDayScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    redirect: (context, state) {
      final atSplash = state.matchedLocation == '/splash';

      if (!isReady && !atSplash) {
        return '/splash';
      }

      if (isReady && atSplash) {
        return '/login';
      }

      return null;
    },
  );
}
