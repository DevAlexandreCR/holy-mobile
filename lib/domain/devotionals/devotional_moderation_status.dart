enum DevotionalModerationStatus {
  clear('CLEAR'),
  underReview('UNDER_REVIEW'),
  restricted('RESTRICTED');

  const DevotionalModerationStatus(this.apiValue);

  final String apiValue;

  static DevotionalModerationStatus fromString(String value) {
    final normalized = value.toUpperCase();
    for (final status in DevotionalModerationStatus.values) {
      if (status.apiValue == normalized) return status;
    }
    return DevotionalModerationStatus.clear;
  }
}
