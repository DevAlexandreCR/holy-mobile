import 'package:holyverso/data/widget/models/widget_install_status.dart';

class WidgetAdoptionPromptState {
  const WidgetAdoptionPromptState({
    this.isChecking = false,
    this.shouldShowPrompt = false,
    this.installStatus,
    this.dismissedUntil,
    this.hasResolved = false,
  });

  final bool isChecking;
  final bool shouldShowPrompt;
  final WidgetInstallStatus? installStatus;
  final DateTime? dismissedUntil;
  final bool hasResolved;

  WidgetAdoptionPromptState copyWith({
    bool? isChecking,
    bool? shouldShowPrompt,
    WidgetInstallStatus? installStatus,
    DateTime? dismissedUntil,
    bool? hasResolved,
    bool clearInstallStatus = false,
    bool clearDismissedUntil = false,
  }) {
    return WidgetAdoptionPromptState(
      isChecking: isChecking ?? this.isChecking,
      shouldShowPrompt: shouldShowPrompt ?? this.shouldShowPrompt,
      installStatus: clearInstallStatus
          ? null
          : installStatus ?? this.installStatus,
      dismissedUntil: clearDismissedUntil
          ? null
          : dismissedUntil ?? this.dismissedUntil,
      hasResolved: hasResolved ?? this.hasResolved,
    );
  }
}
