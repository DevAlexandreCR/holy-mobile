import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/data/network/api_client.dart';

class ShareAttributionApiClient {
  ShareAttributionApiClient(this._dio);

  final Dio _dio;

  Future<void> recordAppOpen({
    required String token,
    String? deviceId,
    bool installDetected = false,
    bool registrationCompleted = false,
  }) {
    return _dio.post(
      '/share-attribution/app-open',
      data: {
        'token': token,
        if (deviceId != null && deviceId.isNotEmpty) 'device_id': deviceId,
        if (installDetected) 'install_detected': true,
        if (registrationCompleted) 'registration_completed': true,
      },
    );
  }
}

final shareAttributionApiClientProvider = Provider<ShareAttributionApiClient>((
  ref,
) {
  return ShareAttributionApiClient(ref.watch(dioProvider));
});
