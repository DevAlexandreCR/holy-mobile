import 'package:holyverso/data/auth/models/user.dart';
import 'package:holyverso/data/auth/models/user_settings.dart';

enum AuthSessionStatus {
  bootstrapping,
  authenticated,
  authenticatedStale,
  guest,
  expired,
}

class AuthState {
  const AuthState({
    this.user,
    this.settings,
    this.sessionStatus = AuthSessionStatus.guest,
    this.isLoading = false,
    this.isUpdatingSettings = false,
    this.errorMessage,
    this.infoMessage,
    this.hasStoredToken = false,
    this.isServerValidated = false,
  });

  final User? user;
  final UserSettings? settings;
  final AuthSessionStatus sessionStatus;
  final bool isLoading;
  final bool isUpdatingSettings;
  final String? errorMessage;
  final String? infoMessage;
  final bool hasStoredToken;
  final bool isServerValidated;

  bool get isAuthenticated =>
      user != null &&
      (sessionStatus == AuthSessionStatus.authenticated ||
          sessionStatus == AuthSessionStatus.authenticatedStale);
  bool get canAccessProtectedRoutes => isAuthenticated;
  bool get isBootstrapping => sessionStatus == AuthSessionStatus.bootstrapping;
  int? get preferredVersionId => settings?.preferredVersionId;

  AuthState copyWith({
    User? user,
    UserSettings? settings,
    AuthSessionStatus? sessionStatus,
    bool? isLoading,
    bool? isUpdatingSettings,
    String? errorMessage,
    String? infoMessage,
    bool? hasStoredToken,
    bool? isServerValidated,
    bool clearError = false,
    bool clearInfo = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      settings: settings ?? this.settings,
      sessionStatus: sessionStatus ?? this.sessionStatus,
      isLoading: isLoading ?? this.isLoading,
      isUpdatingSettings: isUpdatingSettings ?? this.isUpdatingSettings,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      infoMessage: clearInfo ? null : infoMessage ?? this.infoMessage,
      hasStoredToken: hasStoredToken ?? this.hasStoredToken,
      isServerValidated: isServerValidated ?? this.isServerValidated,
    );
  }
}
