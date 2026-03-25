import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/data/network/api_client.dart';
import 'package:holyverso/domain/core/cursor_paged_result.dart';
import 'package:holyverso/domain/core/paged_result.dart';
import 'package:holyverso/domain/devotionals/devotional.dart';
import 'package:holyverso/domain/devotionals/devotional_comment.dart';
import 'package:holyverso/domain/devotionals/devotional_feed_mode.dart';
import 'package:holyverso/domain/devotionals/devotional_status.dart';
import 'package:holyverso/domain/devotionals/devotional_verse_reference.dart';
import 'package:holyverso/domain/devotionals/uploaded_devotional_image.dart';

class DevotionalsApiClient {
  DevotionalsApiClient(this._dio);

  final Dio _dio;
  static const _l10n = AppLocalizations(Locale('es'));

  String? _resolveUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return null;
    if (rawUrl.startsWith('http')) return rawUrl;

    final base = _dio.options.baseUrl;
    final normalizedBase = base.endsWith('/')
        ? base.substring(0, base.length - 1)
        : base;
    final normalizedPath = rawUrl.startsWith('/') ? rawUrl : '/$rawUrl';
    return '$normalizedBase$normalizedPath';
  }

  Map<String, dynamic> _normalizeDevotional(Map<String, dynamic> map) {
    final cover = _resolveUrl(map['cover_image_url']?.toString());
    final preview = _resolveUrl(map['preview_image_url']?.toString());
    final author = Map<String, dynamic>.from(map['author'] as Map? ?? const {});
    return {
      ...map,
      if (cover != null) 'cover_image_url': cover,
      if (preview != null) 'preview_image_url': preview,
      'author': {
        ...author,
        'avatar_url': _resolveUrl(author['avatar_url']?.toString()),
      },
    };
  }

  Map<String, dynamic> _unwrapData(dynamic rawData, {String? errorMessage}) {
    final data = rawData is Map ? rawData['data'] ?? rawData : rawData;

    if (data is Map<String, dynamic>) {
      return data;
    }

    throw StateError(errorMessage ?? _l10n.genericError);
  }

  Future<PagedResult<Devotional>> fetchDevotionals({
    DevotionalStatus status = DevotionalStatus.published,
    int page = 1,
    int limit = 20,
    String? authorId,
  }) async {
    final response = await _dio.get(
      '/devotionals',
      queryParameters: {
        'status': status.apiValue,
        'page': page,
        'limit': limit,
        if (authorId != null) 'authorId': authorId,
      },
    );

    final data = _unwrapData(response.data);
    final itemsRaw = data['items'] as List? ?? [];

    return PagedResult<Devotional>(
      items: itemsRaw
          .whereType<Map>()
          .map(
            (item) => Devotional.fromMap(
              _normalizeDevotional(Map<String, dynamic>.from(item)),
            ),
          )
          .toList(),
      page: (data['page'] as num?)?.toInt() ?? page,
      limit: (data['limit'] as num?)?.toInt() ?? limit,
      total: (data['total'] as num?)?.toInt() ?? itemsRaw.length,
    );
  }

  Future<CursorPagedResult<Devotional>> fetchFeed({
    required DevotionalFeedMode mode,
    String? cursor,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      '/devotionals/feed',
      queryParameters: {
        'mode': mode.apiValue,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        'limit': limit,
      },
    );

    final data = _unwrapData(response.data);
    final itemsRaw = data['items'] as List? ?? [];

    return CursorPagedResult<Devotional>(
      items: itemsRaw
          .whereType<Map>()
          .map(
            (item) => Devotional.fromMap(
              _normalizeDevotional(Map<String, dynamic>.from(item)),
            ),
          )
          .toList(),
      nextCursor: data['next_cursor']?.toString(),
      hasMore: data['has_more'] == true,
    );
  }

  Future<void> recordFeedEvents(List<Map<String, dynamic>> events) async {
    await _dio.post('/devotionals/feed/events', data: {'events': events});
  }

  Future<Devotional> getDevotional(String id) async {
    final response = await _dio.get('/devotionals/$id');
    final data = _unwrapData(response.data);
    return Devotional.fromMap(_normalizeDevotional(data));
  }

  Future<Devotional> createDevotional({
    required String title,
    required List<dynamic> content,
    required List<DevotionalVerseReference> verseReferences,
    String? imageAssetId,
    double? coverImageFocusY,
  }) async {
    final response = await _dio.post(
      '/devotionals',
      data: {
        'title': title,
        'content': content,
        'image_asset_id': imageAssetId,
        'cover_image_focus_y': coverImageFocusY,
        'verse_references': verseReferences
            .map((reference) => reference.toMap())
            .toList(),
      },
    );

    final data = _unwrapData(response.data);
    return Devotional.fromMap(_normalizeDevotional(data));
  }

  Future<Devotional> updateDevotional({
    required String devotionalId,
    String? title,
    List<dynamic>? content,
    List<DevotionalVerseReference>? verseReferences,
    String? imageAssetId,
    double? coverImageFocusY,
    bool clearImageAsset = false,
  }) async {
    final payload = <String, dynamic>{};
    if (title != null) payload['title'] = title;
    if (content != null) payload['content'] = content;
    if (clearImageAsset) {
      payload['image_asset_id'] = null;
    } else if (imageAssetId != null) {
      payload['image_asset_id'] = imageAssetId;
    }
    if (coverImageFocusY != null) {
      payload['cover_image_focus_y'] = coverImageFocusY;
    }
    if (verseReferences != null) {
      payload['verse_references'] = verseReferences
          .map((reference) => reference.toMap())
          .toList();
    }

    final response = await _dio.put(
      '/devotionals/$devotionalId',
      data: payload,
    );
    final data = _unwrapData(response.data);
    return Devotional.fromMap(_normalizeDevotional(data));
  }

  Future<void> deleteDevotional(String devotionalId) async {
    await _dio.delete('/devotionals/$devotionalId');
  }

  Future<Devotional> publishDevotional(String devotionalId) async {
    final response = await _dio.post('/devotionals/$devotionalId/publish');
    final data = _unwrapData(response.data);
    return Devotional.fromMap(_normalizeDevotional(data));
  }

  Future<Devotional> archiveDevotional(String devotionalId) async {
    final response = await _dio.post('/devotionals/$devotionalId/archive');
    final data = _unwrapData(response.data);
    return Devotional.fromMap(_normalizeDevotional(data));
  }

  Future<({bool liked, int likesCount})> toggleLike(String devotionalId) async {
    final response = await _dio.post('/devotionals/$devotionalId/like');
    final data = _unwrapData(response.data);
    return (
      liked: data['liked'] == true,
      likesCount: (data['likes_count'] as num?)?.toInt() ?? 0,
    );
  }

  Future<({bool saved, int saveCount})> saveDevotional(
    String devotionalId,
  ) async {
    final response = await _dio.post('/devotionals/$devotionalId/save');
    final data = _unwrapData(response.data);
    return (
      saved: data['saved'] == true,
      saveCount: (data['save_count'] as num?)?.toInt() ?? 0,
    );
  }

  Future<({bool saved, int saveCount})> unsaveDevotional(
    String devotionalId,
  ) async {
    final response = await _dio.delete('/devotionals/$devotionalId/save');
    final data = _unwrapData(response.data);
    return (
      saved: data['saved'] == true,
      saveCount: (data['save_count'] as num?)?.toInt() ?? 0,
    );
  }

  Future<int> shareDevotional(String devotionalId) async {
    final response = await _dio.post('/devotionals/$devotionalId/share');
    final data = _unwrapData(response.data);
    return (data['share_count'] as num?)?.toInt() ?? 0;
  }

  Future<int> markReadComplete(String devotionalId) async {
    final response = await _dio.post(
      '/devotionals/$devotionalId/read-complete',
    );
    final data = _unwrapData(response.data);
    return (data['read_complete_count'] as num?)?.toInt() ?? 0;
  }

  Future<void> reportDevotional({
    required String devotionalId,
    required String reason,
    String? details,
  }) async {
    await _dio.post(
      '/devotionals/$devotionalId/report',
      data: {
        'reason': reason,
        if (details != null && details.isNotEmpty) 'details': details,
      },
    );
  }

  Future<PagedResult<DevotionalComment>> fetchComments({
    required String devotionalId,
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _dio.get(
      '/devotionals/$devotionalId/comments',
      queryParameters: {'page': page, 'limit': limit},
    );

    final data = _unwrapData(response.data);
    final itemsRaw = data['items'] as List? ?? [];

    return PagedResult<DevotionalComment>(
      items: itemsRaw
          .whereType<Map>()
          .map(
            (item) =>
                DevotionalComment.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList(),
      page: (data['page'] as num?)?.toInt() ?? page,
      limit: (data['limit'] as num?)?.toInt() ?? limit,
      total: (data['total'] as num?)?.toInt() ?? itemsRaw.length,
    );
  }

  Future<DevotionalComment> addComment({
    required String devotionalId,
    required String content,
  }) async {
    final response = await _dio.post(
      '/devotionals/$devotionalId/comments',
      data: {'content': content},
    );

    final data = _unwrapData(response.data);
    return DevotionalComment.fromMap(data);
  }

  Future<DevotionalComment> updateComment({
    required String devotionalId,
    required String commentId,
    required String content,
  }) async {
    final response = await _dio.put(
      '/devotionals/$devotionalId/comments/$commentId',
      data: {'content': content},
    );

    final data = _unwrapData(response.data);
    return DevotionalComment.fromMap(data);
  }

  Future<void> deleteComment({
    required String devotionalId,
    required String commentId,
  }) async {
    await _dio.delete('/devotionals/$devotionalId/comments/$commentId');
  }

  Future<UploadedDevotionalImage> uploadImage(File file) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(file.path),
    });

    final response = await _dio.post(
      '/devotionals/upload-image',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final data = _unwrapData(response.data);
    final normalized = {
      ...data,
      'preview_image_url': _resolveUrl(data['preview_image_url']?.toString()),
    };
    return UploadedDevotionalImage.fromMap(normalized);
  }
}

final devotionalsApiClientProvider = Provider<DevotionalsApiClient>((ref) {
  return DevotionalsApiClient(ref.watch(dioProvider));
});
