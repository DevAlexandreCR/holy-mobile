import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/data/network/api_client.dart';
import 'package:holyverso/domain/core/cursor_paged_result.dart';
import 'package:holyverso/domain/creator_profiles/creator_profile.dart';
import 'package:holyverso/domain/creator_profiles/creator_profile_update_result.dart';
import 'package:holyverso/domain/creator_profiles/uploaded_creator_avatar.dart';
import 'package:holyverso/domain/devotionals/devotional.dart';

class CreatorProfilesApiClient {
  CreatorProfilesApiClient(this._dio);

  final Dio _dio;

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

  Map<String, dynamic> _unwrapData(dynamic rawData) {
    final data = rawData is Map ? rawData['data'] ?? rawData : rawData;
    return Map<String, dynamic>.from(data as Map);
  }

  Map<String, dynamic> _normalizeProfile(Map<String, dynamic> map) {
    return {...map, 'avatar_url': _resolveUrl(map['avatar_url']?.toString())};
  }

  Map<String, dynamic> _normalizeDevotional(Map<String, dynamic> map) {
    final author = Map<String, dynamic>.from(map['author'] as Map? ?? const {});
    return {
      ...map,
      'cover_image_url': _resolveUrl(map['cover_image_url']?.toString()),
      'preview_image_url': _resolveUrl(map['preview_image_url']?.toString()),
      'author': {
        ...author,
        'avatar_url': _resolveUrl(author['avatar_url']?.toString()),
      },
    };
  }

  Future<CreatorProfile> getCreatorProfile(String id) async {
    final response = await _dio.get('/users/$id/profile');
    return CreatorProfile.fromMap(
      _normalizeProfile(_unwrapData(response.data)),
    );
  }

  Future<CursorPagedResult<Devotional>> getCreatorDevotionals({
    required String id,
    String? cursor,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      '/users/$id/devotionals',
      queryParameters: {
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

  Future<CreatorProfile> followCreator(String id) async {
    final response = await _dio.post('/users/$id/follow');
    return CreatorProfile.fromMap(
      _normalizeProfile(_unwrapData(response.data)),
    );
  }

  Future<CreatorProfile> unfollowCreator(String id) async {
    final response = await _dio.delete('/users/$id/follow');
    return CreatorProfile.fromMap(
      _normalizeProfile(_unwrapData(response.data)),
    );
  }

  Future<CreatorProfileUpdateResult> updateMyCreatorProfile({
    String? handle,
    String? bio,
    String? avatarAssetId,
    bool clearAvatar = false,
  }) async {
    final payload = <String, dynamic>{};
    if (handle != null) payload['handle'] = handle;
    payload['bio'] = bio;
    if (clearAvatar) {
      payload['avatar_asset_id'] = null;
    } else if (avatarAssetId != null) {
      payload['avatar_asset_id'] = avatarAssetId;
    }

    final response = await _dio.put('/users/me/creator-profile', data: payload);
    return CreatorProfileUpdateResult.fromMap(
      _normalizeProfile(_unwrapData(response.data)),
    );
  }

  Future<UploadedCreatorAvatar> uploadAvatar(File file) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(file.path),
    });

    final response = await _dio.post(
      '/users/me/upload-avatar',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final data = _unwrapData(response.data);
    return UploadedCreatorAvatar.fromMap({
      ...data,
      'preview_image_url': _resolveUrl(data['preview_image_url']?.toString()),
    });
  }
}

final creatorProfilesApiClientProvider = Provider<CreatorProfilesApiClient>((
  ref,
) {
  return CreatorProfilesApiClient(ref.watch(dioProvider));
});
