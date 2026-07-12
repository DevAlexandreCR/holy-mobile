import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holyverso/data/devotionals/devotionals_api_client.dart';

void main() {
  group('DevotionalsApiClient.fetchFeedHeader', () {
    test(
      'absolutizes the daily featured preview image URL against the base URL',
      () async {
        final dio = Dio(BaseOptions(baseUrl: 'https://api.holyverso.test'));
        dio.httpClientAdapter = _FakeHttpClientAdapter(
          jsonEncode({
            'data': {
              'streak': {
                'current_streak': 3,
                'longest_streak': 5,
                'streak_freeze_count': 0,
              },
              'completed_today': false,
              'daily_featured': {
                'id': 'devo-1',
                'title': 'Título',
                'estimated_read_time': 2,
                'preview_text': 'Preview',
                'preview_image_url':
                    '/storage/devotionals/images/daily.jpg',
              },
              'primary_cta': {
                'type': 'OPEN_DAILY_FEATURED',
                'label': 'Completa tu día',
                'devotional_id': 'devo-1',
              },
            },
          }),
        );

        final client = DevotionalsApiClient(dio);
        final header = await client.fetchFeedHeader();

        expect(
          header.dailyFeatured?.previewImageUrl,
          'https://api.holyverso.test/storage/devotionals/images/daily.jpg',
        );
      },
    );

    test('handles a null daily featured devotional without throwing', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.holyverso.test'));
      dio.httpClientAdapter = _FakeHttpClientAdapter(
        jsonEncode({
          'data': {
            'streak': {
              'current_streak': 0,
              'longest_streak': 0,
              'streak_freeze_count': 0,
            },
            'completed_today': false,
            'daily_featured': null,
            'primary_cta': {
              'type': 'OPEN_DAILY_FEATURED',
              'label': 'Completa tu día',
            },
          },
        }),
      );

      final client = DevotionalsApiClient(dio);
      final header = await client.fetchFeedHeader();

      expect(header.dailyFeatured, isNull);
    });
  });
}

class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter(this._responseBody);

  final String _responseBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      _responseBody,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
