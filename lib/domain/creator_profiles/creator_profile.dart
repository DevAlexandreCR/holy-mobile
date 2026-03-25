class CreatorProfile {
  const CreatorProfile({
    required this.id,
    required this.name,
    required this.handle,
    required this.bio,
    required this.avatarUrl,
    required this.followersCount,
    required this.followingCount,
    required this.followedByMe,
    required this.publishedDevotionalsCount,
  });

  final String id;
  final String name;
  final String? handle;
  final String? bio;
  final String? avatarUrl;
  final int followersCount;
  final int followingCount;
  final bool followedByMe;
  final int publishedDevotionalsCount;

  factory CreatorProfile.fromMap(Map<String, dynamic> map) {
    return CreatorProfile(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      handle: map['handle']?.toString(),
      bio: map['bio']?.toString(),
      avatarUrl: map['avatar_url']?.toString(),
      followersCount: (map['followers_count'] as num?)?.toInt() ?? 0,
      followingCount: (map['following_count'] as num?)?.toInt() ?? 0,
      followedByMe: map['followed_by_me'] == true,
      publishedDevotionalsCount:
          (map['published_devotionals_count'] as num?)?.toInt() ?? 0,
    );
  }

  CreatorProfile copyWith({
    String? handle,
    String? bio,
    String? avatarUrl,
    int? followersCount,
    int? followingCount,
    bool? followedByMe,
    int? publishedDevotionalsCount,
  }) {
    return CreatorProfile(
      id: id,
      name: name,
      handle: handle ?? this.handle,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      followedByMe: followedByMe ?? this.followedByMe,
      publishedDevotionalsCount:
          publishedDevotionalsCount ?? this.publishedDevotionalsCount,
    );
  }
}
