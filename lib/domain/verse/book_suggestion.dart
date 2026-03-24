class BookSuggestion {
  const BookSuggestion({
    required this.bookName,
    required this.bookId,
    required this.abbreviations,
    required this.type,
  });

  final String bookName;
  final int bookId;
  final List<String> abbreviations;
  final String type;

  factory BookSuggestion.fromMap(Map<String, dynamic> map) {
    final rawAbbreviations = map['abbreviations'] ?? map['abbr'] ?? const [];
    final abbreviations = rawAbbreviations is List
        ? rawAbbreviations.map((item) => item.toString()).toList()
        : <String>[];

    return BookSuggestion(
      bookName:
          map['bookName']?.toString() ?? map['book_name']?.toString() ?? '',
      bookId: _parseInt(map['bookId'] ?? map['book_id']),
      abbreviations: abbreviations,
      type: map['type']?.toString() ?? '',
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
