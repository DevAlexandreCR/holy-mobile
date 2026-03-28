class UserModerationActor {
  const UserModerationActor({
    required this.id,
    required this.name,
    required this.email,
  });

  final String id;
  final String name;
  final String email;

  factory UserModerationActor.fromMap(Map<String, dynamic> map) {
    return UserModerationActor(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
    );
  }
}

class UserModerationState {
  const UserModerationState({
    this.isBlocked = false,
    this.blockedReason,
    this.blockedAt,
    this.blockedBy,
    this.unblockedReason,
    this.unblockedAt,
    this.unblockedBy,
  });

  final bool isBlocked;
  final String? blockedReason;
  final DateTime? blockedAt;
  final UserModerationActor? blockedBy;
  final String? unblockedReason;
  final DateTime? unblockedAt;
  final UserModerationActor? unblockedBy;

  factory UserModerationState.fromMap(Map<String, dynamic>? map) {
    final moderation = map == null
        ? const <String, dynamic>{}
        : Map<String, dynamic>.from(map);

    return UserModerationState(
      isBlocked: moderation['is_blocked'] == true,
      blockedReason: moderation['blocked_reason']?.toString(),
      blockedAt: DateTime.tryParse(moderation['blocked_at']?.toString() ?? ''),
      blockedBy: moderation['blocked_by'] is Map
          ? UserModerationActor.fromMap(
              Map<String, dynamic>.from(moderation['blocked_by'] as Map),
            )
          : null,
      unblockedReason: moderation['unblocked_reason']?.toString(),
      unblockedAt: DateTime.tryParse(
        moderation['unblocked_at']?.toString() ?? '',
      ),
      unblockedBy: moderation['unblocked_by'] is Map
          ? UserModerationActor.fromMap(
              Map<String, dynamic>.from(moderation['unblocked_by'] as Map),
            )
          : null,
    );
  }

  UserModerationState copyWith({
    bool? isBlocked,
    String? blockedReason,
    DateTime? blockedAt,
    UserModerationActor? blockedBy,
    String? unblockedReason,
    DateTime? unblockedAt,
    UserModerationActor? unblockedBy,
  }) {
    return UserModerationState(
      isBlocked: isBlocked ?? this.isBlocked,
      blockedReason: blockedReason ?? this.blockedReason,
      blockedAt: blockedAt ?? this.blockedAt,
      blockedBy: blockedBy ?? this.blockedBy,
      unblockedReason: unblockedReason ?? this.unblockedReason,
      unblockedAt: unblockedAt ?? this.unblockedAt,
      unblockedBy: unblockedBy ?? this.unblockedBy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'is_blocked': isBlocked,
      'blocked_reason': blockedReason,
      'blocked_at': blockedAt?.toIso8601String(),
      'blocked_by': blockedBy == null
          ? null
          : {
              'id': blockedBy!.id,
              'name': blockedBy!.name,
              'email': blockedBy!.email,
            },
      'unblocked_reason': unblockedReason,
      'unblocked_at': unblockedAt?.toIso8601String(),
      'unblocked_by': unblockedBy == null
          ? null
          : {
              'id': unblockedBy!.id,
              'name': unblockedBy!.name,
              'email': unblockedBy!.email,
            },
    };
  }
}
