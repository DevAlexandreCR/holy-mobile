import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:holyverso/core/errors/app_error_mapper.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/data/auth/auth_repository.dart';
import 'package:holyverso/data/auth/models/auth_payload.dart';
import 'package:holyverso/data/auth/models/auth_restore_result.dart';
import 'package:holyverso/data/auth/models/user_settings.dart';
import 'package:holyverso/presentation/state/auth/auth_state.dart';
import 'package:holyverso/presentation/state/verse/verse_controller.dart';

class AuthController extends Notifier<AuthState> {
  late final AuthRepository _repository;
  static const _l10n = AppLocalizations(Locale('es'));

  @override
  AuthState build() {
    _repository = ref.read(authRepositoryProvider);
    _autoRestoreSession();
    return const AuthState(
      sessionStatus: AuthSessionStatus.bootstrapping,
      isLoading: true,
    );
  }

  void _autoRestoreSession() {
    Future.microtask(() async {
      try {
        final result = await _repository.restoreSession();
        _applyRestoreResult(result);
      } catch (error) {
        state = const AuthState(
          sessionStatus: AuthSessionStatus.guest,
          isLoading: false,
        );
      }
    });
  }

  Future<void> restoreSession() async {
    state = state.copyWith(
      isLoading: true,
      isUpdatingSettings: false,
      clearError: true,
      clearInfo: true,
    );
    try {
      final result = await _repository.restoreSession();
      _applyRestoreResult(result);
    } catch (error) {
      state = const AuthState(
        sessionStatus: AuthSessionStatus.guest,
        isLoading: false,
      );
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(
      isLoading: true,
      isUpdatingSettings: false,
      clearError: true,
      clearInfo: true,
    );
    try {
      final payload = await _repository.login(email: email, password: password);
      _setAuthenticated(
        payload,
        sessionStatus: AuthSessionStatus.authenticated,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _mapError(error),
        clearInfo: true,
      );
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(
      isLoading: true,
      isUpdatingSettings: false,
      clearError: true,
      clearInfo: true,
    );
    try {
      final payload = await _repository.register(
        name: name,
        email: email,
        password: password,
      );
      _setAuthenticated(
        payload,
        sessionStatus: AuthSessionStatus.authenticated,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _mapError(error),
        clearInfo: true,
      );
      return false;
    }
  }

  Future<bool> sendForgotPassword(String email) async {
    state = state.copyWith(
      isLoading: true,
      isUpdatingSettings: false,
      clearError: true,
      clearInfo: true,
    );
    try {
      await _repository.forgotPassword(email);
      state = state.copyWith(
        isLoading: false,
        infoMessage: _l10n.instructionsSent,
        clearError: true,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _mapError(error),
        clearInfo: true,
      );
      return false;
    }
  }

  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    state = state.copyWith(
      isLoading: true,
      isUpdatingSettings: false,
      clearError: true,
      clearInfo: true,
    );
    try {
      await _repository.resetPassword(token: token, newPassword: newPassword);
      state = state.copyWith(isLoading: false, clearInfo: true);
      return true;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _mapError(error),
        clearInfo: true,
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState(sessionStatus: AuthSessionStatus.guest);
  }

  Future<bool> deleteAccount() async {
    state = state.copyWith(
      isLoading: true,
      isUpdatingSettings: false,
      clearError: true,
      clearInfo: true,
    );
    try {
      await _repository.deleteAccount();
      state = AuthState(infoMessage: _l10n.deleteAccountSuccess);
      return true;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _mapError(error),
        clearInfo: true,
      );
      return false;
    }
  }

  Future<bool> updatePreferredVersion(int versionId) async {
    state = state.copyWith(
      isUpdatingSettings: true,
      clearError: true,
      clearInfo: true,
    );
    try {
      final updatedSettings = await _repository.updatePreferredVersion(
        versionId,
      );
      await _repository.persistSessionSnapshot(
        user: state.user!,
        settings: updatedSettings,
      );
      state = state.copyWith(
        settings: updatedSettings,
        isUpdatingSettings: false,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        isUpdatingSettings: false,
        errorMessage: _mapError(error),
        clearInfo: true,
      );
      return false;
    }
  }

  Future<bool> updateWidgetFontSize(WidgetFontSize fontSize) async {
    state = state.copyWith(
      isUpdatingSettings: true,
      clearError: true,
      clearInfo: true,
    );
    try {
      final updatedSettings = await _repository.updateWidgetFontSize(
        fontSize.toApiString(),
      );
      await _repository.persistSessionSnapshot(
        user: state.user!,
        settings: updatedSettings,
      );
      state = state.copyWith(
        settings: updatedSettings,
        isUpdatingSettings: false,
      );

      // Reload the verse so the widget picks up the new font size
      ref.read(verseControllerProvider.notifier).loadVerse(forceRefresh: true);

      return true;
    } catch (error) {
      state = state.copyWith(
        isUpdatingSettings: false,
        errorMessage: _mapError(error),
        clearInfo: true,
      );
      return false;
    }
  }

  void _setAuthenticated(
    AuthPayload payload, {
    required AuthSessionStatus sessionStatus,
    String? infoMessage,
    bool isServerValidated = true,
  }) {
    state = AuthState(
      user: payload.user,
      settings: payload.settings,
      sessionStatus: sessionStatus,
      isLoading: false,
      isUpdatingSettings: false,
      errorMessage: null,
      infoMessage: infoMessage,
      hasStoredToken: true,
      isServerValidated: isServerValidated,
    );

    _autoUpdateTimezoneIfNeeded();
  }

  /// Detects the device timezone and sends it to the backend if it's missing
  Future<void> _autoUpdateTimezoneIfNeeded() async {
    try {
      // Skip if the user already has a timezone configured
      if (state.settings?.timezone != null &&
          state.settings!.timezone!.isNotEmpty) {
        debugPrint('[Auth] Timezone already set: ${state.settings!.timezone}');
        return;
      }

      // Fetch the device timezone in IANA format (e.g., 'America/Bogota')
      final String deviceTimezone = await FlutterTimezone.getLocalTimezone();

      debugPrint('[Auth] Auto-updating timezone to: $deviceTimezone');

      // Send it to the backend without blocking the UI
      final updatedSettings = await _repository.updateTimezone(deviceTimezone);
      await _repository.persistSessionSnapshot(
        user: state.user!,
        settings: updatedSettings,
      );

      state = state.copyWith(settings: updatedSettings);

      debugPrint('[Auth] Timezone updated successfully');
    } catch (error) {
      // Do not show an error to the user; this is a background task
      debugPrint('[Auth] Failed to auto-update timezone: $error');
    }
  }

  String _mapError(Object error) {
    return AppErrorMapper.toMessage(
      error,
      l10n: _l10n,
      fallbackMessage: _l10n.authRequestFailed,
      allowInvalidCredentials: true,
    );
  }

  void clearInfoMessage() {
    if (state.infoMessage == null) return;
    state = state.copyWith(clearInfo: true);
  }

  Future<void> markSessionExpired({String? message}) async {
    await _repository.clearSession();
    state = AuthState(
      sessionStatus: AuthSessionStatus.expired,
      isLoading: false,
      infoMessage: message ?? _l10n.sessionExpiredMessage,
    );
  }

  void _applyRestoreResult(AuthRestoreResult result) {
    switch (result.status) {
      case AuthRestoreStatus.missing:
        state = const AuthState(
          sessionStatus: AuthSessionStatus.guest,
          isLoading: false,
        );
        return;
      case AuthRestoreStatus.authenticated:
        _setAuthenticated(
          result.payload!,
          sessionStatus: AuthSessionStatus.authenticated,
          isServerValidated: true,
        );
        return;
      case AuthRestoreStatus.authenticatedStale:
        _setAuthenticated(
          result.payload!,
          sessionStatus: AuthSessionStatus.authenticatedStale,
          infoMessage: _l10n.showingLastAvailableSessionMessage,
          isServerValidated: false,
        );
        return;
      case AuthRestoreStatus.expired:
        state = AuthState(
          sessionStatus: AuthSessionStatus.expired,
          isLoading: false,
          infoMessage: _l10n.sessionExpiredMessage,
        );
        return;
    }
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
