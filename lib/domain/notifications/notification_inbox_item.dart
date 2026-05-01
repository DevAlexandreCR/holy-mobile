enum NotificationInboxType {
  devotionalLike,
  devotionalComment,
  devotionalShare,
  newFollower;

  static NotificationInboxType fromApi(String? value) {
    return switch (value) {
      'DEVOTIONAL_COMMENT' => NotificationInboxType.devotionalComment,
      'DEVOTIONAL_SHARE' => NotificationInboxType.devotionalShare,
      'NEW_FOLLOWER' => NotificationInboxType.newFollower,
      _ => NotificationInboxType.devotionalLike,
    };
  }
}

enum NotificationInboxDestinationType { devotional, creatorProfile }

enum NotificationInboxFilter {
  all('all'),
  unread('unread');

  const NotificationInboxFilter(this.queryValue);

  final String queryValue;
}

class NotificationInboxActorPreview {
  const NotificationInboxActorPreview({
    required this.id,
    required this.name,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String? avatarUrl;

  factory NotificationInboxActorPreview.fromMap(Map<String, dynamic> map) {
    return NotificationInboxActorPreview(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      avatarUrl: map['avatar_url']?.toString(),
    );
  }
}

class NotificationInboxDevotionalSummary {
  const NotificationInboxDevotionalSummary({
    required this.id,
    required this.title,
    this.imageUrl,
  });

  final String id;
  final String title;
  final String? imageUrl;

  factory NotificationInboxDevotionalSummary.fromMap(
    Map<String, dynamic> map,
  ) {
    return NotificationInboxDevotionalSummary(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      imageUrl: map['image_url']?.toString(),
    );
  }
}

class NotificationInboxCreatorSummary {
  const NotificationInboxCreatorSummary({
    required this.id,
    required this.name,
    this.handle,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String? handle;
  final String? avatarUrl;

  factory NotificationInboxCreatorSummary.fromMap(Map<String, dynamic> map) {
    return NotificationInboxCreatorSummary(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      handle: map['handle']?.toString(),
      avatarUrl: map['avatar_url']?.toString(),
    );
  }
}

class NotificationInboxDestination {
  const NotificationInboxDestination({
    required this.type,
    this.devotionalId,
    this.creatorId,
  });

  final NotificationInboxDestinationType type;
  final String? devotionalId;
  final String? creatorId;

  factory NotificationInboxDestination.fromMap(Map<String, dynamic> map) {
    return NotificationInboxDestination(
      type: map['type'] == 'creator_profile'
          ? NotificationInboxDestinationType.creatorProfile
          : NotificationInboxDestinationType.devotional,
      devotionalId: map['devotional_id']?.toString(),
      creatorId: map['creator_id']?.toString(),
    );
  }
}

class NotificationInboxItem {
  const NotificationInboxItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.aggregateCount,
    required this.actorPreview,
    required this.isRead,
    required this.createdAt,
    this.imageUrl,
    this.devotional,
    this.creator,
    this.destination,
    this.readAt,
    this.openedAt,
  });

  final String id;
  final NotificationInboxType type;
  final String title;
  final String body;
  final String? imageUrl;
  final int aggregateCount;
  final List<NotificationInboxActorPreview> actorPreview;
  final NotificationInboxDevotionalSummary? devotional;
  final NotificationInboxCreatorSummary? creator;
  final NotificationInboxDestination? destination;
  final bool isRead;
  final DateTime? readAt;
  final DateTime? openedAt;
  final DateTime createdAt;

  factory NotificationInboxItem.fromMap(Map<String, dynamic> map) {
    final actorPreview = (map['actor_preview'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) => NotificationInboxActorPreview.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();

    final devotionalMap = map['devotional'] as Map?;
    final creatorMap = map['creator'] as Map?;
    final destinationMap = map['destination'] as Map?;

    return NotificationInboxItem(
      id: map['id']?.toString() ?? '',
      type: NotificationInboxType.fromApi(map['type']?.toString()),
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      imageUrl: map['image_url']?.toString(),
      aggregateCount: (map['aggregate_count'] as num?)?.toInt() ?? 1,
      actorPreview: actorPreview,
      devotional: devotionalMap == null
          ? null
          : NotificationInboxDevotionalSummary.fromMap(
              Map<String, dynamic>.from(devotionalMap),
            ),
      creator: creatorMap == null
          ? null
          : NotificationInboxCreatorSummary.fromMap(
              Map<String, dynamic>.from(creatorMap),
            ),
      destination: destinationMap == null
          ? null
          : NotificationInboxDestination.fromMap(
              Map<String, dynamic>.from(destinationMap),
            ),
      isRead: map['is_read'] == true,
      readAt: DateTime.tryParse(map['read_at']?.toString() ?? ''),
      openedAt: DateTime.tryParse(map['opened_at']?.toString() ?? ''),
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  NotificationInboxItem copyWith({
    bool? isRead,
    DateTime? readAt,
    DateTime? openedAt,
  }) {
    return NotificationInboxItem(
      id: id,
      type: type,
      title: title,
      body: body,
      imageUrl: imageUrl,
      aggregateCount: aggregateCount,
      actorPreview: actorPreview,
      devotional: devotional,
      creator: creator,
      destination: destination,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      openedAt: openedAt ?? this.openedAt,
      createdAt: createdAt,
    );
  }
}
