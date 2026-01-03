import 'package:holyverso/data/auth/models/user.dart';
import 'package:holyverso/data/auth/models/user_settings.dart';

class AuthState {
  const AuthState({
    this.user,
    this.settings,
    this.isLoading = false,
    this.isUpdatingSettings = false,
    this.errorMessage,
    this.infoMessage,
  });

  final User? user;
  final UserSettings? settings;
  final bool isLoading;
  final bool isUpdatingSettings;
  final String? errorMessage;
  final String? infoMessage;

  bool get isAuthenticated => user != null;
  int? get preferredVersionId => settings?.preferredVersionId;

  AuthState copyWith({
    User? user,
    UserSettings? settings,
    bool? isLoading,
    bool? isUpdatingSettings,
    String? errorMessage,
    String? infoMessage,
    bool clearError = false,
    bool clearInfo = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      isUpdatingSettings: isUpdatingSettings ?? this.isUpdatingSettings,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      infoMessage: clearInfo ? null : infoMessage ?? this.infoMessage,
    );
  }
}
