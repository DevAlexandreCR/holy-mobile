import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/data/insights/insights_api_client.dart';
import 'package:holyverso/domain/core/cursor_paged_result.dart';
import 'package:holyverso/domain/insights/creator_devotional_insight.dart';
import 'package:holyverso/domain/insights/creator_insights_overview.dart';

class InsightsRepository {
  InsightsRepository(this._client);

  final InsightsApiClient _client;

  Future<CreatorInsightsOverview> fetchOverview() {
    return _client.fetchOverview();
  }

  Future<CursorPagedResult<CreatorDevotionalInsight>> fetchDevotionalInsights({
    String? cursor,
    int limit = 20,
  }) {
    return _client.fetchDevotionalInsights(cursor: cursor, limit: limit);
  }

  Future<CreatorDevotionalInsight> fetchDevotionalInsightDetail(
    String devotionalId,
  ) {
    return _client.fetchDevotionalInsightDetail(devotionalId);
  }
}

final insightsRepositoryProvider = Provider<InsightsRepository>((ref) {
  return InsightsRepository(ref.watch(insightsApiClientProvider));
});
