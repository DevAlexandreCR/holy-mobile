import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/core/errors/app_error_mapper.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/data/devotionals/devotionals_repository.dart';
import 'package:holyverso/domain/devotionals/devotional.dart';
import 'package:holyverso/domain/devotionals/devotional_feed_mode.dart';
import 'package:holyverso/presentation/state/auth/auth_controller.dart';
import 'package:holyverso/presentation/state/devotionals/devotionals_feed_state.dart';

abstract class BaseDevotionalsFeedController
    extends Notifier<DevotionalsFeedState> {
  late final DevotionalsRepository _repository;
  final Set<String> _trackedImpressions = <String>{};
  final Set<String> _trackedOpens = <String>{};
  bool _isRecoveringInvalidFeedState = false;
  static const _l10n = AppLocalizations(Locale('es'));

  DevotionalFeedMode get feedMode;

  @override
  DevotionalsFeedState build() {
    _repository = ref.read(devotionalsRepositoryProvider);
    return const DevotionalsFeedState();
  }

  Future<void> loadInitial({bool forceRefresh = false}) async {
    final ownerChanged = _syncFeedOwner();
    if (state.status == DevotionalsFeedStatus.loading && !forceRefresh) {
      return;
    }

    if (!forceRefresh && !ownerChanged && state.items.isNotEmpty) {
      return;
    }

    final hasCachedItems = state.items.isNotEmpty;
    state = hasCachedItems
        ? state.copyWith(
            status: DevotionalsFeedStatus.loading,
            clearError: true,
          )
        : state.copyWith(
            status: DevotionalsFeedStatus.loading,
            items: const [],
            hasMore: true,
            clearError: true,
            clearNextCursor: true,
          );

    await _fetchPage(clearTracking: forceRefresh);
  }

  Future<void> refresh() => loadInitial(forceRefresh: true);

  Future<void> loadMore() async {
    if (_syncFeedOwner()) {
      await loadInitial(forceRefresh: true);
      return;
    }

    if (state.isFetchingMore ||
        !state.hasMore ||
        state.status == DevotionalsFeedStatus.loading) {
      return;
    }
    state = state.copyWith(isFetchingMore: true, clearError: true);
    await _fetchPage(append: true);
  }

  Future<void> _fetchPage({
    bool append = false,
    bool clearTracking = false,
  }) async {
    try {
      final ownerUserId = _currentUserId;
      final result = await _repository.fetchFeed(
        mode: feedMode,
        cursor: append ? state.nextCursor : null,
      );
      final items = append ? [...state.items, ...result.items] : result.items;
      if (!append && clearTracking) {
        _trackedImpressions.clear();
        _trackedOpens.clear();
      }
      state = state.copyWith(
        status: DevotionalsFeedStatus.success,
        items: items,
        nextCursor: result.nextCursor,
        ownerUserId: ownerUserId,
        hasMore: result.hasMore,
      );
    } catch (error) {
      state = state.copyWith(
        status: DevotionalsFeedStatus.error,
        errorMessage: _mapError(error),
      );
    } finally {
      if (state.isFetchingMore) {
        state = state.copyWith(isFetchingMore: false);
      }
    }
  }

  Future<void> toggleLike(String devotionalId) async {
    if (state.likingDevotionalId == devotionalId) return;
    final index = state.items.indexWhere((item) => item.id == devotionalId);
    if (index == -1) return;

    state = state.copyWith(likingDevotionalId: devotionalId, clearError: true);
    try {
      final result = await _repository.toggleLike(devotionalId);
      final items = [...state.items];
      items[index] = items[index].copyWith(
        likesCount: result.likesCount,
        liked: result.liked,
      );
      state = state.copyWith(items: items);
    } catch (error) {
      state = state.copyWith(errorMessage: _mapError(error));
    } finally {
      if (state.likingDevotionalId == devotionalId) {
        state = state.copyWith(clearLikingDevotionalId: true);
      }
    }
  }

  Future<bool> toggleSave(String devotionalId) async {
    if (state.savingDevotionalId == devotionalId) return false;
    final index = state.items.indexWhere((item) => item.id == devotionalId);
    if (index == -1) return false;

    final devotional = state.items[index];
    final optimisticSaved = !devotional.saved;
    final optimisticSaveCount = max(
      devotional.saveCount + (optimisticSaved ? 1 : -1),
      0,
    );
    final items = [...state.items];
    items[index] = devotional.copyWith(
      saved: optimisticSaved,
      saveCount: optimisticSaveCount,
    );
    state = state.copyWith(savingDevotionalId: devotionalId, clearError: true);
    state = state.copyWith(items: items);
    try {
      final result = devotional.saved
          ? await _repository.unsaveDevotional(devotionalId)
          : await _repository.saveDevotional(
              devotionalId,
              deliveryToken: devotional.deliveryToken,
            );
      final updatedItems = [...state.items];
      updatedItems[index] = updatedItems[index].copyWith(
        saved: result.saved,
        saveCount: result.saveCount,
      );
      state = state.copyWith(items: updatedItems);
      return true;
    } catch (error) {
      final revertedItems = [...state.items];
      revertedItems[index] = devotional;
      state = state.copyWith(errorMessage: _mapError(error));
      state = state.copyWith(items: revertedItems);
      return false;
    } finally {
      if (state.savingDevotionalId == devotionalId) {
        state = state.copyWith(clearSavingDevotionalId: true);
      }
    }
  }

  Future<void> registerImpression(Devotional devotional) async {
    if (_syncFeedOwner()) {
      await loadInitial(forceRefresh: true);
      return;
    }

    final deliveryToken = devotional.deliveryToken;
    if (deliveryToken == null || deliveryToken.isEmpty) return;
    if (_trackedImpressions.contains(deliveryToken)) return;

    _trackedImpressions.add(deliveryToken);
    try {
      await _recordFeedEvent(
        devotional: devotional,
        type: 'IMPRESSION',
        trackedTokens: _trackedImpressions,
      );
    } catch (_) {}
  }

  Future<void> registerOpen(Devotional devotional) async {
    if (_syncFeedOwner()) {
      await loadInitial(forceRefresh: true);
      return;
    }

    final deliveryToken = devotional.deliveryToken;
    if (deliveryToken == null || deliveryToken.isEmpty) return;
    if (_trackedOpens.contains(deliveryToken)) return;

    _trackedOpens.add(deliveryToken);
    try {
      await _recordFeedEvent(
        devotional: devotional,
        type: 'OPEN',
        trackedTokens: _trackedOpens,
      );
    } catch (_) {}
  }

  Future<void> registerShare(Devotional devotional, {int? shareCount}) async {
    final index = state.items.indexWhere((item) => item.id == devotional.id);
    if (index == -1) return;

    if (shareCount != null) {
      final items = [...state.items];
      items[index] = items[index].copyWith(shareCount: shareCount);
      state = state.copyWith(items: items);
      return;
    }

    try {
      final result = await _repository.shareDevotional(
        devotional.id,
        deliveryToken: devotional.deliveryToken,
      );
      final items = [...state.items];
      items[index] = items[index].copyWith(shareCount: result.shareCount);
      state = state.copyWith(items: items);
    } catch (_) {}
  }

  void syncUpdatedDevotional(Devotional devotional) {
    final index = state.items.indexWhere((item) => item.id == devotional.id);
    if (index == -1) return;
    final items = [...state.items];
    items[index] = devotional;
    state = state.copyWith(items: items);
  }

  void syncCreatorProfile({
    required String creatorId,
    required bool following,
    String? handle,
    String? avatarUrl,
  }) {
    final items = state.items
        .where(
          (item) =>
              feedMode != DevotionalFeedMode.following ||
              following ||
              item.author.id != creatorId,
        )
        .map((item) {
          if (item.author.id != creatorId) {
            return item;
          }

          return item.copyWith(
            author: item.author.copyWith(
              following: following,
              handle: handle ?? item.author.handle,
              avatarUrl: avatarUrl ?? item.author.avatarUrl,
            ),
          );
        })
        .toList();

    state = state.copyWith(items: items);
  }

  String? get _currentUserId => ref.read(authControllerProvider).user?.id;

  bool _syncFeedOwner() {
    final currentUserId = _currentUserId;
    if (state.ownerUserId == currentUserId) {
      return false;
    }

    _trackedImpressions.clear();
    _trackedOpens.clear();
    state = state.copyWith(
      items: const [],
      status: DevotionalsFeedStatus.idle,
      ownerUserId: currentUserId,
      hasMore: true,
      isFetchingMore: false,
      clearError: true,
      clearNextCursor: true,
      clearLikingDevotionalId: true,
      clearSavingDevotionalId: true,
    );
    return true;
  }

  Future<void> _recordFeedEvent({
    required Devotional devotional,
    required String type,
    required Set<String> trackedTokens,
  }) async {
    final deliveryToken = devotional.deliveryToken;
    if (deliveryToken == null || deliveryToken.isEmpty) {
      return;
    }

    try {
      await _repository.recordFeedEvents([
        {
          'event_id': _generateUuid(),
          'type': type,
          'devotional_id': devotional.id,
          'delivery_token': deliveryToken,
          'occurred_at': DateTime.now().toUtc().toIso8601String(),
        },
      ]);
    } catch (error) {
      trackedTokens.remove(deliveryToken);
      if (AppErrorMapper.backendCode(error) == 'INVALID_DELIVERY_TOKEN') {
        await _recoverFromInvalidFeedDelivery();
      }
      rethrow;
    }
  }

  Future<void> _recoverFromInvalidFeedDelivery() async {
    if (_isRecoveringInvalidFeedState) {
      return;
    }

    _isRecoveringInvalidFeedState = true;
    try {
      _trackedImpressions.clear();
      _trackedOpens.clear();
      state = state.copyWith(
        items: const [],
        status: DevotionalsFeedStatus.idle,
        hasMore: true,
        isFetchingMore: false,
        clearError: true,
        clearNextCursor: true,
        clearLikingDevotionalId: true,
        clearSavingDevotionalId: true,
      );
      await loadInitial(forceRefresh: true);
    } finally {
      _isRecoveringInvalidFeedState = false;
    }
  }

  String _mapError(Object error) {
    return AppErrorMapper.toMessage(
      error,
      l10n: _l10n,
      fallbackMessage: _l10n.devotionalsLoadError,
    );
  }

  String _generateUuid() {
    final random = Random.secure();
    String segment(int length) => List.generate(
      length,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();

    return '${segment(8)}-${segment(4)}-4${segment(3)}-'
        '${['8', '9', 'a', 'b'][random.nextInt(4)]}${segment(3)}-'
        '${segment(12)}';
  }
}

class ForYouFeedController extends BaseDevotionalsFeedController {
  @override
  DevotionalFeedMode get feedMode => DevotionalFeedMode.forYou;
}

class FollowingFeedController extends BaseDevotionalsFeedController {
  @override
  DevotionalFeedMode get feedMode => DevotionalFeedMode.following;
}

final forYouFeedControllerProvider =
    NotifierProvider<ForYouFeedController, DevotionalsFeedState>(
      ForYouFeedController.new,
    );

final followingFeedControllerProvider =
    NotifierProvider<FollowingFeedController, DevotionalsFeedState>(
      FollowingFeedController.new,
    );

final devotionalsFeedControllerProvider = forYouFeedControllerProvider;
