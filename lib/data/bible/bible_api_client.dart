import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holy_mobile/data/bible/models/bible_version.dart';
import 'package:holy_mobile/data/network/api_client.dart';

class BibleApiClient {
  BibleApiClient(this._dio);

  final Dio _dio;

  Future<List<BibleVersion>> getVersions() async {
    final response = await _dio.get('/bible/versions');
    final rawData = response.data;
    final data = rawData is Map ? rawData['data'] ?? rawData : rawData;

    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => BibleVersion.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    }

    return const [];
  }
}

final bibleApiClientProvider = Provider<BibleApiClient>((ref) {
  return BibleApiClient(ref.watch(dioProvider));
});
