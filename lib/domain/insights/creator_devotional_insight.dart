class CreatorDevotionalInsight {
  const CreatorDevotionalInsight({
    required this.id,
    required this.title,
    required this.publicationState,
    required this.effectiveState,
    required this.publishedAt,
    required this.impressions,
    required this.uniqueImpressions,
    required this.opens,
    required this.readCompletes,
    required this.readCompleteRate,
    required this.saves,
    required this.shares,
    required this.reports,
    this.likes = 0,
    this.comments = 0,
  });

  final String id;
  final String title;
  final String publicationState;
  final String effectiveState;
  final DateTime? publishedAt;
  final int impressions;
  final int uniqueImpressions;
  final int opens;
  final int readCompletes;
  final double readCompleteRate;
  final int saves;
  final int shares;
  final int reports;
  final int likes;
  final int comments;

  factory CreatorDevotionalInsight.fromMap(Map<String, dynamic> map) {
    return CreatorDevotionalInsight(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      publicationState: map['publication_state']?.toString() ?? '',
      effectiveState: map['effective_state']?.toString() ?? '',
      publishedAt: DateTime.tryParse(map['published_at']?.toString() ?? ''),
      impressions: (map['impressions'] as num?)?.toInt() ?? 0,
      uniqueImpressions: (map['unique_impressions'] as num?)?.toInt() ?? 0,
      opens: (map['opens'] as num?)?.toInt() ?? 0,
      readCompletes: (map['read_completes'] as num?)?.toInt() ?? 0,
      readCompleteRate:
          (map['read_complete_rate'] as num?)?.toDouble() ?? 0,
      saves: (map['saves'] as num?)?.toInt() ?? 0,
      shares: (map['shares'] as num?)?.toInt() ?? 0,
      reports: (map['reports'] as num?)?.toInt() ?? 0,
      likes: (map['likes'] as num?)?.toInt() ?? 0,
      comments: (map['comments'] as num?)?.toInt() ?? 0,
    );
  }
}
