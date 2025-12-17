import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/data/auth/auth_repository.dart';
import 'package:holyverso/data/auth/models/auth_payload.dart';
import 'package:holyverso/data/auth/models/user_settings.dart';
import 'package:holyverso/presentation/state/auth/auth_state.dart';
import 'package:holyverso/presentation/state/verse/verse_controller.dart';

class AuthController extends Notifier<AuthState> {
  late final AuthRepository _repository;
  static const _l10n = AppLocalizations(Locale('es'));

  @override
  AuthState build() {
    _repository = ref.read(authRepositoryProvider);
    // Automatically restore session on initialization
    _autoRestoreSession();
    return const AuthState(isLoading: true);
  }

  void _autoRestoreSession() {
    Future.microtask(() async {
      try {
        final session = await _repository.restoreSession();
        if (session == null) {
          state = const AuthState();
          return;
        }
        _setAuthenticated(session);
      } catch (error) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: _mapError(error),
        );
      }
    });
  }

  Future<void> restoreSession() async {
    state = state.copyWith(
      isLoading: true,
      isUpdatingSettings: false,
      clearError: true,
    );
    try {
      final session = await _repository.restoreSession();
      if (session == null) {
        state = const AuthState();
        return;
      }
      _setAuthenticated(session);
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: _mapError(error));
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(
      isLoading: true,
      isUpdatingSettings: false,
      clearError: true,
    );
    try {
      final payload = await _repository.login(email: email, password: password);
      _setAuthenticated(payload);
      return true;
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: _mapError(error));
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
    );
    try {
      final payload = await _repository.register(
        name: name,
        email: email,
        password: password,
      );
      _setAuthenticated(payload);
      return true;
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: _mapError(error));
      return false;
    }
  }

  Future<bool> sendForgotPassword(String email) async {
    state = state.copyWith(
      isLoading: true,
      isUpdatingSettings: false,
      clearError: true,
    );
    try {
      await _repository.forgotPassword(email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: _mapError(error));
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
    );
    try {
      await _repository.resetPassword(token: token, newPassword: newPassword);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: _mapError(error));
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState();
  }

  Future<bool> updatePreferredVersion(int versionId) async {
    state = state.copyWith(isUpdatingSettings: true, clearError: true);
    try {
      final updatedSettings = await _repository.updatePreferredVersion(
        versionId,
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
      );
      return false;
    }
  }

  Future<bool> updateWidgetFontSize(WidgetFontSize fontSize) async {
    state = state.copyWith(isUpdatingSettings: true, clearError: true);
    try {
      final updatedSettings = await _repository.updateWidgetFontSize(
        fontSize.toApiString(),
      );
      state = state.copyWith(
        settings: updatedSettings,
        isUpdatingSettings: false,
      );

      // Recargar el verso para actualizar el widget con el nuevo tamaño
      ref.read(verseControllerProvider.notifier).loadVerse(forceRefresh: true);

      return true;
    } catch (error) {
      state = state.copyWith(
        isUpdatingSettings: false,
        errorMessage: _mapError(error),
      );
      return false;
    }
  }

  void _setAuthenticated(AuthPayload payload) {
    state = AuthState(
      user: payload.user,
      settings: payload.settings,
      isLoading: false,
      isUpdatingSettings: false,
      errorMessage: null,
    );
  }

  String _mapError(Object error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;

      // El backend devuelve errores en data['error']['message']
      String? responseMessage;
      if (data is Map) {
        if (data['error'] is Map && data['error']['message'] is String) {
          responseMessage = data['error']['message'] as String;
        } else if (data['message'] is String) {
          responseMessage = data['message'] as String;
        }
      }

      // Si es un 401 con mensaje de credenciales, usar mensaje específico
      if (statusCode == 401 && responseMessage != null) {
        if (responseMessage.toLowerCase().contains('invalid') &&
            (responseMessage.toLowerCase().contains('email') ||
                responseMessage.toLowerCase().contains('password'))) {
          return _l10n.authInvalidCredentials;
        }
      }

      return responseMessage ?? error.message ?? _l10n.authRequestFailed;
    }

    return _l10n.authUnexpectedError;
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
