import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/core/services/app_runtime_storage.dart';
import 'package:holyverso/presentation/state/auth/auth_controller.dart';

/// Resolves whether the one-time "¿Cuándo es tu momento con Dios?" prompt
/// should be shown: only for authenticated users who have never seen it.
final dailyReminderPromptProvider = FutureProvider<bool>((ref) async {
  final isAuthenticated = ref.read(authControllerProvider).isAuthenticated;
  if (!isAuthenticated) {
    return false;
  }

  final storage = ref.read(appRuntimeStorageProvider);
  final alreadySeen = await storage.hasSeenDailyReminderPrompt();
  return !alreadySeen;
});
