import 'package:holyverso/domain/roles/user_role.dart';
import 'package:holyverso/domain/users/user_moderation_state.dart';

class UserWithRole {
  const UserWithRole({
    required this.id,
    required this.email,
    this.name,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.moderation = const UserModerationState(),
  });

  final String id;
  final String email;
  final String? name;
  final UserRole role;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserModerationState moderation;

  String get displayName {
    final trimmed = name?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }
    final emailPrefix = email.split('@').first;
    return emailPrefix.isNotEmpty ? emailPrefix : email;
  }

  factory UserWithRole.fromMap(Map<String, dynamic> map) {
    return UserWithRole(
      id: map['id']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      name: map['name']?.toString(),
      role: UserRole.fromString(map['role']?.toString() ?? ''),
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedAt:
          DateTime.tryParse(map['updatedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      moderation: UserModerationState.fromMap(
        map['moderation'] is Map
            ? Map<String, dynamic>.from(map['moderation'] as Map)
            : null,
      ),
    );
  }

  UserWithRole copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserModerationState? moderation,
  }) {
    return UserWithRole(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      moderation: moderation ?? this.moderation,
    );
  }
}
