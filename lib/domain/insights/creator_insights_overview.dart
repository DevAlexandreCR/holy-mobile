class CreatorInsightsOverview {
  const CreatorInsightsOverview({
    required this.window,
    required this.windowStart,
    required this.windowEnd,
    required this.publishedDevotionalsLast30d,
    required this.totalImpressionsLast30d,
    required this.totalUniqueImpressionsLast30d,
    required this.totalOpensLast30d,
    required this.totalReadsCompletedLast30d,
    required this.readCompleteRateLast30d,
    required this.totalSavesLast30d,
    required this.totalSharesLast30d,
    required this.newFollowersLast30d,
  });

  final String window;
  final DateTime? windowStart;
  final DateTime? windowEnd;
  final int publishedDevotionalsLast30d;
  final int totalImpressionsLast30d;
  final int totalUniqueImpressionsLast30d;
  final int totalOpensLast30d;
  final int totalReadsCompletedLast30d;
  final double readCompleteRateLast30d;
  final int totalSavesLast30d;
  final int totalSharesLast30d;
  final int newFollowersLast30d;

  factory CreatorInsightsOverview.fromMap(Map<String, dynamic> map) {
    return CreatorInsightsOverview(
      window: map['window']?.toString() ?? 'last_30d',
      windowStart: DateTime.tryParse(map['window_start']?.toString() ?? ''),
      windowEnd: DateTime.tryParse(map['window_end']?.toString() ?? ''),
      publishedDevotionalsLast30d:
          (map['published_devotionals_last_30d'] as num?)?.toInt() ?? 0,
      totalImpressionsLast30d:
          (map['total_impressions_last_30d'] as num?)?.toInt() ?? 0,
      totalUniqueImpressionsLast30d:
          (map['total_unique_impressions_last_30d'] as num?)?.toInt() ?? 0,
      totalOpensLast30d:
          (map['total_opens_last_30d'] as num?)?.toInt() ?? 0,
      totalReadsCompletedLast30d:
          (map['total_reads_completed_last_30d'] as num?)?.toInt() ?? 0,
      readCompleteRateLast30d:
          (map['read_complete_rate_last_30d'] as num?)?.toDouble() ?? 0,
      totalSavesLast30d:
          (map['total_saves_last_30d'] as num?)?.toInt() ?? 0,
      totalSharesLast30d:
          (map['total_shares_last_30d'] as num?)?.toInt() ?? 0,
      newFollowersLast30d:
          (map['new_followers_last_30d'] as num?)?.toInt() ?? 0,
    );
  }
}
