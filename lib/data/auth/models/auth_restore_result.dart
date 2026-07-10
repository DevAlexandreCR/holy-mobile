import 'package:holyverso/data/auth/models/auth_payload.dart';

enum AuthRestoreStatus {
  missing,
  authenticated,
  authenticatedStale,
  reconnecting,
  expired,
}

class AuthRestoreResult {
  const AuthRestoreResult._(this.status, {this.payload});

  final AuthRestoreStatus status;
  final AuthPayload? payload;

  bool get hasSession =>
      status == AuthRestoreStatus.authenticated ||
      status == AuthRestoreStatus.authenticatedStale;

  factory AuthRestoreResult.missing() {
    return const AuthRestoreResult._(AuthRestoreStatus.missing);
  }

  factory AuthRestoreResult.authenticated(AuthPayload payload) {
    return AuthRestoreResult._(
      AuthRestoreStatus.authenticated,
      payload: payload,
    );
  }

  factory AuthRestoreResult.authenticatedStale(AuthPayload payload) {
    return AuthRestoreResult._(
      AuthRestoreStatus.authenticatedStale,
      payload: payload,
    );
  }

  factory AuthRestoreResult.reconnecting() {
    return const AuthRestoreResult._(AuthRestoreStatus.reconnecting);
  }

  factory AuthRestoreResult.expired() {
    return const AuthRestoreResult._(AuthRestoreStatus.expired);
  }
}
