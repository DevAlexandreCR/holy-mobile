import 'package:holyverso/domain/devotionals/devotional.dart';
import 'package:holyverso/domain/devotionals/devotional_feed_header.dart';

enum DevotionalsFeedStatus { idle, loading, success, error }

class DevotionalsFeedState {
  static const _unset = Object();

  const DevotionalsFeedState({
    this.items = const [],
    this.status = DevotionalsFeedStatus.idle,
    this.errorMessage,
    this.nextCursor,
    this.feedHeader,
    this.ownerUserId,
    this.hasMore = true,
    this.isFetchingMore = false,
    this.likingDevotionalId,
    this.savingDevotionalId,
  });

  final List<Devotional> items;
  final DevotionalsFeedStatus status;
  final String? errorMessage;
  final String? nextCursor;
  final DevotionalFeedHeader? feedHeader;
  final String? ownerUserId;
  final bool hasMore;
  final bool isFetchingMore;
  final String? likingDevotionalId;
  final String? savingDevotionalId;

  DevotionalsFeedState copyWith({
    List<Devotional>? items,
    DevotionalsFeedStatus? status,
    String? errorMessage,
    String? nextCursor,
    Object? feedHeader = _unset,
    Object? ownerUserId = _unset,
    bool? hasMore,
    bool? isFetchingMore,
    String? likingDevotionalId,
    String? savingDevotionalId,
    bool clearError = false,
    bool clearNextCursor = false,
    bool clearLikingDevotionalId = false,
    bool clearSavingDevotionalId = false,
  }) {
    return DevotionalsFeedState(
      items: items ?? this.items,
      status: status ?? this.status,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      nextCursor: clearNextCursor ? null : nextCursor ?? this.nextCursor,
      feedHeader: identical(feedHeader, _unset)
          ? this.feedHeader
          : feedHeader as DevotionalFeedHeader?,
      ownerUserId: identical(ownerUserId, _unset)
          ? this.ownerUserId
          : ownerUserId as String?,
      hasMore: hasMore ?? this.hasMore,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      likingDevotionalId: clearLikingDevotionalId
          ? null
          : likingDevotionalId ?? this.likingDevotionalId,
      savingDevotionalId: clearSavingDevotionalId
          ? null
          : savingDevotionalId ?? this.savingDevotionalId,
    );
  }
}
