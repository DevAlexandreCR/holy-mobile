import 'package:holyverso/domain/verse/verse_of_the_day.dart';

class VerseState {
  const VerseState({
    this.verse,
    this.isLoading = false,
    this.errorMessage,
  });

  final VerseOfTheDay? verse;
  final bool isLoading;
  final String? errorMessage;

  bool get hasError => errorMessage != null;

  VerseState copyWith({
    VerseOfTheDay? verse,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return VerseState(
      verse: verse ?? this.verse,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
