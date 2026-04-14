import 'package:holyverso/domain/devotionals/devotional_daily_featured.dart';

class DevotionalFeedHeader {
  const DevotionalFeedHeader({
    required this.currentStreak,
    required this.longestStreak,
    required this.streakFreezeCount,
    required this.completedToday,
    required this.dailyFeatured,
    required this.primaryCtaType,
    required this.primaryCtaLabel,
    required this.primaryCtaDevotionalId,
  });

  final int currentStreak;
  final int longestStreak;
  final int streakFreezeCount;
  final bool completedToday;
  final DevotionalDailyFeatured? dailyFeatured;
  final String primaryCtaType;
  final String primaryCtaLabel;
  final String? primaryCtaDevotionalId;

  factory DevotionalFeedHeader.fromMap(Map<String, dynamic> map) {
    final streak = Map<String, dynamic>.from(map['streak'] as Map? ?? const {});
    final dailyFeaturedMap = map['daily_featured'];
    final primaryCta = Map<String, dynamic>.from(
      map['primary_cta'] as Map? ?? const {},
    );

    return DevotionalFeedHeader(
      currentStreak: (streak['current_streak'] as num?)?.toInt() ?? 0,
      longestStreak: (streak['longest_streak'] as num?)?.toInt() ?? 0,
      streakFreezeCount: (streak['streak_freeze_count'] as num?)?.toInt() ?? 0,
      completedToday: map['completed_today'] == true,
      dailyFeatured: dailyFeaturedMap is Map
          ? DevotionalDailyFeatured.fromMap(
              Map<String, dynamic>.from(dailyFeaturedMap),
            )
          : null,
      primaryCtaType: primaryCta['type']?.toString() ?? 'OPEN_DAILY_FEATURED',
      primaryCtaLabel: primaryCta['label']?.toString() ?? 'Completa tu día',
      primaryCtaDevotionalId: primaryCta['devotional_id']?.toString(),
    );
  }
}
