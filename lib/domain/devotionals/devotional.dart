import 'package:holyverso/domain/devotionals/devotional_author.dart';
import 'package:holyverso/domain/devotionals/devotional_moderation_status.dart';
import 'package:holyverso/domain/devotionals/devotional_publication_state.dart';
import 'package:holyverso/domain/devotionals/devotional_status.dart';
import 'package:holyverso/domain/devotionals/devotional_verse_reference.dart';

class Devotional {
  const Devotional({
    required this.id,
    required this.title,
    required this.status,
    required this.publicationState,
    required this.moderationStatus,
    required this.effectiveState,
    required this.moderationReason,
    required this.coverImageUrl,
    required this.previewImageUrl,
    required this.previewText,
    required this.computedHook,
    required this.optimizedPreviewText,
    required this.hookSource,
    required this.coverImageFocusY,
    required this.viewCount,
    required this.estimatedReadTime,
    required this.publishedAt,
    required this.firstPublishedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.author,
    required this.verseReferences,
    required this.likesCount,
    required this.commentsCount,
    required this.shareCount,
    required this.saveCount,
    required this.readCompleteCount,
    required this.impressionCount,
    required this.uniqueImpressionCount,
    required this.reportCount,
    required this.openReportCount,
    required this.liked,
    required this.saved,
    required this.isOwner,
    required this.canModerate,
    required this.deliveryToken,
    required this.recommendationReason,
    required this.feedContextReason,
    this.content,
  });

  final String id;
  final String title;
  final DevotionalStatus status;
  final DevotionalPublicationState publicationState;
  final DevotionalModerationStatus moderationStatus;
  final String effectiveState;
  final String? moderationReason;
  final String? coverImageUrl;
  final String? previewImageUrl;
  final String previewText;
  final String computedHook;
  final String optimizedPreviewText;
  final String? hookSource;
  final double coverImageFocusY;
  final int viewCount;
  final int estimatedReadTime;
  final DateTime? publishedAt;
  final DateTime? firstPublishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DevotionalAuthor author;
  final List<DevotionalVerseReference> verseReferences;
  final int likesCount;
  final int commentsCount;
  final int shareCount;
  final int saveCount;
  final int readCompleteCount;
  final int impressionCount;
  final int uniqueImpressionCount;
  final int reportCount;
  final int openReportCount;
  final bool liked;
  final bool saved;
  final bool isOwner;
  final bool canModerate;
  final String? deliveryToken;
  final String? recommendationReason;
  final String? feedContextReason;
  final List<dynamic>? content;

  List<DevotionalVerseReference> get primaryReferences =>
      verseReferences.where((ref) => ref.isPrimary).toList();

  bool get isPubliclyVisible =>
      moderationStatus == DevotionalModerationStatus.clear &&
      publicationState != DevotionalPublicationState.draft &&
      publicationState != DevotionalPublicationState.archived;

  String get primaryHook {
    final hook = computedHook.trim();
    if (hook.isNotEmpty) return hook;
    return title.trim();
  }

  String get feedPreview {
    final preview = optimizedPreviewText.trim();
    if (preview.isNotEmpty) return preview;
    return previewText.trim();
  }

  factory Devotional.fromMap(Map<String, dynamic> map) {
    final rawReferences =
        map['verse_references'] as List? ??
        map['verseReferences'] as List? ??
        const [];

    final contentRaw = map['content'];
    List<dynamic>? content;
    if (contentRaw is List) {
      content = List<dynamic>.from(contentRaw);
    } else if (contentRaw is Map && contentRaw['ops'] is List) {
      content = List<dynamic>.from(contentRaw['ops'] as List);
    }

    final viewerState = map['viewer_state'] as Map?;
    final counters = map['counters'] as Map?;
    final authorRelationship = map['author_relationship'] as Map?;
    final authorMap = Map<String, dynamic>.from(
      map['author'] as Map? ?? const {},
    );
    if (authorRelationship?['following'] != null) {
      authorMap['following'] = authorRelationship!['following'];
    }

    return Devotional(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      status: DevotionalStatus.fromString(map['status']?.toString() ?? ''),
      publicationState: DevotionalPublicationState.fromString(
        map['publication_state']?.toString() ?? '',
      ),
      moderationStatus: DevotionalModerationStatus.fromString(
        map['moderation_status']?.toString() ?? '',
      ),
      effectiveState: map['effective_state']?.toString() ?? '',
      moderationReason: map['moderation_reason']?.toString(),
      coverImageUrl: map['cover_image_url']?.toString(),
      previewImageUrl:
          map['preview_image_url']?.toString() ??
          map['cover_image_url']?.toString(),
      previewText: map['preview_text']?.toString() ?? '',
      computedHook: map['computed_hook']?.toString() ?? '',
      optimizedPreviewText: map['optimized_preview_text']?.toString() ?? '',
      hookSource: map['hook_source']?.toString(),
      coverImageFocusY: _parseCoverImageFocusY(map['cover_image_focus_y']),
      viewCount: (map['view_count'] as num?)?.toInt() ?? 0,
      estimatedReadTime: (map['estimated_read_time'] as num?)?.toInt() ?? 1,
      publishedAt: DateTime.tryParse(map['published_at']?.toString() ?? ''),
      firstPublishedAt: DateTime.tryParse(
        map['first_published_at']?.toString() ?? '',
      ),
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          DateTime.tryParse(map['updated_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      author: DevotionalAuthor.fromMap(authorMap),
      verseReferences: rawReferences
          .whereType<Map>()
          .map(
            (item) => DevotionalVerseReference.fromMap(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      likesCount:
          (map['likes_count'] as num?)?.toInt() ??
          (counters?['like_count'] as num?)?.toInt() ??
          0,
      commentsCount:
          (map['comments_count'] as num?)?.toInt() ??
          (counters?['comment_count'] as num?)?.toInt() ??
          0,
      shareCount:
          (map['share_count'] as num?)?.toInt() ??
          (counters?['share_count'] as num?)?.toInt() ??
          0,
      saveCount:
          (map['save_count'] as num?)?.toInt() ??
          (counters?['save_count'] as num?)?.toInt() ??
          0,
      readCompleteCount: (map['read_complete_count'] as num?)?.toInt() ?? 0,
      impressionCount: (map['impression_count'] as num?)?.toInt() ?? 0,
      uniqueImpressionCount:
          (map['unique_impression_count'] as num?)?.toInt() ?? 0,
      reportCount: (map['report_count'] as num?)?.toInt() ?? 0,
      openReportCount: (map['open_report_count'] as num?)?.toInt() ?? 0,
      liked: viewerState?['liked'] == true || map['liked'] == true,
      saved: viewerState?['saved'] == true || map['saved'] == true,
      isOwner: map['is_owner'] == true,
      canModerate: map['can_moderate'] == true,
      deliveryToken: map['delivery_token']?.toString(),
      recommendationReason: map['recommendation_reason']?.toString(),
      feedContextReason: map['feed_context_reason']?.toString(),
      content: content,
    );
  }

  Devotional copyWith({
    int? likesCount,
    int? commentsCount,
    int? shareCount,
    int? saveCount,
    int? readCompleteCount,
    bool? liked,
    bool? saved,
    List<dynamic>? content,
    DevotionalAuthor? author,
  }) {
    return Devotional(
      id: id,
      title: title,
      status: status,
      publicationState: publicationState,
      moderationStatus: moderationStatus,
      effectiveState: effectiveState,
      moderationReason: moderationReason,
      coverImageUrl: coverImageUrl,
      previewImageUrl: previewImageUrl,
      previewText: previewText,
      computedHook: computedHook,
      optimizedPreviewText: optimizedPreviewText,
      hookSource: hookSource,
      coverImageFocusY: coverImageFocusY,
      viewCount: viewCount,
      estimatedReadTime: estimatedReadTime,
      publishedAt: publishedAt,
      firstPublishedAt: firstPublishedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      author: author ?? this.author,
      verseReferences: verseReferences,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      shareCount: shareCount ?? this.shareCount,
      saveCount: saveCount ?? this.saveCount,
      readCompleteCount: readCompleteCount ?? this.readCompleteCount,
      impressionCount: impressionCount,
      uniqueImpressionCount: uniqueImpressionCount,
      reportCount: reportCount,
      openReportCount: openReportCount,
      liked: liked ?? this.liked,
      saved: saved ?? this.saved,
      isOwner: isOwner,
      canModerate: canModerate,
      deliveryToken: deliveryToken,
      recommendationReason: recommendationReason,
      feedContextReason: feedContextReason,
      content: content ?? this.content,
    );
  }

  static double _parseCoverImageFocusY(dynamic rawValue) {
    final value = (rawValue as num?)?.toDouble() ?? 0;
    if (value < -1) return -1;
    if (value > 1) return 1;
    return value;
  }
}
