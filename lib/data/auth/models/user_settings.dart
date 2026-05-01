enum WidgetFontSize {
  small(12),
  medium(14),
  large(16),
  extraLarge(18);

  const WidgetFontSize(this.size);
  final double size;

  static WidgetFontSize fromString(String? value) {
    return switch (value?.toLowerCase()) {
      'small' => WidgetFontSize.small,
      'medium' => WidgetFontSize.medium,
      'large' => WidgetFontSize.large,
      'extra_large' || 'extralarge' => WidgetFontSize.extraLarge,
      _ => WidgetFontSize.large, // default
    };
  }

  String toApiString() {
    return switch (this) {
      WidgetFontSize.small => 'small',
      WidgetFontSize.medium => 'medium',
      WidgetFontSize.large => 'large',
      WidgetFontSize.extraLarge => 'extra_large',
    };
  }
}

class UserSettings {
  const UserSettings({
    this.preferredVersionId,
    this.timezone,
    this.widgetFontSize = WidgetFontSize.large,
    this.devotionalNotificationsEnabled = true,
    this.followedCreatorNotificationsEnabled = true,
    this.featuredDevotionalNotificationsEnabled = true,
    this.streakRiskNotificationsEnabled = true,
    this.authorModerationNotificationsEnabled = true,
    this.editorReviewNotificationsEnabled = true,
    this.socialActivityNotificationsEnabled = true,
    this.commentNotificationsEnabled = true,
    this.followNotificationsEnabled = true,
    this.reactionNotificationsEnabled = true,
  });

  final int? preferredVersionId;
  final String? timezone;
  final WidgetFontSize widgetFontSize;
  final bool devotionalNotificationsEnabled;
  final bool followedCreatorNotificationsEnabled;
  final bool featuredDevotionalNotificationsEnabled;
  final bool streakRiskNotificationsEnabled;
  final bool authorModerationNotificationsEnabled;
  final bool editorReviewNotificationsEnabled;
  final bool socialActivityNotificationsEnabled;
  final bool commentNotificationsEnabled;
  final bool followNotificationsEnabled;
  final bool reactionNotificationsEnabled;

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    final rawPreferred =
        map['preferred_version_id'] ?? map['preferredVersionId'];
    final preferredId = switch (rawPreferred) {
      int value => value,
      String value => int.tryParse(value),
      _ => null,
    };

    return UserSettings(
      preferredVersionId: preferredId,
      timezone: map['timezone'] as String?,
      widgetFontSize: WidgetFontSize.fromString(
        map['widget_font_size'] as String?,
      ),
      devotionalNotificationsEnabled:
          map['devotional_notifications_enabled'] as bool? ?? true,
      followedCreatorNotificationsEnabled:
          map['followed_creator_notifications_enabled'] as bool? ?? true,
      featuredDevotionalNotificationsEnabled:
          map['featured_devotional_notifications_enabled'] as bool? ?? true,
      streakRiskNotificationsEnabled:
          map['streak_risk_notifications_enabled'] as bool? ?? true,
      authorModerationNotificationsEnabled:
          map['author_moderation_notifications_enabled'] as bool? ?? true,
      editorReviewNotificationsEnabled:
          map['editor_review_notifications_enabled'] as bool? ?? true,
      socialActivityNotificationsEnabled:
          map['social_activity_notifications_enabled'] as bool? ?? true,
      commentNotificationsEnabled:
          map['comment_notifications_enabled'] as bool? ?? true,
      followNotificationsEnabled:
          map['follow_notifications_enabled'] as bool? ?? true,
      reactionNotificationsEnabled:
          map['reaction_notifications_enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'preferred_version_id': preferredVersionId,
      'timezone': timezone,
      'widget_font_size': widgetFontSize.toApiString(),
      'devotional_notifications_enabled': devotionalNotificationsEnabled,
      'followed_creator_notifications_enabled':
          followedCreatorNotificationsEnabled,
      'featured_devotional_notifications_enabled':
          featuredDevotionalNotificationsEnabled,
      'streak_risk_notifications_enabled': streakRiskNotificationsEnabled,
      'author_moderation_notifications_enabled':
          authorModerationNotificationsEnabled,
      'editor_review_notifications_enabled': editorReviewNotificationsEnabled,
      'social_activity_notifications_enabled':
          socialActivityNotificationsEnabled,
      'comment_notifications_enabled': commentNotificationsEnabled,
      'follow_notifications_enabled': followNotificationsEnabled,
      'reaction_notifications_enabled': reactionNotificationsEnabled,
    };
  }
}
