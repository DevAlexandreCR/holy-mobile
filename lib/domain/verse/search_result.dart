class SearchVerse {
  const SearchVerse({required this.verseNumber, required this.text});

  final int verseNumber;
  final String text;

  factory SearchVerse.fromMap(Map<String, dynamic> map) {
    return SearchVerse(
      verseNumber: _parseInt(map['verseNumber'] ?? map['verse_number'] ?? map['number']),
      text: map['text']?.toString() ?? map['verse']?.toString() ?? '',
    );
  }

  static int _parseInt(Object? value) {
    return switch (value) {
      int v => v,
      String v => int.tryParse(v) ?? 0,
      _ => 0,
    };
  }
}

class SearchReference {
  const SearchReference({
    required this.book,
    required this.bookId,
    required this.chapter,
    required this.verseStart,
    this.verseEnd,
  });

  final String book;
  final int bookId;
  final int chapter;
  final int verseStart;
  final int? verseEnd;

  factory SearchReference.fromMap(Map<String, dynamic> map) {
    return SearchReference(
      book: map['book']?.toString() ?? '',
      bookId: SearchVerse._parseInt(map['bookId'] ?? map['book_id']),
      chapter: SearchVerse._parseInt(map['chapter']),
      verseStart: SearchVerse._parseInt(map['verseStart'] ?? map['verse_start']),
      verseEnd: map['verseEnd'] != null || map['verse_end'] != null
          ? SearchVerse._parseInt(map['verseEnd'] ?? map['verse_end'])
          : null,
    );
  }

  String get displayReference {
    final end = verseEnd ?? verseStart;
    if (end != verseStart) {
      return '$book $chapter:$verseStart-$end';
    }
    if (verseStart > 0) {
      return '$book $chapter:$verseStart';
    }
    return '$book $chapter';
  }
}

class SearchVersion {
  const SearchVersion({
    required this.id,
    required this.name,
    required this.abbreviation,
  });

  final int id;
  final String name;
  final String abbreviation;

  factory SearchVersion.fromMap(Map<String, dynamic> map) {
    final apiCode = map['abbreviation'] ?? map['apiCode'] ?? map['api_code'];
    return SearchVersion(
      id: SearchVerse._parseInt(map['id']),
      name: map['name']?.toString() ?? '',
      abbreviation: apiCode?.toString() ?? '',
    );
  }
}

class SearchResult {
  const SearchResult({
    required this.reference,
    required this.verses,
    required this.version,
    required this.canShareAsImage,
    required this.characterCount,
  });

  final SearchReference reference;
  final List<SearchVerse> verses;
  final SearchVersion version;
  final bool canShareAsImage;
  final int characterCount;

  factory SearchResult.fromMap(Map<String, dynamic> map) {
    final versesRaw = map['verses'] ?? const [];
    final parsedVerses = versesRaw is List
        ? versesRaw
            .whereType<Map>()
            .map((item) => SearchVerse.fromMap(Map<String, dynamic>.from(item)))
            .toList()
        : <SearchVerse>[];

    return SearchResult(
      reference: SearchReference.fromMap(
        Map<String, dynamic>.from(map['reference'] as Map? ?? const {}),
      ),
      verses: parsedVerses,
      version: SearchVersion.fromMap(
        Map<String, dynamic>.from(map['version'] as Map? ?? const {}),
      ),
      canShareAsImage: map['canShareAsImage'] as bool? ??
          map['can_share_as_image'] as bool? ??
          false,
      characterCount: SearchVerse._parseInt(
        map['characterCount'] ?? map['character_count'],
      ),
    );
  }
}
