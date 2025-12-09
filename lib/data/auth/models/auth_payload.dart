import 'package:holy_mobile/data/auth/models/user.dart';
import 'package:holy_mobile/data/auth/models/user_settings.dart';

class AuthPayload {
  const AuthPayload({
    required this.user,
    this.settings,
    this.accessToken,
  });

  final User user;
  final UserSettings? settings;
  final String? accessToken;

  factory AuthPayload.fromMap(Map<String, dynamic> map) {
    final dynamic rawData = map['data'] ?? map;
    final data = Map<String, dynamic>.from(rawData as Map);

    return AuthPayload(
      user: User.fromMap(data['user'] as Map<String, dynamic>),
      settings:
          data['settings'] != null ? UserSettings.fromMap(data['settings'] as Map<String, dynamic>) : null,
      accessToken: data['access_token'] as String?,
    );
  }
}
