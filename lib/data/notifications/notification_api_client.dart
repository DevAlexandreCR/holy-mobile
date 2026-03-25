import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/data/network/api_client.dart';

class NotificationApiClient {
  NotificationApiClient(this._dio);

  final Dio _dio;

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
}

final notificationApiClientProvider = Provider<NotificationApiClient>((ref) {
  return NotificationApiClient(ref.watch(dioProvider));
});
