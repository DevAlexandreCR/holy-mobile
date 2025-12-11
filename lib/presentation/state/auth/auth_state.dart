import 'package:holy_mobile/data/auth/models/user.dart';
import 'package:holy_mobile/data/auth/models/user_settings.dart';

class AuthState {
  const AuthState({
    this.user,
    this.settings,
    this.isLoading = false,
    this.isUpdatingSettings = false,
    this.errorMessage,
  });

  final User? user;
  final UserSettings? settings;
  final bool isLoading;
  final bool isUpdatingSettings;
  final String? errorMessage;

  bool get isAuthenticated => user != null;
  int? get preferredVersionId => settings?.preferredVersionId;

  AuthState copyWith({
    User? user,
    UserSettings? settings,
    bool? isLoading,
    bool? isUpdatingSettings,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      isUpdatingSettings: isUpdatingSettings ?? this.isUpdatingSettings,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
