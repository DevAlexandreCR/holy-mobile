enum DevotionalStatus {
  draft('DRAFT'),
  published('PUBLISHED'),
  archived('ARCHIVED');

  final String apiValue;

  const DevotionalStatus(this.apiValue);

  static DevotionalStatus fromString(String value) {
    final normalized = value.toUpperCase();
    for (final status in DevotionalStatus.values) {
      if (status.apiValue == normalized) return status;
    }
    return DevotionalStatus.draft;
  }
}
