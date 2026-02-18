import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/data/network/api_client.dart';
import 'package:holyverso/domain/core/paged_result.dart';
import 'package:holyverso/domain/devotionals/devotional.dart';
import 'package:holyverso/domain/devotionals/devotional_comment.dart';
import 'package:holyverso/domain/devotionals/devotional_status.dart';
import 'package:holyverso/domain/devotionals/devotional_verse_reference.dart';

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
    final cover = map['cover_image_url']?.toString();
    if (cover == null || cover.isEmpty) return map;
    return {...map, 'cover_image_url': _resolveUrl(cover)};
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

  Future<Devotional> getDevotional(String id) async {
    final response = await _dio.get('/devotionals/$id');
    final data = _unwrapData(response.data);
    return Devotional.fromMap(_normalizeDevotional(data));
  }

  Future<Devotional> createDevotional({
    required String title,
    required List<dynamic> content,
    required List<DevotionalVerseReference> verseReferences,
    String? coverImageUrl,
    double? coverImageFocusY,
    DevotionalStatus status = DevotionalStatus.draft,
  }) async {
    final response = await _dio.post(
      '/devotionals',
      data: {
        'title': title,
        'content': content,
        'cover_image_url': coverImageUrl,
        'cover_image_focus_y': coverImageFocusY,
        'verse_references': verseReferences
            .map((reference) => reference.toMap())
            .toList(),
        'status': status.apiValue,
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
    String? coverImageUrl,
    double? coverImageFocusY,
  }) async {
    final payload = <String, dynamic>{};
    if (title != null) payload['title'] = title;
    if (content != null) payload['content'] = content;
    if (coverImageUrl != null) payload['cover_image_url'] = coverImageUrl;
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

  Future<String> uploadImage(File file) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(file.path),
    });

    final response = await _dio.post(
      '/devotionals/upload-image',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final data = _unwrapData(response.data);
    final url = _resolveUrl(data['url']?.toString());
    if (url == null || url.isEmpty) {
      throw StateError(_l10n.genericError);
    }
    return url;
  }
}

final devotionalsApiClientProvider = Provider<DevotionalsApiClient>((ref) {
  return DevotionalsApiClient(ref.watch(dioProvider));
});
