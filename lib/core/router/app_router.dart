import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/presentation/state/auth/auth_controller.dart';
import 'package:holyverso/presentation/state/auth/auth_state.dart';
import 'package:holyverso/presentation/state/roles/role_provider.dart';
import 'package:holyverso/presentation/screens/auth/forgot_password_screen.dart';
import 'package:holyverso/presentation/screens/auth/login_screen.dart';
import 'package:holyverso/presentation/screens/auth/register_screen.dart';
import 'package:holyverso/presentation/screens/auth/reset_password_screen.dart';
import 'package:holyverso/presentation/screens/devotionals/devotional_editor_screen.dart';
import 'package:holyverso/presentation/screens/devotionals/devotional_detail_screen.dart';
import 'package:holyverso/presentation/screens/devotionals/devotional_preview_screen.dart';
import 'package:holyverso/presentation/screens/devotionals/devotionals_list_screen.dart';
import 'package:holyverso/presentation/screens/creator_profiles/creator_profile_edit_screen.dart';
import 'package:holyverso/presentation/screens/creator_profiles/creator_profile_screen.dart';
import 'package:holyverso/presentation/screens/search/search_screen.dart';
import 'package:holyverso/presentation/screens/settings/settings_screen.dart';
import 'package:holyverso/presentation/screens/splash/splash_screen.dart';
import 'package:holyverso/presentation/screens/users/users_list_screen.dart';
import 'package:holyverso/presentation/screens/verse/saved_verses_screen.dart';
import 'package:holyverso/presentation/screens/verse/chapter_reader_screen.dart';
import 'package:holyverso/presentation/screens/verse/verse_of_the_day_screen.dart';
import 'package:holyverso/presentation/widgets/navigation/bottom_navigation_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(
    authControllerProvider.select(
      (state) => (
        sessionStatus: state.sessionStatus,
        isBootstrapping: state.isBootstrapping,
        canAccessProtectedRoutes: state.canAccessProtectedRoutes,
        errorMessage: state.errorMessage,
        infoMessage: state.infoMessage,
      ),
    ),
  );

  const baseL10n = AppLocalizations(Locale('es'));

  final splashMessage = authState.isBootstrapping
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
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(
          successMessage: state.extra is String
              ? state.extra as String
              : state.uri.queryParameters['message'],
        ),
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
        path: '/reset-password',
        builder: (context, state) => ResetPasswordScreen(
          initialToken: state.uri.queryParameters['token'],
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            BottomNavigationShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            initialLocation: '/home',
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const VerseOfTheDayScreen(),
              ),
              GoRoute(path: '/verse', redirect: (context, state) => '/home'),
              GoRoute(
                path: '/verse/chapter',
                builder: (context, state) {
                  final args = state.extra is ChapterReaderArgs
                      ? state.extra as ChapterReaderArgs
                      : const ChapterReaderArgs.today();
                  return ChapterReaderScreen(args: args);
                },
              ),
              GoRoute(
                path: '/verse/saved',
                redirect: (context, state) => '/saved',
              ),
            ],
          ),
          StatefulShellBranch(
            initialLocation: '/search',
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, state) => const SearchScreen(),
              ),
              GoRoute(
                path: '/verse/search',
                redirect: (context, state) => '/search',
              ),
            ],
          ),
          StatefulShellBranch(
            initialLocation: '/saved',
            routes: [
              GoRoute(
                path: '/saved',
                builder: (context, state) => const SavedVersesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            initialLocation: '/profile',
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) {
                  final userId = ref.read(authControllerProvider).user?.id;
                  if (userId == null) {
                    return const SizedBox.shrink();
                  }
                  return CreatorProfileScreen(creatorId: userId);
                },
              ),
              GoRoute(
                path: '/profile/edit',
                builder: (context, state) => const CreatorProfileEditScreen(),
              ),
              GoRoute(
                path: '/profile/settings',
                builder: (context, state) =>
                    const SettingsScreen(showBackButton: true),
              ),
              GoRoute(
                path: '/settings',
                redirect: (context, state) => '/profile/settings',
              ),
            ],
          ),
          StatefulShellBranch(
            initialLocation: '/users',
            routes: [
              GoRoute(
                path: '/users',
                builder: (context, state) => const UsersListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            initialLocation: '/devotionals',
            routes: [
              GoRoute(
                path: '/devotionals',
                builder: (context, state) => const DevotionalsListScreen(),
              ),
              GoRoute(
                path: '/devotionals/create',
                builder: (context, state) => const DevotionalEditorScreen(),
              ),
              GoRoute(
                path: '/devotionals/preview',
                builder: (context, state) {
                  final payload = state.extra as DevotionalPreviewPayload;
                  return DevotionalPreviewScreen(payload: payload);
                },
              ),
              GoRoute(
                path: '/devotionals/:id/edit',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return DevotionalEditorScreen(devotionalId: id);
                },
              ),
              GoRoute(
                path: '/devotionals/:id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return DevotionalDetailScreen(devotionalId: id);
                },
              ),
              GoRoute(
                path: '/users/me/edit-profile',
                redirect: (context, state) => '/profile/edit',
              ),
              GoRoute(
                path: '/users/:id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return CreatorProfileScreen(creatorId: id);
                },
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final bootstrapping = authState.isBootstrapping;
      final atSplash = state.matchedLocation == '/splash';
      final atResetPassword = state.matchedLocation == '/reset-password';
      final atAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password';
      final location = state.matchedLocation;
      final canManageUsers = ref.watch(canManageUsersProvider);
      final isProtectedRoute =
          location == '/saved' ||
          location == '/profile' ||
          location.startsWith('/profile/') ||
          location == '/settings' ||
          location == '/users' ||
          location == '/users/me/edit-profile' ||
          (location.startsWith('/users/') && location != '/users') ||
          location == '/devotionals' ||
          location.startsWith('/devotionals') ||
          location == '/verse/saved';

      if (bootstrapping && !atResetPassword && !atAuthRoute) {
        return atSplash ? null : '/splash';
      }

      if (atSplash) {
        if (authState.sessionStatus == AuthSessionStatus.expired) {
          final encodedMessage = Uri.encodeComponent(
            baseL10n.sessionExpiredMessage,
          );
          return '/login?message=$encodedMessage';
        }
        return '/home';
      }

      if (authState.canAccessProtectedRoutes && atAuthRoute) {
        return '/home';
      }

      if (!authState.canAccessProtectedRoutes && isProtectedRoute) {
        if (atSplash) {
          return '/login';
        }

        final message = authState.sessionStatus == AuthSessionStatus.expired
            ? baseL10n.sessionExpiredMessage
            : baseL10n.loginRequiredMessage;
        final encodedMessage = Uri.encodeComponent(message);
        return authState.infoMessage == null || authState.infoMessage!.isEmpty
            ? '/login?message=$encodedMessage'
            : '/login';
      }

      if (authState.canAccessProtectedRoutes &&
          location == '/users' &&
          !canManageUsers) {
        return '/profile';
      }

      return null;
    },
  );
});
