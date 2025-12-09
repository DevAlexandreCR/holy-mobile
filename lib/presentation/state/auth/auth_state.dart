import 'package:holy_mobile/data/auth/models/user.dart';
import 'package:holy_mobile/data/auth/models/user_settings.dart';

class AuthState {
  const AuthState({
    this.user,
    this.settings,
    this.isLoading = false,
    this.errorMessage,
  });

  final User? user;
  final UserSettings? settings;
  final bool isLoading;
  final String? errorMessage;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    User? user,
    UserSettings? settings,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
