import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:holy_mobile/core/config/app_config.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({
    super.key,
    this.message = 'Cargando configuración...',
    this.errorDetails,
  });

  final String message;
  final String? errorDetails;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isError = errorDetails != null;

    ref.listen<AsyncValue<AppConfig>>(appConfigProvider, (previous, next) {
      next.whenOrNull(data: (_) => context.go('/login'));
    });

    return Scaffold(
      backgroundColor: colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.onPrimary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_stories_rounded,
                color: colorScheme.onPrimary,
                size: 42,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Bible Widget',
              style: textTheme.headlineMedium?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onPrimary.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 18),
            if (!isError) const CircularProgressIndicator(color: Colors.white),
            if (isError) ...[
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                errorDetails ?? '',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimary.withOpacity(0.9),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
