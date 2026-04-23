import 'package:holyverso/domain/devotionals/devotional.dart';

enum DevotionalDetailStatus { idle, loading, success, error }

class DevotionalDetailState {
  static const _unset = Object();

  const DevotionalDetailState({
    this.devotional,
    this.status = DevotionalDetailStatus.idle,
    this.deliveryToken,
    this.shareToken,
    this.deviceId,
    this.errorMessage,
    this.isTogglingLike = false,
    this.isTogglingSave = false,
    this.isReporting = false,
    this.isReportingReadComplete = false,
    this.hasReportedReadComplete = false,
    this.readCompleteJustSucceeded = false,
    this.isApprovingReview = false,
    this.isRestrictingReview = false,
  });

  final Devotional? devotional;
  final DevotionalDetailStatus status;
  final String? deliveryToken;
  final String? shareToken;
  final String? deviceId;
  final String? errorMessage;
  final bool isTogglingLike;
  final bool isTogglingSave;
  final bool isReporting;
  final bool isReportingReadComplete;
  final bool hasReportedReadComplete;

  /// True for exactly one state emission after the backend confirms read-complete.
  /// Consumers must clear it immediately after reacting.
  final bool readCompleteJustSucceeded;
  final bool isApprovingReview;
  final bool isRestrictingReview;

  DevotionalDetailState copyWith({
    Devotional? devotional,
    DevotionalDetailStatus? status,
    Object? deliveryToken = _unset,
    Object? shareToken = _unset,
    Object? deviceId = _unset,
    String? errorMessage,
    bool? isTogglingLike,
    bool? isTogglingSave,
    bool? isReporting,
    bool? isReportingReadComplete,
    bool? hasReportedReadComplete,
    bool? readCompleteJustSucceeded,
    bool? isApprovingReview,
    bool? isRestrictingReview,
    bool clearError = false,
    bool clearDevotional = false,
  }) {
    return DevotionalDetailState(
      devotional: clearDevotional ? null : devotional ?? this.devotional,
      status: status ?? this.status,
      deliveryToken: identical(deliveryToken, _unset)
          ? this.deliveryToken
          : deliveryToken as String?,
      shareToken: identical(shareToken, _unset)
          ? this.shareToken
          : shareToken as String?,
      deviceId: identical(deviceId, _unset)
          ? this.deviceId
          : deviceId as String?,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      isTogglingLike: isTogglingLike ?? this.isTogglingLike,
      isTogglingSave: isTogglingSave ?? this.isTogglingSave,
      isReporting: isReporting ?? this.isReporting,
      isReportingReadComplete:
          isReportingReadComplete ?? this.isReportingReadComplete,
      hasReportedReadComplete:
          hasReportedReadComplete ?? this.hasReportedReadComplete,
      readCompleteJustSucceeded:
          readCompleteJustSucceeded ?? this.readCompleteJustSucceeded,
      isApprovingReview: isApprovingReview ?? this.isApprovingReview,
      isRestrictingReview: isRestrictingReview ?? this.isRestrictingReview,
    );
  }
}
