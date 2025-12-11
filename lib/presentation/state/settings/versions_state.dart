import 'package:holy_mobile/data/bible/models/bible_version.dart';

class VersionsState {
  const VersionsState({
    this.versions = const [],
    this.isLoading = false,
    this.hasLoaded = false,
    this.errorMessage,
  });

  final List<BibleVersion> versions;
  final bool isLoading;
  final bool hasLoaded;
  final String? errorMessage;

  bool get hasError => errorMessage != null;

  VersionsState copyWith({
    List<BibleVersion>? versions,
    bool? isLoading,
    bool? hasLoaded,
    String? errorMessage,
    bool clearError = false,
  }) {
    return VersionsState(
      versions: versions ?? this.versions,
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
