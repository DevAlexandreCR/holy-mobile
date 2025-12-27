class SavedVerse {
  const SavedVerse({
    required this.id,
    required this.libraryVerseId,
    required this.reference,
    required this.text,
    required this.versionCode,
    required this.versionName,
    required this.theme,
    required this.savedAt,
  });

  final int id;
  final int libraryVerseId;
  final String reference;
  final String text;
  final String versionCode;
  final String versionName;
  final String theme;
  final DateTime savedAt;

  String get displayVersionCode => versionCode.toUpperCase();

  factory SavedVerse.fromMap(Map<String, dynamic> map) {
    final savedAtRaw = map['saved_at'] ??
        map['savedAt'] ??
        map['savedAtUtc'] ??
        map['saved'] ??
        '';

    return SavedVerse(
      id: (map['id'] as num?)?.toInt() ?? 0,
      libraryVerseId:
          (map['library_verse_id'] as num?)?.toInt() ??
          (map['libraryVerseId'] as num?)?.toInt() ??
          0,
      reference: map['reference'] as String? ?? '',
      text: map['text'] as String? ?? '',
      versionCode:
          map['version_code'] as String? ?? map['versionCode'] as String? ?? '',
      versionName:
          map['version_name'] as String? ?? map['versionName'] as String? ?? '',
      theme: map['theme'] as String? ?? '',
      savedAt: DateTime.tryParse(savedAtRaw.toString()) ?? DateTime.now(),
    );
  }
}
