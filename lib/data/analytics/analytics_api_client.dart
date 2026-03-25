import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/data/network/api_client.dart';

class AnalyticsApiClient {
  AnalyticsApiClient(this._dio);

  final Dio _dio;

  Future<void> recordAppSession({String? deviceId}) {
    return _dio.post(
      '/analytics/app-session',
      data: {
        if (deviceId != null && deviceId.isNotEmpty) 'device_id': deviceId,
      },
    );
  }
}

final analyticsApiClientProvider = Provider<AnalyticsApiClient>((ref) {
  return AnalyticsApiClient(ref.watch(dioProvider));
});
