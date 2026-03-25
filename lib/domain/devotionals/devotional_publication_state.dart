enum DevotionalPublicationState {
  draft('DRAFT'),
  publishedLowReach('PUBLISHED_LOW_REACH'),
  trending('TRENDING'),
  featured('FEATURED'),
  archived('ARCHIVED');

  const DevotionalPublicationState(this.apiValue);

  final String apiValue;

  static DevotionalPublicationState fromString(String value) {
    final normalized = value.toUpperCase();
    for (final state in DevotionalPublicationState.values) {
      if (state.apiValue == normalized) return state;
    }
    return DevotionalPublicationState.draft;
  }
}
