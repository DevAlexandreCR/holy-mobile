class DevotionalAuthorBlockRecommendation {
  const DevotionalAuthorBlockRecommendation({
    required this.restrictedDevotionalsCountLast30Days,
    required this.threshold,
    required this.windowDays,
    required this.thresholdMet,
    required this.authorIsBlocked,
  });

  final int restrictedDevotionalsCountLast30Days;
  final int threshold;
  final int windowDays;
  final bool thresholdMet;
  final bool authorIsBlocked;

  bool get shouldSuggestBlocking => thresholdMet && !authorIsBlocked;

  factory DevotionalAuthorBlockRecommendation.fromMap(
    Map<String, dynamic> map,
  ) {
    return DevotionalAuthorBlockRecommendation(
      restrictedDevotionalsCountLast30Days:
          (map['restricted_devotionals_count_last_30_days'] as num?)?.toInt() ??
          0,
      threshold: (map['threshold'] as num?)?.toInt() ?? 3,
      windowDays: (map['window_days'] as num?)?.toInt() ?? 30,
      thresholdMet: map['threshold_met'] == true,
      authorIsBlocked: map['author_is_blocked'] == true,
    );
  }
}
