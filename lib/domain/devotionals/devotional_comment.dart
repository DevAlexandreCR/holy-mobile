import 'package:holyverso/domain/devotionals/devotional_author.dart';

class DevotionalComment {
  const DevotionalComment({
    required this.id,
    required this.devotionalId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.author,
  });

  final String id;
  final String devotionalId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DevotionalAuthor author;

  factory DevotionalComment.fromMap(Map<String, dynamic> map) {
    return DevotionalComment(
      id: map['id']?.toString() ?? '',
      devotionalId:
          map['devotional_id']?.toString() ??
          map['devotionalId']?.toString() ??
          '',
      content: map['content']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          DateTime.tryParse(map['updated_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      author: DevotionalAuthor.fromMap(
        Map<String, dynamic>.from(map['author'] as Map? ?? const {}),
      ),
    );
  }
}
