import 'package:holyverso/domain/verse/chapter.dart';

const double kChapterTextScaleMin = 0.9;
const double kChapterTextScaleMax = 1.5;

enum ChapterReaderStatus { idle, loading, success, error }

class ChapterHighlightRange {
  const ChapterHighlightRange({required this.start, required this.end});

  final int start;
  final int end;

  bool contains(int verseNumber) {
    return verseNumber >= start && verseNumber <= end;
  }
}

class ChapterReaderState {
  const ChapterReaderState({
    this.chapter,
    this.status = ChapterReaderStatus.idle,
    this.errorMessage,
    this.highlightRange,
    this.textScale = 1.0,
  });

  final Chapter? chapter;
  final ChapterReaderStatus status;
  final String? errorMessage;
  final ChapterHighlightRange? highlightRange;
  final double textScale;

  bool get isLoading => status == ChapterReaderStatus.loading;
  bool get hasError => status == ChapterReaderStatus.error;

  ChapterReaderState copyWith({
    Chapter? chapter,
    ChapterReaderStatus? status,
    String? errorMessage,
    bool clearError = false,
    ChapterHighlightRange? highlightRange,
    double? textScale,
  }) {
    return ChapterReaderState(
      chapter: chapter ?? this.chapter,
      status: status ?? this.status,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      highlightRange: highlightRange ?? this.highlightRange,
      textScale: textScale ?? this.textScale,
    );
  }
}
