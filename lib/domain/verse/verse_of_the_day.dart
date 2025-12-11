class VerseOfTheDay {
  const VerseOfTheDay({
    required this.date,
    required this.versionCode,
    required this.versionName,
    required this.reference,
    required this.text,
  });

  final String date;
  final String versionCode;
  final String versionName;
  final String reference;
  final String text;

  String get displayVersionCode => versionCode.toUpperCase();

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'version_code': versionCode,
      'version_name': versionName,
      'reference': reference,
      'text': text,
    };
  }

  factory VerseOfTheDay.fromMap(Map<String, dynamic> map) {
    return VerseOfTheDay(
      date: map['date'] as String? ?? '',
      versionCode: map['version_code'] as String? ?? map['versionCode'] as String? ?? '',
      versionName: map['version_name'] as String? ?? map['versionName'] as String? ?? '',
      reference: map['reference'] as String? ?? '',
      text: map['text'] as String? ?? '',
    );
  }
}
