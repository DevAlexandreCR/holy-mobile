import 'package:holyverso/domain/devotionals/devotional_audio_segment.dart';

enum DevotionalAudioResponseStatus { ready, generating }

class DevotionalAudioResponse {
  const DevotionalAudioResponse({
    required this.status,
    this.segments = const [],
    this.retryAfterMs,
  });

  final DevotionalAudioResponseStatus status;
  final List<DevotionalAudioSegment> segments;
  final int? retryAfterMs;

  bool get isReady => status == DevotionalAudioResponseStatus.ready;
  bool get isGenerating => status == DevotionalAudioResponseStatus.generating;

  factory DevotionalAudioResponse.fromMap(Map<String, dynamic> map) {
    final statusRaw = map['status']?.toString().toUpperCase() ?? 'READY';
    final segmentsRaw = map['segments'] as List? ?? const [];

    return DevotionalAudioResponse(
      status: statusRaw == 'GENERATING'
          ? DevotionalAudioResponseStatus.generating
          : DevotionalAudioResponseStatus.ready,
      segments: segmentsRaw
          .whereType<Map>()
          .map(
            (item) =>
                DevotionalAudioSegment.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList(),
      retryAfterMs: (map['retry_after_ms'] as num?)?.toInt(),
    );
  }
}
