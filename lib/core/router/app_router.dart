import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:holy_mobile/core/config/app_config.dart';
import 'package:holy_mobile/presentation/state/auth/auth_controller.dart';
import 'package:holy_mobile/presentation/screens/auth/forgot_password_screen.dart';
import 'package:holy_mobile/presentation/screens/auth/login_screen.dart';
import 'package:holy_mobile/presentation/screens/auth/register_screen.dart';
import 'package:holy_mobile/presentation/screens/settings/settings_screen.dart';
import 'package:holy_mobile/presentation/screens/splash/splash_screen.dart';
import 'package:holy_mobile/presentation/screens/verse/verse_of_the_day_screen.dart';

final authBootstrapProvider = FutureProvider<void>((ref) async {
  await ref.watch(appConfigProvider.future);
  await ref.read(authControllerProvider.notifier).restoreSession();
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final configState = ref.watch(appConfigProvider);
  final authState = ref.watch(authControllerProvider);
  final authBootstrap = ref.watch(authBootstrapProvider);

  final splashMessage = _resolveSplashMessage(configState, authBootstrap);
  final splashError = _resolveSplashError(configState, authBootstrap);

  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => SplashScreen(
          message: splashMessage,
          errorDetails: splashError,
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
      final bootstrapping = configState.isLoading || authBootstrap.isLoading;
      final hasErrors = configState.hasError || authBootstrap.hasError;
      final atSplash = state.matchedLocation == '/splash';
      final atAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password';
      final isProtectedRoute = state.matchedLocation == '/verse' ||
          state.matchedLocation == '/settings';

      if (hasErrors) {
        return atSplash ? null : '/splash';
      }

      if (bootstrapping) {
        return atSplash ? null : '/splash';
      }

      if (authState.isAuthenticated && (atSplash || atAuthRoute)) {
        return '/verse';
      }

      if (!authState.isAuthenticated && (atSplash || isProtectedRoute)) {
        return '/login';
      }

      return null;
    },
  );
});

String _resolveSplashMessage(
  AsyncValue<AppConfig> configState,
  AsyncValue<void> authBootstrap,
) {
  if (configState.isLoading || authBootstrap.isLoading) {
    return 'Preparando tu experiencia...';
  }
  if (configState.hasError) {
    return 'Error al cargar configuración';
  }
  if (authBootstrap.hasError) {
    return 'No se pudo validar tu sesión';
  }
  return 'Listo para comenzar';
}

String? _resolveSplashError(
  AsyncValue<AppConfig> configState,
  AsyncValue<void> authBootstrap,
) {
  if (configState.hasError) {
    return configState.error.toString();
  }
  if (authBootstrap.hasError) {
    return authBootstrap.error.toString();
  }
  return null;
}
