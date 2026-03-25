import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/data/devotionals/devotionals_api_client.dart';
import 'package:holyverso/domain/core/cursor_paged_result.dart';
import 'package:holyverso/domain/core/paged_result.dart';
import 'package:holyverso/domain/devotionals/devotional.dart';
import 'package:holyverso/domain/devotionals/devotional_comment.dart';
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

  Future<CursorPagedResult<Devotional>> fetchFeed({
    String? cursor,
    int limit = 20,
  }) {
    return _client.fetchFeed(cursor: cursor, limit: limit);
  }

  Future<void> recordFeedEvents(List<Map<String, dynamic>> events) {
    return _client.recordFeedEvents(events);
  }

  Future<Devotional> getDevotional(String id) {
    return _client.getDevotional(id);
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
  }) {
    return _client.updateDevotional(
      devotionalId: devotionalId,
      title: title,
      content: content,
      verseReferences: verseReferences,
      imageAssetId: imageAssetId,
      coverImageFocusY: coverImageFocusY,
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

  Future<({bool liked, int likesCount})> toggleLike(String devotionalId) {
    return _client.toggleLike(devotionalId);
  }

  Future<({bool saved, int saveCount})> saveDevotional(String devotionalId) {
    return _client.saveDevotional(devotionalId);
  }

  Future<({bool saved, int saveCount})> unsaveDevotional(String devotionalId) {
    return _client.unsaveDevotional(devotionalId);
  }

  Future<int> shareDevotional(String devotionalId) {
    return _client.shareDevotional(devotionalId);
  }

  Future<int> markReadComplete(String devotionalId) {
    return _client.markReadComplete(devotionalId);
  }

  Future<void> reportDevotional({
    required String devotionalId,
    required String reason,
    String? details,
  }) {
    return _client.reportDevotional(
      devotionalId: devotionalId,
      reason: reason,
      details: details,
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
