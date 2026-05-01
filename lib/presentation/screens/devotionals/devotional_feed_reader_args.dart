import 'package:holyverso/domain/devotionals/devotional_feed_mode.dart';

class DevotionalFeedReaderArgs {
  const DevotionalFeedReaderArgs({
    required this.feedMode,
    required this.initialDevotionalId,
    required this.initialDeliveryToken,
    this.heroTag,
  });

  final DevotionalFeedMode feedMode;
  final String initialDevotionalId;
  final String? initialDeliveryToken;
  final String? heroTag;
}
