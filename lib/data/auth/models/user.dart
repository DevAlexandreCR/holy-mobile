import 'package:holyverso/domain/roles/user_role.dart';
import 'package:holyverso/domain/users/user_moderation_state.dart';

class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.moderation = const UserModerationState(),
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final UserModerationState moderation;

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      role: UserRole.fromString(map['role']?.toString() ?? ''),
      moderation: UserModerationState.fromMap(
        map['moderation'] is Map
            ? Map<String, dynamic>.from(map['moderation'] as Map)
            : null,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'moderation': moderation.toMap(),
    };
  }
}
