class VerseOfTheDay {
  const VerseOfTheDay({
    required this.date,
    required this.versionCode,
    required this.versionName,
    required this.reference,
    required this.text,
    this.libraryVerseId,
    this.isSaved = false,
    this.theme,
  });

  final String date;
  final String versionCode;
  final String versionName;
  final String reference;
  final String text;
  final int? libraryVerseId;
  final bool isSaved;
  final String? theme;

  String get displayVersionCode => versionCode.toUpperCase();

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'version_code': versionCode,
      'version_name': versionName,
      'reference': reference,
      'text': text,
      if (libraryVerseId != null) 'library_verse_id': libraryVerseId,
      'is_saved': isSaved,
      if (theme != null) 'theme': theme,
    };
  }

  factory VerseOfTheDay.fromMap(Map<String, dynamic> map) {
    return VerseOfTheDay(
      date: map['date'] as String? ?? '',
      versionCode:
          map['version_code'] as String? ?? map['versionCode'] as String? ?? '',
      versionName:
          map['version_name'] as String? ?? map['versionName'] as String? ?? '',
      reference: map['reference'] as String? ?? '',
      text: map['text'] as String? ?? '',
      libraryVerseId:
          map['library_verse_id'] as int? ?? map['libraryVerseId'] as int?,
      isSaved: map['is_saved'] as bool? ??
          map['isSaved'] as bool? ??
          false,
      theme: map['theme'] as String?,
    );
  }

  VerseOfTheDay copyWith({
    String? date,
    String? versionCode,
    String? versionName,
    String? reference,
    String? text,
    int? libraryVerseId,
    bool? isSaved,
    String? theme,
  }) {
    return VerseOfTheDay(
      date: date ?? this.date,
      versionCode: versionCode ?? this.versionCode,
      versionName: versionName ?? this.versionName,
      reference: reference ?? this.reference,
      text: text ?? this.text,
      libraryVerseId: libraryVerseId ?? this.libraryVerseId,
      isSaved: isSaved ?? this.isSaved,
      theme: theme ?? this.theme,
    );
  }
}
