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
  });

  final int? preferredVersionId;
  final String? timezone;
  final WidgetFontSize widgetFontSize;

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
    );
  }
}
