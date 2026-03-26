import 'package:holyverso/domain/devotionals/devotional.dart';

enum DevotionalDetailStatus { idle, loading, success, error }

class DevotionalDetailState {
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
  final bool isApprovingReview;
  final bool isRestrictingReview;

  DevotionalDetailState copyWith({
    Devotional? devotional,
    DevotionalDetailStatus? status,
    String? deliveryToken,
    String? shareToken,
    String? deviceId,
    String? errorMessage,
    bool? isTogglingLike,
    bool? isTogglingSave,
    bool? isReporting,
    bool? isReportingReadComplete,
    bool? hasReportedReadComplete,
    bool? isApprovingReview,
    bool? isRestrictingReview,
    bool clearError = false,
    bool clearDevotional = false,
  }) {
    return DevotionalDetailState(
      devotional: clearDevotional ? null : devotional ?? this.devotional,
      status: status ?? this.status,
      deliveryToken: deliveryToken ?? this.deliveryToken,
      shareToken: shareToken ?? this.shareToken,
      deviceId: deviceId ?? this.deviceId,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      isTogglingLike: isTogglingLike ?? this.isTogglingLike,
      isTogglingSave: isTogglingSave ?? this.isTogglingSave,
      isReporting: isReporting ?? this.isReporting,
      isReportingReadComplete:
          isReportingReadComplete ?? this.isReportingReadComplete,
      hasReportedReadComplete:
          hasReportedReadComplete ?? this.hasReportedReadComplete,
      isApprovingReview: isApprovingReview ?? this.isApprovingReview,
      isRestrictingReview: isRestrictingReview ?? this.isRestrictingReview,
    );
  }
}
