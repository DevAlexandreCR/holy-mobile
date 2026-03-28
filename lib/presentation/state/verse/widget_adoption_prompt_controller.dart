import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/core/services/app_runtime_storage.dart';
import 'package:holyverso/data/widget/models/widget_install_status.dart';
import 'package:holyverso/data/widget/widget_verse_storage.dart';
import 'package:holyverso/presentation/state/auth/auth_controller.dart';
import 'package:holyverso/presentation/state/verse/widget_adoption_prompt_state.dart';

class WidgetAdoptionPromptController
    extends Notifier<WidgetAdoptionPromptState> {
  static const _dismissDuration = Duration(days: 7);

  late final WidgetVerseStorage _widgetStorage;
  late final AppRuntimeStorage _runtimeStorage;

  @override
  WidgetAdoptionPromptState build() {
    _widgetStorage = ref.read(widgetVerseStorageProvider);
    _runtimeStorage = ref.read(appRuntimeStorageProvider);

    ref.listen(authControllerProvider, (previous, next) {
      final wasAuthenticated = previous?.isAuthenticated == true;
      if (wasAuthenticated && !next.isAuthenticated) {
        state = const WidgetAdoptionPromptState();
        return;
      }

      if (!wasAuthenticated && next.isAuthenticated) {
        unawaited(refreshStatus());
      }
    });

    return const WidgetAdoptionPromptState();
  }

  Future<void> refreshStatus() async {
    final authState = ref.read(authControllerProvider);
    if (!authState.isAuthenticated) {
      state = const WidgetAdoptionPromptState(hasResolved: true);
      return;
    }

    state = state.copyWith(isChecking: true);

    try {
      final installStatus = await _widgetStorage.readInstallStatus();
      final dismissedUntil = await _runtimeStorage
          .readWidgetPromptDismissedUntil();
      state = WidgetAdoptionPromptState(
        isChecking: false,
        shouldShowPrompt: _shouldShowPrompt(
          installStatus: installStatus,
          dismissedUntil: dismissedUntil,
        ),
        installStatus: installStatus,
        dismissedUntil: dismissedUntil,
        hasResolved: true,
      );
    } catch (_) {
      state = state.copyWith(
        isChecking: false,
        shouldShowPrompt: false,
        hasResolved: true,
        clearInstallStatus: true,
      );
    }
  }

  Future<void> dismissPrompt() async {
    final dismissedUntil = DateTime.now().add(_dismissDuration);
    await _runtimeStorage.saveWidgetPromptDismissedUntil(dismissedUntil);
    state = state.copyWith(
      shouldShowPrompt: false,
      dismissedUntil: dismissedUntil,
      hasResolved: true,
    );
  }

  bool _shouldShowPrompt({
    required WidgetInstallStatus installStatus,
    required DateTime? dismissedUntil,
  }) {
    if (installStatus.isInstalled) {
      return false;
    }

    if (dismissedUntil == null) {
      return true;
    }

    return DateTime.now().isAfter(dismissedUntil);
  }
}

final widgetAdoptionPromptControllerProvider =
    NotifierProvider<WidgetAdoptionPromptController, WidgetAdoptionPromptState>(
      WidgetAdoptionPromptController.new,
    );
