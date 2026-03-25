class DevotionalAuthor {
  const DevotionalAuthor({
    required this.id,
    required this.name,
    this.handle,
    this.avatarUrl,
    this.following = false,
  });

  final String id;
  final String name;
  final String? handle;
  final String? avatarUrl;
  final bool following;

  factory DevotionalAuthor.fromMap(Map<String, dynamic> map) {
    final relationship = map['author_relationship'] as Map?;
    return DevotionalAuthor(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      handle: map['handle']?.toString(),
      avatarUrl: map['avatar_url']?.toString(),
      following: map['following'] == true || relationship?['following'] == true,
    );
  }

  DevotionalAuthor copyWith({
    String? handle,
    String? avatarUrl,
    bool? following,
  }) {
    return DevotionalAuthor(
      id: id,
      name: name,
      handle: handle ?? this.handle,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      following: following ?? this.following,
    );
  }
}
