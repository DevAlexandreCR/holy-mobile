class DevotionalAudioConfig {
  const DevotionalAudioConfig({
    required this.enabled,
    required this.unavailableMessage,
  });

  final bool enabled;
  final String unavailableMessage;

  factory DevotionalAudioConfig.fromMap(Map<String, dynamic> map) {
    return DevotionalAudioConfig(
      enabled: map['enabled'] == true,
      unavailableMessage: map['unavailable_message']?.toString() ?? '',
    );
  }
}
