class UserSettings {
  const UserSettings({
    this.preferredVersionId,
    this.timezone,
  });

  final int? preferredVersionId;
  final String? timezone;

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    final rawPreferred = map['preferred_version_id'] ?? map['preferredVersionId'];
    final preferredId = switch (rawPreferred) {
      int value => value,
      String value => int.tryParse(value),
      _ => null,
    };

    return UserSettings(
      preferredVersionId: preferredId,
      timezone: map['timezone'] as String?,
    );
  }
}
