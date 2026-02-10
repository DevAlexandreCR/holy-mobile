class DevotionalAuthor {
  const DevotionalAuthor({required this.id, required this.name});

  final String id;
  final String name;

  factory DevotionalAuthor.fromMap(Map<String, dynamic> map) {
    return DevotionalAuthor(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
    );
  }
}
