class ChapterVerse {
  const ChapterVerse({required this.number, required this.text, this.study});

  final int number;
  final String text;
  final String? study;

  Map<String, dynamic> toMap() {
    return {'number': number, 'text': text, if (study != null) 'study': study};
  }

  factory ChapterVerse.fromMap(Map<String, dynamic> map) {
    return ChapterVerse(
      number:
          (map['number'] as num?)?.toInt() ??
          (map['verse'] as num?)?.toInt() ??
          0,
      text: map['text'] as String? ?? map['verse'] as String? ?? '',
      study: map['study'] as String?,
    );
  }
}

class Chapter {
  const Chapter({
    required this.book,
    required this.chapter,
    required this.reference,
    required this.numChapters,
    required this.versionCode,
    required this.versionName,
    required this.verses,
  });

  final String book;
  final int chapter;
  final String reference;
  final int numChapters;
  final String versionCode;
  final String versionName;
  final List<ChapterVerse> verses;

  String get displayVersionCode => versionCode.toUpperCase();

  Map<String, dynamic> toMap() {
    return {
      'book': book,
      'chapter': chapter,
      'reference': reference,
      'num_chapters': numChapters,
      'version_code': versionCode,
      'version_name': versionName,
      'verses': verses.map((v) => v.toMap()).toList(),
    };
  }

  factory Chapter.fromMap(Map<String, dynamic> map) {
    final rawVerses = map['verses'] ?? map['vers'];
    final parsedVerses = rawVerses is List
        ? rawVerses
              .whereType<Map>()
              .map(
                (item) => ChapterVerse.fromMap(Map<String, dynamic>.from(item)),
              )
              .toList()
        : <ChapterVerse>[];

    final rawBook = (map['book'] ?? map['name'] ?? '').toString();
    final rawChapter = (map['chapter'] as num?)?.toInt() ?? 0;
    final reference =
        map['reference'] as String? ??
        '$rawBook ${rawChapter > 0 ? rawChapter : ''}'.trim();

    return Chapter(
      book: rawBook,
      chapter: rawChapter,
      reference: reference,
      numChapters:
          (map['num_chapters'] as num?)?.toInt() ??
          (map['numChapters'] as num?)?.toInt() ??
          0,
      versionCode:
          map['version_code'] as String? ?? map['versionCode'] as String? ?? '',
      versionName:
          map['version_name'] as String? ?? map['versionName'] as String? ?? '',
      verses: parsedVerses,
    );
  }
}
