import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/data/devotionals/devotionals_api_client.dart';
import 'package:holyverso/domain/core/cursor_paged_result.dart';
import 'package:holyverso/domain/core/paged_result.dart';
import 'package:holyverso/domain/devotionals/devotional.dart';
import 'package:holyverso/domain/devotionals/devotional_audio_config.dart';
import 'package:holyverso/domain/devotionals/devotional_audio_response.dart';
import 'package:holyverso/domain/devotionals/devotional_comment.dart';
import 'package:holyverso/domain/devotionals/devotional_feed_mode.dart';
import 'package:holyverso/domain/devotionals/devotional_feed_header.dart';
import 'package:holyverso/domain/devotionals/devotional_status.dart';
import 'package:holyverso/domain/devotionals/devotional_verse_reference.dart';
import 'package:holyverso/domain/devotionals/uploaded_devotional_image.dart';

class DevotionalsRepository {
  DevotionalsRepository(this._client);

  final DevotionalsApiClient _client;

  Future<PagedResult<Devotional>> fetchDevotionals({
    DevotionalStatus status = DevotionalStatus.published,
    int page = 1,
    int limit = 20,
    String? authorId,
  }) {
    return _client.fetchDevotionals(
      status: status,
      page: page,
      limit: limit,
      authorId: authorId,
    );
  }

  Future<PagedResult<Devotional>> fetchReviewQueue({
    int page = 1,
    int limit = 20,
  }) {
    return _client.fetchReviewQueue(page: page, limit: limit);
  }

  Future<CursorPagedResult<Devotional>> fetchFeed({
    required DevotionalFeedMode mode,
    String? cursor,
    int limit = 20,
  }) {
    return _client.fetchFeed(mode: mode, cursor: cursor, limit: limit);
  }

  Future<DevotionalFeedHeader> fetchFeedHeader() {
    return _client.fetchFeedHeader();
  }

  Future<void> celebrateMilestone(int milestone) {
    return _client.celebrateMilestone(milestone);
  }

  Future<DevotionalAudioConfig> fetchDevotionalAudioConfig() {
    return _client.fetchDevotionalAudioConfig();
  }

  Future<CursorPagedResult<Devotional>> fetchSavedDevotionals({
    String? cursor,
    int limit = 20,
  }) {
    return _client.fetchSavedDevotionals(cursor: cursor, limit: limit);
  }

  Future<void> recordFeedEvents(List<Map<String, dynamic>> events) {
    return _client.recordFeedEvents(events);
  }

  Future<Devotional> getDevotional(
    String id, {
    String? shareToken,
    String? deviceId,
  }) {
    return _client.getDevotional(
      id,
      shareToken: shareToken,
      deviceId: deviceId,
    );
  }

  Future<DevotionalAudioResponse> requestDevotionalAudio(String devotionalId) {
    return _client.requestDevotionalAudio(devotionalId);
  }

  Future<Devotional> createDevotional({
    required String title,
    required List<dynamic> content,
    required List<DevotionalVerseReference> verseReferences,
    String? imageAssetId,
    double? coverImageFocusY,
  }) {
    return _client.createDevotional(
      title: title,
      content: content,
      verseReferences: verseReferences,
      imageAssetId: imageAssetId,
      coverImageFocusY: coverImageFocusY,
    );
  }

  Future<Devotional> updateDevotional({
    required String devotionalId,
    String? title,
    List<dynamic>? content,
    List<DevotionalVerseReference>? verseReferences,
    String? imageAssetId,
    double? coverImageFocusY,
    bool clearImageAsset = false,
  }) {
    return _client.updateDevotional(
      devotionalId: devotionalId,
      title: title,
      content: content,
      verseReferences: verseReferences,
      imageAssetId: imageAssetId,
      coverImageFocusY: coverImageFocusY,
      clearImageAsset: clearImageAsset,
    );
  }

  Future<void> deleteDevotional(String devotionalId) {
    return _client.deleteDevotional(devotionalId);
  }

  Future<Devotional> publishDevotional(String devotionalId) {
    return _client.publishDevotional(devotionalId);
  }

  Future<Devotional> archiveDevotional(String devotionalId) {
    return _client.archiveDevotional(devotionalId);
  }

  Future<Devotional> approveDevotionalReview(String devotionalId) {
    return _client.approveDevotionalReview(devotionalId);
  }

  Future<Devotional> restrictDevotionalReview({
    required String devotionalId,
    required String reason,
  }) {
    return _client.restrictDevotionalReview(
      devotionalId: devotionalId,
      reason: reason,
    );
  }

  Future<({bool liked, int likesCount})> toggleLike(String devotionalId) {
    return _client.toggleLike(devotionalId);
  }

  Future<({bool saved, int saveCount})> saveDevotional(
    String devotionalId, {
    String? deliveryToken,
  }) {
    return _client.saveDevotional(devotionalId, deliveryToken: deliveryToken);
  }

  Future<({bool saved, int saveCount})> unsaveDevotional(String devotionalId) {
    return _client.unsaveDevotional(devotionalId);
  }

  Future<({int shareCount, String shareUrl})> shareDevotional(
    String devotionalId, {
    String? deliveryToken,
  }) {
    return _client.shareDevotional(devotionalId, deliveryToken: deliveryToken);
  }

  Future<int> markReadComplete(
    String devotionalId, {
    String? deliveryToken,
    String? shareToken,
    String? deviceId,
  }) {
    return _client.markReadComplete(
      devotionalId,
      deliveryToken: deliveryToken,
      shareToken: shareToken,
      deviceId: deviceId,
    );
  }

  Future<void> reportDevotional({
    required String devotionalId,
    required String reason,
    String? details,
    String? deliveryToken,
  }) {
    return _client.reportDevotional(
      devotionalId: devotionalId,
      reason: reason,
      details: details,
      deliveryToken: deliveryToken,
    );
  }

  Future<PagedResult<DevotionalComment>> fetchComments({
    required String devotionalId,
    int page = 1,
    int limit = 50,
  }) {
    return _client.fetchComments(
      devotionalId: devotionalId,
      page: page,
      limit: limit,
    );
  }

  Future<DevotionalComment> addComment({
    required String devotionalId,
    required String content,
  }) {
    return _client.addComment(devotionalId: devotionalId, content: content);
  }

  Future<DevotionalComment> updateComment({
    required String devotionalId,
    required String commentId,
    required String content,
  }) {
    return _client.updateComment(
      devotionalId: devotionalId,
      commentId: commentId,
      content: content,
    );
  }

  Future<void> deleteComment({
    required String devotionalId,
    required String commentId,
  }) {
    return _client.deleteComment(
      devotionalId: devotionalId,
      commentId: commentId,
    );
  }

  Future<UploadedDevotionalImage> uploadImage(File file) {
    return _client.uploadImage(file);
  }
}

final devotionalsRepositoryProvider = Provider<DevotionalsRepository>((ref) {
  return DevotionalsRepository(ref.watch(devotionalsApiClientProvider));
});
