enum DevotionalListeningStatus {
  idle,
  disabled,
  loading,
  buffering,
  playing,
  paused,
  completed,
  error,
}

class DevotionalListeningState {
  static const _unset = Object();

  const DevotionalListeningState({
    this.status = DevotionalListeningStatus.idle,
    this.configLoaded = false,
    this.enabled = false,
    this.isPlayerVisible = false,
    this.unavailableMessage,
    this.activeDevotionalId,
    this.completedDevotionalId,
    this.errorMessage,
    this.retryAfterMs,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  final DevotionalListeningStatus status;
  final bool configLoaded;
  final bool enabled;
  final bool isPlayerVisible;
  final String? unavailableMessage;
  final String? activeDevotionalId;
  final String? completedDevotionalId;
  final String? errorMessage;
  final int? retryAfterMs;
  final Duration position;
  final Duration duration;

  bool get hasProgress => duration > Duration.zero;

  bool get hasActiveSession =>
      status == DevotionalListeningStatus.loading ||
      status == DevotionalListeningStatus.buffering ||
      status == DevotionalListeningStatus.playing ||
      status == DevotionalListeningStatus.paused;

  double get progressValue {
    if (!hasProgress) {
      return 0;
    }

    final totalMs = duration.inMilliseconds;
    if (totalMs <= 0) {
      return 0;
    }

    return (position.inMilliseconds / totalMs).clamp(0, 1).toDouble();
  }

  DevotionalListeningState copyWith({
    DevotionalListeningStatus? status,
    bool? configLoaded,
    bool? enabled,
    bool? isPlayerVisible,
    Object? unavailableMessage = _unset,
    Object? activeDevotionalId = _unset,
    Object? completedDevotionalId = _unset,
    Object? errorMessage = _unset,
    Object? retryAfterMs = _unset,
    Duration? position,
    Duration? duration,
    bool clearError = false,
  }) {
    return DevotionalListeningState(
      status: status ?? this.status,
      configLoaded: configLoaded ?? this.configLoaded,
      enabled: enabled ?? this.enabled,
      isPlayerVisible: isPlayerVisible ?? this.isPlayerVisible,
      unavailableMessage: identical(unavailableMessage, _unset)
          ? this.unavailableMessage
          : unavailableMessage as String?,
      activeDevotionalId: identical(activeDevotionalId, _unset)
          ? this.activeDevotionalId
          : activeDevotionalId as String?,
      completedDevotionalId: identical(completedDevotionalId, _unset)
          ? this.completedDevotionalId
          : completedDevotionalId as String?,
      errorMessage: clearError
          ? null
          : identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      retryAfterMs: identical(retryAfterMs, _unset)
          ? this.retryAfterMs
          : retryAfterMs as int?,
      position: position ?? this.position,
      duration: duration ?? this.duration,
    );
  }
}
