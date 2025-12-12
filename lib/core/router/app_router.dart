import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:holy_mobile/core/l10n/app_localizations.dart';
import 'package:holy_mobile/presentation/state/auth/auth_controller.dart';
import 'package:holy_mobile/presentation/screens/auth/forgot_password_screen.dart';
import 'package:holy_mobile/presentation/screens/auth/login_screen.dart';
import 'package:holy_mobile/presentation/screens/auth/register_screen.dart';
import 'package:holy_mobile/presentation/screens/settings/settings_screen.dart';
import 'package:holy_mobile/presentation/screens/splash/splash_screen.dart';
import 'package:holy_mobile/presentation/screens/verse/verse_of_the_day_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(
    authControllerProvider.select(
      (state) => (
        isLoading: state.isLoading,
        isAuthenticated: state.isAuthenticated,
        errorMessage: state.errorMessage,
      ),
    ),
  );

  const baseL10n = AppLocalizations(Locale('es'));

  final splashMessage = authState.isLoading
      ? baseL10n.splashPreparing
      : baseL10n.splashReady;
  final splashError = authState.errorMessage;

  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) =>
            SplashScreen(message: splashMessage, errorDetails: splashError),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
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
      final bootstrapping = authState.isLoading;
      final atSplash = state.matchedLocation == '/splash';
      final atAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password';
      final isProtectedRoute =
          state.matchedLocation == '/verse' ||
          state.matchedLocation == '/settings';

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
