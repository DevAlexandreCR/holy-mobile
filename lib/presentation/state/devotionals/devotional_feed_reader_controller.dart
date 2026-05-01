import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/core/errors/app_error_mapper.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/data/devotionals/devotionals_repository.dart';
import 'package:holyverso/domain/devotionals/devotional.dart';
import 'package:holyverso/domain/devotionals/devotional_feed_mode.dart';
import 'package:holyverso/presentation/screens/devotionals/devotional_feed_reader_args.dart';
import 'package:holyverso/presentation/state/devotionals/devotional_feed_reader_state.dart';
import 'package:holyverso/presentation/state/devotionals/devotionals_feed_controller.dart';
import 'package:holyverso/presentation/state/devotionals/devotionals_feed_state.dart';
import 'package:holyverso/presentation/state/devotionals/saved_devotionals_controller.dart';

NotifierProvider<BaseDevotionalsFeedController, DevotionalsFeedState>
devotionalFeedProviderForMode(DevotionalFeedMode mode) {
  return switch (mode) {
    DevotionalFeedMode.forYou => forYouFeedControllerProvider,
    DevotionalFeedMode.following => followingFeedControllerProvider,
  };
}

class DevotionalFeedReaderController
    extends Notifier<DevotionalFeedReaderState> {
  late final DevotionalsRepository _repository;
  static const _l10n = AppLocalizations(Locale('es'));

  @override
  DevotionalFeedReaderState build() {
    _repository = ref.read(devotionalsRepositoryProvider);
    return const DevotionalFeedReaderState();
  }

  Future<void> configure({
    DevotionalFeedReaderArgs? readerArgs,
    required String devotionalId,
    String? deliveryToken,
    required String deviceId,
  }) async {
    final feedIndex = _indexFor(devotionalId, readerArgs: readerArgs);
    state = state.copyWith(
      readerArgs: readerArgs,
      activeDevotionalId: devotionalId,
      activeIndex: feedIndex >= 0 ? feedIndex : 0,
      deviceId: deviceId,
      status: DevotionalFeedReaderStatus.loading,
      clearError: true,
    );

    if (readerArgs != null) {
      _syncFeedSnapshot(devotionalId);
      await _registerOpen(devotionalId, readerArgs: readerArgs);
    }

    await _loadDevotional(devotionalId);
  }

  Future<void> activateIndex(int index) async {
    final readerArgs = state.readerArgs;
    if (readerArgs == null) {
      return;
    }

    final feedItems = _feedItems(readerArgs.feedMode);
    if (index < 0 || index >= feedItems.length) {
      return;
    }

    final devotionalId = feedItems[index].id;
    state = state.copyWith(
      activeIndex: index,
      activeDevotionalId: devotionalId,
      status: state.devotionalFor(devotionalId) == null
          ? DevotionalFeedReaderStatus.loading
          : DevotionalFeedReaderStatus.success,
      clearError: true,
    );

    await _registerOpen(devotionalId, readerArgs: readerArgs);

    if (state.devotionalFor(devotionalId) == null) {
      await _loadDevotional(devotionalId);
    }
  }

  Future<int?> resolveNextIndex() async {
    final readerArgs = state.readerArgs;
    if (readerArgs == null) {
      return null;
    }

    final provider = devotionalFeedProviderForMode(readerArgs.feedMode);
    final feedState = ref.read(provider);
    final nextIndex = state.activeIndex + 1;
    if (nextIndex < feedState.items.length) {
      return nextIndex;
    }

    if (!feedState.hasMore) {
      return null;
    }

    await ref.read(provider.notifier).loadMore();
    final updatedItems = ref.read(provider).items;
    if (nextIndex < updatedItems.length) {
      return nextIndex;
    }
    return null;
  }

  int? resolvePreviousIndex() {
    final readerArgs = state.readerArgs;
    if (readerArgs == null) {
      return null;
    }

    final previousIndex = state.activeIndex - 1;
    if (previousIndex < 0) {
      return null;
    }

    final feedItems = _feedItems(readerArgs.feedMode);
    if (previousIndex >= feedItems.length) {
      return null;
    }

    return previousIndex;
  }

  Future<void> reloadActive() async {
    final devotionalId = state.activeDevotionalId;
    if (devotionalId == null) {
      return;
    }
    state = state.copyWith(
      status: DevotionalFeedReaderStatus.loading,
      clearError: true,
    );
    await _loadDevotional(devotionalId);
  }

  Future<void> toggleLike() async {
    final devotional = state.activeDevotional;
    if (devotional == null || state.isTogglingLike) {
      return;
    }

    state = state.copyWith(isTogglingLike: true, clearError: true);
    try {
      final result = await _repository.toggleLike(devotional.id);
      _updateCachedDevotional(
        devotional.copyWith(likesCount: result.likesCount, liked: result.liked),
      );
    } catch (error) {
      state = state.copyWith(errorMessage: _mapError(error));
    } finally {
      state = state.copyWith(isTogglingLike: false);
    }
  }

  Future<void> toggleSave() async {
    final devotional = state.activeDevotional;
    if (devotional == null || state.isTogglingSave) {
      return;
    }

    state = state.copyWith(isTogglingSave: true, clearError: true);
    try {
      final deliveryToken = _deliveryTokenFor(devotional.id);
      final result = devotional.saved
          ? await _repository.unsaveDevotional(devotional.id)
          : await _repository.saveDevotional(
              devotional.id,
              deliveryToken: deliveryToken,
            );
      final updatedDevotional = devotional.copyWith(
        saveCount: result.saveCount,
        saved: result.saved,
      );
      _updateCachedDevotional(updatedDevotional);
      ref
          .read(savedDevotionalsControllerProvider.notifier)
          .syncSavedDevotional(updatedDevotional);
    } catch (error) {
      state = state.copyWith(errorMessage: _mapError(error));
    } finally {
      state = state.copyWith(isTogglingSave: false);
    }
  }

  Future<void> registerShare({int? shareCount}) async {
    final devotional = state.activeDevotional;
    if (devotional == null) {
      return;
    }

    if (shareCount != null) {
      final updatedDevotional = devotional.copyWith(shareCount: shareCount);
      _updateCachedDevotional(updatedDevotional);
      ref
          .read(savedDevotionalsControllerProvider.notifier)
          .syncSavedDevotional(updatedDevotional);
      return;
    }

    try {
      final result = await _repository.shareDevotional(
        devotional.id,
        deliveryToken: _deliveryTokenFor(devotional.id),
      );
      final updatedDevotional = devotional.copyWith(
        shareCount: result.shareCount,
      );
      _updateCachedDevotional(updatedDevotional);
      ref
          .read(savedDevotionalsControllerProvider.notifier)
          .syncSavedDevotional(updatedDevotional);
    } catch (_) {}
  }

  Future<bool> report({required String reason, String? details}) async {
    final devotional = state.activeDevotional;
    if (devotional == null) {
      return false;
    }

    try {
      await _repository.reportDevotional(
        devotionalId: devotional.id,
        reason: reason,
        details: details,
        deliveryToken: _deliveryTokenFor(devotional.id),
      );
      return true;
    } catch (error) {
      state = state.copyWith(errorMessage: _mapError(error));
      return false;
    }
  }

  Future<void> reportReadComplete() async {
    final devotional = state.activeDevotional;
    if (devotional == null ||
        state.isReportingReadComplete ||
        state.hasReportedReadComplete(devotional.id)) {
      return;
    }

    if (!devotional.isPubliclyVisible) {
      state = state.copyWith(
        readCompletedIds: {...state.readCompletedIds, devotional.id},
      );
      return;
    }

    state = state.copyWith(
      isReportingReadComplete: true,
      readCompleteJustSucceededId: null,
    );

    try {
      final count = await _repository.markReadComplete(
        devotional.id,
        deliveryToken: _deliveryTokenFor(devotional.id),
        deviceId: state.deviceId,
      );
      _updateCachedDevotional(
        devotional.copyWith(readCompleteCount: count),
        readCompletedIds: {...state.readCompletedIds, devotional.id},
        readCompleteJustSucceededId: devotional.id,
      );
    } catch (error) {
      final shouldStopRetrying =
          AppErrorMapper.backendCode(error) == 'DEVOTIONAL_NOT_PUBLIC';
      if (shouldStopRetrying) {
        state = state.copyWith(
          readCompletedIds: {...state.readCompletedIds, devotional.id},
        );
      }
    } finally {
      state = state.copyWith(isReportingReadComplete: false);
    }
  }

  void acknowledgeReadComplete() {
    state = state.copyWith(readCompleteJustSucceededId: null);
  }

  void syncCommentCount(int count) {
    final devotional = state.activeDevotional;
    if (devotional == null) {
      return;
    }
    _updateCachedDevotional(devotional.copyWith(commentsCount: count));
  }

  void syncCreatorProfile({
    required String creatorId,
    required bool following,
    String? handle,
    String? avatarUrl,
    bool syncFeed = true,
  }) {
    if (state.loadedDevotionals.isEmpty) {
      if (syncFeed) {
        final readerArgs = state.readerArgs;
        if (readerArgs != null) {
          ref
              .read(devotionalFeedProviderForMode(readerArgs.feedMode).notifier)
              .syncCreatorProfile(
                creatorId: creatorId,
                following: following,
                handle: handle,
                avatarUrl: avatarUrl,
              );
        }
      }
      return;
    }

    final updatedDevotionals = <String, Devotional>{
      for (final entry in state.loadedDevotionals.entries)
        entry.key: entry.value.author.id == creatorId
            ? entry.value.copyWith(
                author: entry.value.author.copyWith(
                  following: following,
                  handle: handle ?? entry.value.author.handle,
                  avatarUrl: avatarUrl ?? entry.value.author.avatarUrl,
                ),
              )
            : entry.value,
    };

    state = state.copyWith(loadedDevotionals: updatedDevotionals);

    if (!syncFeed) {
      return;
    }

    final readerArgs = state.readerArgs;
    if (readerArgs == null) {
      return;
    }

    ref
        .read(devotionalFeedProviderForMode(readerArgs.feedMode).notifier)
        .syncCreatorProfile(
          creatorId: creatorId,
          following: following,
          handle: handle,
          avatarUrl: avatarUrl,
        );
  }

  Devotional? feedSnapshotFor(String devotionalId) {
    final readerArgs = state.readerArgs;
    if (readerArgs == null) {
      return null;
    }
    final items = _feedItems(readerArgs.feedMode);
    for (final item in items) {
      if (item.id == devotionalId) {
        return item;
      }
    }
    return null;
  }

  Future<void> _loadDevotional(String devotionalId) async {
    try {
      final devotional = await _repository.getDevotional(
        devotionalId,
        deviceId: state.deviceId,
      );
      if (state.activeDevotionalId != devotionalId) {
        return;
      }
      _updateCachedDevotional(
        _mergeFeedSnapshot(devotional),
        status: DevotionalFeedReaderStatus.success,
      );
    } catch (error) {
      if (state.activeDevotionalId != devotionalId) {
        return;
      }
      state = state.copyWith(
        status: DevotionalFeedReaderStatus.error,
        errorMessage: _mapError(error),
      );
    }
  }

  Future<void> _registerOpen(
    String devotionalId, {
    required DevotionalFeedReaderArgs readerArgs,
  }) async {
    final feedDevotional = feedSnapshotFor(devotionalId);
    if (feedDevotional == null) {
      return;
    }
    await ref
        .read(devotionalFeedProviderForMode(readerArgs.feedMode).notifier)
        .registerOpen(feedDevotional);
  }

  void _updateCachedDevotional(
    Devotional devotional, {
    DevotionalFeedReaderStatus? status,
    Set<String>? readCompletedIds,
    String? readCompleteJustSucceededId,
  }) {
    final updatedDevotionals = Map<String, Devotional>.from(
      state.loadedDevotionals,
    );
    updatedDevotionals[devotional.id] = devotional;
    state = state.copyWith(
      loadedDevotionals: updatedDevotionals,
      status: status ?? state.status,
      readCompletedIds: readCompletedIds,
      readCompleteJustSucceededId: readCompleteJustSucceededId,
    );
    _syncIntoFeed(devotional);
  }

  void _syncFeedSnapshot(String devotionalId) {
    final snapshot = feedSnapshotFor(devotionalId);
    if (snapshot == null) {
      return;
    }
    final updatedDevotionals = Map<String, Devotional>.from(
      state.loadedDevotionals,
    );
    updatedDevotionals[devotionalId] = snapshot;
    state = state.copyWith(loadedDevotionals: updatedDevotionals);
  }

  Devotional _mergeFeedSnapshot(Devotional devotional) {
    final snapshot = feedSnapshotFor(devotional.id);
    if (snapshot == null) {
      return devotional;
    }

    return snapshot.copyWith(
      likesCount: devotional.likesCount,
      commentsCount: devotional.commentsCount,
      shareCount: devotional.shareCount,
      saveCount: devotional.saveCount,
      readCompleteCount: devotional.readCompleteCount,
      liked: devotional.liked,
      saved: devotional.saved,
      content: devotional.content,
      author: devotional.author.copyWith(following: snapshot.author.following),
      authorBlockRecommendation: devotional.authorBlockRecommendation,
    );
  }

  void _syncIntoFeed(Devotional devotional) {
    final readerArgs = state.readerArgs;
    if (readerArgs == null) {
      return;
    }
    ref
        .read(devotionalFeedProviderForMode(readerArgs.feedMode).notifier)
        .syncUpdatedDevotional(devotional);
  }

  int _indexFor(String devotionalId, {DevotionalFeedReaderArgs? readerArgs}) {
    final args = readerArgs ?? state.readerArgs;
    if (args == null) {
      return -1;
    }
    final items = _feedItems(args.feedMode);
    return items.indexWhere((item) => item.id == devotionalId);
  }

  List<Devotional> _feedItems(DevotionalFeedMode mode) {
    return ref.read(devotionalFeedProviderForMode(mode)).items;
  }

  String? _deliveryTokenFor(String devotionalId) {
    final snapshot = feedSnapshotFor(devotionalId);
    if (snapshot?.deliveryToken != null &&
        snapshot!.deliveryToken!.isNotEmpty) {
      return snapshot.deliveryToken;
    }

    final readerArgs = state.readerArgs;
    if (readerArgs != null && readerArgs.initialDevotionalId == devotionalId) {
      return readerArgs.initialDeliveryToken;
    }
    return null;
  }

  String _mapError(Object error) {
    return AppErrorMapper.toMessage(
      error,
      l10n: _l10n,
      fallbackMessage: _l10n.devotionalsLoadError,
    );
  }
}

final devotionalFeedReaderControllerProvider =
    NotifierProvider<DevotionalFeedReaderController, DevotionalFeedReaderState>(
      DevotionalFeedReaderController.new,
    );
