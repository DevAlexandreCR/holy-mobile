import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/data/network/api_client.dart';
import 'package:holyverso/domain/core/cursor_paged_result.dart';
import 'package:holyverso/domain/notifications/notification_inbox_item.dart';

class NotificationApiClient {
  NotificationApiClient(this._dio);

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

  Map<String, dynamic> _normalizeInboxItem(Map<String, dynamic> map) {
    final actorPreview = (map['actor_preview'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) => {
            ...Map<String, dynamic>.from(item),
            'avatar_url': _resolveUrl(item['avatar_url']?.toString()),
          },
        )
        .toList();
    final devotional = map['devotional'] as Map?;
    final creator = map['creator'] as Map?;

    return {
      ...map,
      'image_url': _resolveUrl(map['image_url']?.toString()),
      'actor_preview': actorPreview,
      if (devotional != null)
        'devotional': {
          ...Map<String, dynamic>.from(devotional),
          'image_url': _resolveUrl(devotional['image_url']?.toString()),
        },
      if (creator != null)
        'creator': {
          ...Map<String, dynamic>.from(creator),
          'avatar_url': _resolveUrl(creator['avatar_url']?.toString()),
        },
    };
  }

  Future<void> registerDeviceToken({
    required String token,
    required String platform,
    required String osPermissionStatus,
  }) {
    return _dio.post(
      '/device-tokens/register',
      data: {
        'token': token,
        'platform': platform,
        'os_permission_status': osPermissionStatus,
      },
    );
  }

  Future<void> deleteDeviceToken({required String token}) {
    return _dio.post('/device-tokens/delete', data: {'token': token});
  }

  Future<void> markNotificationOpened({
    required String devotionalId,
    required String type,
  }) {
    return _dio.post(
      '/notifications/open',
      data: {'devotional_id': devotionalId, 'type': type},
    );
  }

  Future<CursorPagedResult<NotificationInboxItem>> fetchInbox({
    String? cursor,
    int limit = 20,
    NotificationInboxFilter filter = NotificationInboxFilter.all,
  }) async {
    final response = await _dio.get(
      '/notifications/inbox',
      queryParameters: {
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        'limit': limit,
        'filter': filter.queryValue,
      },
    );

    final data = _unwrapData(response.data);
    final itemsRaw = data['items'] as List? ?? [];

    return CursorPagedResult<NotificationInboxItem>(
      items: itemsRaw
          .whereType<Map>()
          .map(
            (item) => NotificationInboxItem.fromMap(
              _normalizeInboxItem(Map<String, dynamic>.from(item)),
            ),
          )
          .toList(),
      nextCursor: data['next_cursor']?.toString(),
      hasMore: data['has_more'] == true,
    );
  }

  Future<int> fetchInboxUnreadCount() async {
    final response = await _dio.get('/notifications/inbox/unread-count');
    final data = _unwrapData(response.data);
    return (data['unread_count'] as num?)?.toInt() ?? 0;
  }

  Future<void> markInboxItemRead(
    String id, {
    bool opened = false,
  }) async {
    await _dio.post(
      '/notifications/inbox/$id/read',
      data: {'opened': opened},
    );
  }

  Future<int> markAllInboxItemsRead() async {
    final response = await _dio.post('/notifications/inbox/read-all');
    final data = _unwrapData(response.data);
    return (data['updated'] as num?)?.toInt() ?? 0;
  }
}

final notificationApiClientProvider = Provider<NotificationApiClient>((ref) {
  return NotificationApiClient(ref.watch(dioProvider));
});
