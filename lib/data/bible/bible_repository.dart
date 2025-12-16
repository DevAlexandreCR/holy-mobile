import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/data/bible/bible_api_client.dart';
import 'package:holyverso/data/bible/models/bible_version.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BibleRepository {
  BibleRepository(this._client);

  final BibleApiClient _client;
  List<BibleVersion>? _inMemoryCache;
  SharedPreferences? _prefs;

  static const _cacheKey = 'cached_bible_versions';

  Future<List<BibleVersion>> fetchVersions({bool forceRefresh = false}) async {
    if (!forceRefresh && _inMemoryCache != null && _inMemoryCache!.isNotEmpty) {
      return _inMemoryCache!;
    }

    if (!forceRefresh) {
      final cached = await _readFromStorage();
      if (cached.isNotEmpty) {
        _inMemoryCache = cached;
        return cached;
      }
    }

    try {
      final versions = await _client.getVersions();
      _inMemoryCache = versions;
      await _writeToStorage(versions);
      return versions;
    } catch (error) {
      if (_inMemoryCache != null && _inMemoryCache!.isNotEmpty) {
        return _inMemoryCache!;
      }
      rethrow;
    }
  }

  Future<List<BibleVersion>> _readFromStorage() async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_cacheKey);
    if (raw == null) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((item) => BibleVersion.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (_) {
      // ignore malformed cache and return empty
    }

    return const [];
  }

  Future<void> _writeToStorage(List<BibleVersion> versions) async {
    _prefs ??= await SharedPreferences.getInstance();
    final serialized = jsonEncode(versions.map((v) => v.toMap()).toList());
    await _prefs!.setString(_cacheKey, serialized);
  }
}

final bibleRepositoryProvider = Provider<BibleRepository>((ref) {
  return BibleRepository(ref.watch(bibleApiClientProvider));
});
