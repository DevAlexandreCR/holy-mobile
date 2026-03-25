class BibleBook {
  const BibleBook({
    required this.name,
    required this.abbrev,
    required this.chapters,
    required this.testament,
  });

  final String name;
  final String abbrev;
  final int chapters;
  final String testament;

  factory BibleBook.fromMap(Map<String, dynamic> map) {
    final names = map['names'];
    final primaryName =
        map['name']?.toString() ??
        (names is List && names.isNotEmpty ? names.first?.toString() : null) ??
        '';

    return BibleBook(
      name: primaryName,
      abbrev: map['abbrev']?.toString() ?? map['abrev']?.toString() ?? '',
      chapters: (map['chapters'] as num?)?.toInt() ?? 0,
      testament: map['testament']?.toString() ?? '',
    );
  }
}
