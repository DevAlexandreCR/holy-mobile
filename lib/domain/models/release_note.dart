class ReleaseNote {
  const ReleaseNote({
    required this.version,
    required this.changes,
    required this.releaseDate,
    required this.isImportant,
  });

  final String version;
  final List<String> changes;
  final DateTime releaseDate;
  final bool isImportant;

  factory ReleaseNote.fromMap(Map<String, dynamic> map) {
    final changes = map['changes'];
    return ReleaseNote(
      version: map['version']?.toString() ?? '',
      changes: changes is List
          ? changes.whereType<String>().toList()
          : const <String>[],
      releaseDate: DateTime.tryParse(map['releaseDate']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      isImportant: map['isImportant'] == true,
    );
  }
}
