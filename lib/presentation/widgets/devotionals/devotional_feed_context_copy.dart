import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/domain/devotionals/devotional.dart';
import 'package:holyverso/domain/devotionals/devotional_feed_mode.dart';

String? devotionalFeedInterpretationLabel(
  AppLocalizations l10n,
  String? reason,
) {
  switch (reason) {
    case 'SAVED_BY_OTHERS':
      return l10n.devotionalFeedSignalSavedByOthers;
    case 'HIGH_COMPLETION':
      return l10n.devotionalFeedSignalHighCompletion;
    case 'HIGH_SHARE':
      return l10n.devotionalFeedSignalHighShare;
    case 'FOLLOWED_AUTHOR':
      return l10n.devotionalFeedSignalFollowedAuthor;
    default:
      return null;
  }
}

String? devotionalDetailContinuityLabel(
  AppLocalizations l10n,
  Devotional devotional,
) {
  final interpretation = devotionalFeedInterpretationLabel(
    l10n,
    devotional.feedContextReason,
  );
  if (interpretation != null) {
    return interpretation;
  }

  if (devotional.recommendationReason == DevotionalFeedMode.forYou.name) {
    return l10n.devotionalFeedOpenCta;
  }

  return null;
}
