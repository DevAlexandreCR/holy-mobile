import 'package:holyverso/domain/devotionals/devotional.dart';

enum DevotionalDetailStatus { idle, loading, success, error }

class DevotionalDetailState {
  const DevotionalDetailState({
    this.devotional,
    this.status = DevotionalDetailStatus.idle,
    this.errorMessage,
    this.isTogglingLike = false,
  });

  final Devotional? devotional;
  final DevotionalDetailStatus status;
  final String? errorMessage;
  final bool isTogglingLike;

  DevotionalDetailState copyWith({
    Devotional? devotional,
    DevotionalDetailStatus? status,
    String? errorMessage,
    bool? isTogglingLike,
    bool clearError = false,
  }) {
    return DevotionalDetailState(
      devotional: devotional ?? this.devotional,
      status: status ?? this.status,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      isTogglingLike: isTogglingLike ?? this.isTogglingLike,
    );
  }
}
