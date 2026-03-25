import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/data/network/api_client.dart';
import 'package:holyverso/domain/core/cursor_paged_result.dart';
import 'package:holyverso/domain/insights/creator_devotional_insight.dart';
import 'package:holyverso/domain/insights/creator_insights_overview.dart';

class InsightsApiClient {
  InsightsApiClient(this._dio);

  final Dio _dio;

  dynamic _unwrapData(dynamic rawData) {
    if (rawData is Map && rawData['data'] != null) {
      return rawData['data'];
    }
    return rawData;
  }

  Future<CreatorInsightsOverview> fetchOverview() async {
    final response = await _dio.get('/users/me/insights/overview');
    final data = Map<String, dynamic>.from(_unwrapData(response.data) as Map);
    return CreatorInsightsOverview.fromMap(data);
  }

  Future<CursorPagedResult<CreatorDevotionalInsight>> fetchDevotionalInsights({
    String? cursor,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      '/users/me/insights/devotionals',
      queryParameters: {
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        'limit': limit,
      },
    );

    final data = Map<String, dynamic>.from(_unwrapData(response.data) as Map);
    final itemsRaw = data['items'] as List? ?? const [];
    return CursorPagedResult<CreatorDevotionalInsight>(
      items: itemsRaw
          .whereType<Map>()
          .map(
            (item) => CreatorDevotionalInsight.fromMap(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      nextCursor: data['next_cursor']?.toString(),
      hasMore: data['has_more'] == true,
    );
  }

  Future<CreatorDevotionalInsight> fetchDevotionalInsightDetail(
    String devotionalId,
  ) async {
    final response = await _dio.get('/users/me/insights/devotionals/$devotionalId');
    final data = Map<String, dynamic>.from(_unwrapData(response.data) as Map);
    return CreatorDevotionalInsight.fromMap(data);
  }
}

final insightsApiClientProvider = Provider<InsightsApiClient>((ref) {
  return InsightsApiClient(ref.watch(dioProvider));
});
