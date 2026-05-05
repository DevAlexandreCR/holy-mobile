class DevotionalAudioSegment {
  const DevotionalAudioSegment({
    required this.order,
    required this.url,
    required this.durationMs,
    required this.chars,
  });

  final int order;
  final String url;
  final int? durationMs;
  final int chars;

  factory DevotionalAudioSegment.fromMap(Map<String, dynamic> map) {
    return DevotionalAudioSegment(
      order: (map['order'] as num?)?.toInt() ?? 0,
      url: map['url']?.toString() ?? '',
      durationMs: (map['duration_ms'] as num?)?.toInt(),
      chars: (map['chars'] as num?)?.toInt() ?? 0,
    );
  }
}
