class BibleVersion {
  const BibleVersion({
    required this.id,
    required this.apiCode,
    required this.name,
    required this.language,
  });

  final int id;
  final String apiCode;
  final String name;
  final String language;

  factory BibleVersion.fromMap(Map<String, dynamic> map) {
    return BibleVersion(
      id: _parseId(map['id']),
      apiCode: map['api_code']?.toString() ?? map['apiCode']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      language: map['language']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'api_code': apiCode,
      'name': name,
      'language': language,
    };
  }

  static int _parseId(Object? value) {
    return switch (value) {
      int v => v,
      String v => int.tryParse(v) ?? 0,
      _ => 0,
    };
  }
}
