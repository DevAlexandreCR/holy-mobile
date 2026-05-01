import 'package:holyverso/domain/devotionals/devotional.dart';
import 'package:holyverso/presentation/screens/devotionals/devotional_feed_reader_args.dart';

enum DevotionalFeedReaderStatus { idle, loading, success, error }

class DevotionalFeedReaderState {
  static const _unset = Object();

  const DevotionalFeedReaderState({
    this.readerArgs,
    this.activeDevotionalId,
    this.activeIndex = 0,
    this.deviceId,
    this.status = DevotionalFeedReaderStatus.idle,
    this.loadedDevotionals = const {},
    this.readCompletedIds = const {},
    this.errorMessage,
    this.isTogglingLike = false,
    this.isTogglingSave = false,
    this.isReportingReadComplete = false,
    this.readCompleteJustSucceededId,
  });

  final DevotionalFeedReaderArgs? readerArgs;
  final String? activeDevotionalId;
  final int activeIndex;
  final String? deviceId;
  final DevotionalFeedReaderStatus status;
  final Map<String, Devotional> loadedDevotionals;
  final Set<String> readCompletedIds;
  final String? errorMessage;
  final bool isTogglingLike;
  final bool isTogglingSave;
  final bool isReportingReadComplete;
  final String? readCompleteJustSucceededId;

  Devotional? devotionalFor(String devotionalId) =>
      loadedDevotionals[devotionalId];

  Devotional? get activeDevotional {
    final activeDevotionalId = this.activeDevotionalId;
    if (activeDevotionalId == null) {
      return null;
    }
    return loadedDevotionals[activeDevotionalId];
  }

  bool hasReportedReadComplete(String devotionalId) {
    return readCompletedIds.contains(devotionalId);
  }

  DevotionalFeedReaderState copyWith({
    Object? readerArgs = _unset,
    Object? activeDevotionalId = _unset,
    int? activeIndex,
    Object? deviceId = _unset,
    DevotionalFeedReaderStatus? status,
    Map<String, Devotional>? loadedDevotionals,
    Set<String>? readCompletedIds,
    String? errorMessage,
    bool? isTogglingLike,
    bool? isTogglingSave,
    bool? isReportingReadComplete,
    Object? readCompleteJustSucceededId = _unset,
    bool clearError = false,
  }) {
    return DevotionalFeedReaderState(
      readerArgs: identical(readerArgs, _unset)
          ? this.readerArgs
          : readerArgs as DevotionalFeedReaderArgs?,
      activeDevotionalId: identical(activeDevotionalId, _unset)
          ? this.activeDevotionalId
          : activeDevotionalId as String?,
      activeIndex: activeIndex ?? this.activeIndex,
      deviceId: identical(deviceId, _unset)
          ? this.deviceId
          : deviceId as String?,
      status: status ?? this.status,
      loadedDevotionals: loadedDevotionals ?? this.loadedDevotionals,
      readCompletedIds: readCompletedIds ?? this.readCompletedIds,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      isTogglingLike: isTogglingLike ?? this.isTogglingLike,
      isTogglingSave: isTogglingSave ?? this.isTogglingSave,
      isReportingReadComplete:
          isReportingReadComplete ?? this.isReportingReadComplete,
      readCompleteJustSucceededId:
          identical(readCompleteJustSucceededId, _unset)
          ? this.readCompleteJustSucceededId
          : readCompleteJustSucceededId as String?,
    );
  }
}
