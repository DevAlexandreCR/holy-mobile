enum DevotionalPublishFailureReason { needsMoreReflection }

class DevotionalPublishReadiness {
  const DevotionalPublishReadiness({
    required this.isReady,
    required this.wordCount,
    required this.sentenceCount,
    required this.meaningfulParagraphCount,
    required this.plainTextLength,
    required this.reason,
  });

  final bool isReady;
  final int wordCount;
  final int sentenceCount;
  final int meaningfulParagraphCount;
  final int plainTextLength;
  final DevotionalPublishFailureReason? reason;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DevotionalPublishReadiness &&
        other.isReady == isReady &&
        other.wordCount == wordCount &&
        other.sentenceCount == sentenceCount &&
        other.meaningfulParagraphCount == meaningfulParagraphCount &&
        other.plainTextLength == plainTextLength &&
        other.reason == reason;
  }

  @override
  int get hashCode => Object.hash(
    isReady,
    wordCount,
    sentenceCount,
    meaningfulParagraphCount,
    plainTextLength,
    reason,
  );
}

class DevotionalPublishValidator {
  const DevotionalPublishValidator._();

  static const minimumPlainTextLength = 220;
  static const minimumWordCount = 45;
  static const minimumSentenceCount = 3;
  static const minimumMeaningfulParagraphCount = 2;
  static const minimumMeaningfulParagraphLength = 60;

  static DevotionalPublishReadiness evaluatePlainText(String plainText) {
    final normalizedPlainText = _normalizePlainText(plainText);
    final collapsedText = _collapseWhitespace(normalizedPlainText);
    final words = collapsedText.isEmpty
        ? const <String>[]
        : collapsedText
              .split(RegExp(r'\s+'))
              .where((word) => word.isNotEmpty)
              .toList();
    final sentenceCount = _extractSentenceCandidates(collapsedText).length;
    final meaningfulParagraphCount = normalizedPlainText
        .split(RegExp(r'\n{2,}'))
        .map(_collapseWhitespace)
        .where(
          (paragraph) => paragraph.length >= minimumMeaningfulParagraphLength,
        )
        .length;

    final hasEnoughReflection =
        collapsedText.length >= minimumPlainTextLength &&
        words.length >= minimumWordCount &&
        (sentenceCount >= minimumSentenceCount ||
            meaningfulParagraphCount >= minimumMeaningfulParagraphCount);

    return DevotionalPublishReadiness(
      isReady: hasEnoughReflection,
      wordCount: words.length,
      sentenceCount: sentenceCount,
      meaningfulParagraphCount: meaningfulParagraphCount,
      plainTextLength: collapsedText.length,
      reason: hasEnoughReflection
          ? null
          : DevotionalPublishFailureReason.needsMoreReflection,
    );
  }

  static String _normalizePlainText(String value) {
    return value
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(RegExp(r'[ \t]+\n'), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  static List<String> _extractSentenceCandidates(String plainText) {
    final normalized = plainText
        .replaceAll(RegExp(r'\n{2,}'), '. ')
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (normalized.isEmpty) {
      return const [];
    }

    return normalized
        .split(RegExp(r'(?<=[.!?…])\s+', unicode: true))
        .map((sentence) => sentence.trim())
        .where((sentence) => sentence.isNotEmpty)
        .toList();
  }

  static String _collapseWhitespace(String value) =>
      value.replaceAll(RegExp(r'\s+'), ' ').trim();
}
