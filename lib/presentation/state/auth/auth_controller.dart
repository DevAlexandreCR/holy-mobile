import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holy_mobile/core/l10n/app_localizations.dart';
import 'package:holy_mobile/data/auth/auth_repository.dart';
import 'package:holy_mobile/data/auth/models/auth_payload.dart';
import 'package:holy_mobile/presentation/state/auth/auth_state.dart';

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
      final data = error.response?.data;
      final responseMessage = data is Map && data['message'] is String
          ? data['message'] as String
          : null;
      return responseMessage ?? error.message ?? _l10n.authRequestFailed;
    }

    return _l10n.authUnexpectedError;
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
