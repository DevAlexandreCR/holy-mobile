class ReferenceParser {
  const ReferenceParser._();

  static ({int start, int end})? parseHighlightRange(String reference) {
    final parts = reference.split(':');
    if (parts.length < 2) return null;

    final versePart = parts.last.split('-');
    final start =
        int.tryParse(versePart.first.replaceAll(RegExp(r'[^0-9]'), ''));
    if (start == null) return null;

    final end = versePart.length > 1
        ? int.tryParse(versePart[1].replaceAll(RegExp(r'[^0-9]'), '')) ?? start
        : start;

    return (start: start, end: end);
  }

  static ({String book, int chapter})? parseBookAndChapter(String reference) {
    final match = RegExp(r'^(.+?)\\s+(\\d+):').firstMatch(reference.trim());
    if (match == null) return null;

    final book = match.group(1)?.trim();
    final chapter = int.tryParse(match.group(2) ?? '');

    if (book == null || book.isEmpty || chapter == null) return null;
    return (book: book, chapter: chapter);
  }
}
