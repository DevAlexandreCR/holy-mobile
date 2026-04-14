class DevotionalDailyFeatured {
  const DevotionalDailyFeatured({
    required this.id,
    required this.title,
    required this.estimatedReadTime,
    required this.previewText,
    required this.previewImageUrl,
  });

  final String id;
  final String title;
  final int estimatedReadTime;
  final String previewText;
  final String? previewImageUrl;

  factory DevotionalDailyFeatured.fromMap(Map<String, dynamic> map) {
    return DevotionalDailyFeatured(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      estimatedReadTime: (map['estimated_read_time'] as num?)?.toInt() ?? 1,
      previewText: map['preview_text']?.toString() ?? '',
      previewImageUrl: map['preview_image_url']?.toString(),
    );
  }
}
