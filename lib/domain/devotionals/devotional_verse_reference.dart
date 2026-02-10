class DevotionalVerseReference {
  const DevotionalVerseReference({
    required this.id,
    required this.book,
    required this.chapter,
    required this.verseStart,
    this.verseEnd,
    required this.isPrimary,
  });

  final String id;
  final String book;
  final int chapter;
  final int verseStart;
  final int? verseEnd;
  final bool isPrimary;

  String get referenceLabel {
    final end = verseEnd != null ? '-${verseEnd!}' : '';
    return '$book $chapter:$verseStart$end';
  }

  factory DevotionalVerseReference.fromMap(Map<String, dynamic> map) {
    return DevotionalVerseReference(
      id: map['id']?.toString() ?? '',
      book: map['book']?.toString() ?? '',
      chapter: (map['chapter'] as num?)?.toInt() ?? 0,
      verseStart:
          (map['verse_start'] as num?)?.toInt() ??
          (map['verseStart'] as num?)?.toInt() ??
          0,
      verseEnd:
          (map['verse_end'] as num?)?.toInt() ??
          (map['verseEnd'] as num?)?.toInt(),
      isPrimary: map['is_primary'] == true || map['isPrimary'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'book': book,
      'chapter': chapter,
      'verse_start': verseStart,
      if (verseEnd != null) 'verse_end': verseEnd,
      'is_primary': isPrimary,
    };
  }
}
