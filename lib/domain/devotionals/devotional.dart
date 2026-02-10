import 'package:holyverso/domain/devotionals/devotional_author.dart';
import 'package:holyverso/domain/devotionals/devotional_status.dart';
import 'package:holyverso/domain/devotionals/devotional_verse_reference.dart';

class Devotional {
  const Devotional({
    required this.id,
    required this.title,
    required this.status,
    required this.coverImageUrl,
    required this.viewCount,
    required this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.author,
    required this.verseReferences,
    required this.likesCount,
    required this.commentsCount,
    required this.liked,
    required this.isOwner,
    this.content,
  });

  final String id;
  final String title;
  final DevotionalStatus status;
  final String? coverImageUrl;
  final int viewCount;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DevotionalAuthor author;
  final List<DevotionalVerseReference> verseReferences;
  final int likesCount;
  final int commentsCount;
  final bool liked;
  final bool isOwner;
  final List<dynamic>? content;

  List<DevotionalVerseReference> get primaryReferences =>
      verseReferences.where((ref) => ref.isPrimary).toList();

  factory Devotional.fromMap(Map<String, dynamic> map) {
    final rawReferences = map['verse_references'] as List? ??
        map['verseReferences'] as List? ??
        const [];

    final contentRaw = map['content'];
    List<dynamic>? content;
    if (contentRaw is List) {
      content = contentRaw;
    } else if (contentRaw is Map && contentRaw['ops'] is List) {
      content = List<dynamic>.from(contentRaw['ops'] as List);
    }

    return Devotional(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      status: DevotionalStatus.fromString(map['status']?.toString() ?? ''),
      coverImageUrl: map['cover_image_url']?.toString(),
      viewCount: (map['view_count'] as num?)?.toInt() ?? 0,
      publishedAt: DateTime.tryParse(map['published_at']?.toString() ?? ''),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      author: DevotionalAuthor.fromMap(
        Map<String, dynamic>.from(map['author'] as Map? ?? const {}),
      ),
      verseReferences: rawReferences
          .whereType<Map>()
          .map((item) => DevotionalVerseReference.fromMap(
                Map<String, dynamic>.from(item),
              ))
          .toList(),
      likesCount: (map['likes_count'] as num?)?.toInt() ?? 0,
      commentsCount: (map['comments_count'] as num?)?.toInt() ?? 0,
      liked: map['liked'] == true,
      isOwner: map['is_owner'] == true,
      content: content,
    );
  }

  Devotional copyWith({
    int? likesCount,
    bool? liked,
    int? commentsCount,
    List<dynamic>? content,
  }) {
    return Devotional(
      id: id,
      title: title,
      status: status,
      coverImageUrl: coverImageUrl,
      viewCount: viewCount,
      publishedAt: publishedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      author: author,
      verseReferences: verseReferences,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      liked: liked ?? this.liked,
      isOwner: isOwner,
      content: content ?? this.content,
    );
  }
}
