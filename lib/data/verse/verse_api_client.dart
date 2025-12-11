import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holy_mobile/data/network/api_client.dart';
import 'package:holy_mobile/domain/verse/verse_of_the_day.dart';

class VerseApiClient {
  VerseApiClient(this._dio);

  final Dio _dio;

  Future<VerseOfTheDay> getTodayVerse() async {
    final response = await _dio.get('/verse/today');
    final rawData = response.data;
    final data = rawData is Map ? rawData['data'] ?? rawData : rawData;

    if (data is Map) {
      return VerseOfTheDay.fromMap(Map<String, dynamic>.from(data));
    }

    throw StateError('Formato de versículo inesperado');
  }
}

final verseApiClientProvider = Provider<VerseApiClient>((ref) {
  return VerseApiClient(ref.watch(dioProvider));
});
