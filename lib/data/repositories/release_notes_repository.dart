import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/domain/models/release_note.dart';

class ReleaseNotesRepository {
  ReleaseNotesRepository(this._bundle);

  static const _assetPath = 'assets/data/release_notes.json';

  final AssetBundle _bundle;
  List<ReleaseNote>? _cache;

  Future<ReleaseNote?> getReleaseNote(String version) async {
    final notes = await _loadNotes();
    for (final note in notes) {
      if (note.version == version) {
        return note;
      }
    }
    return null;
  }

  Future<List<ReleaseNote>> _loadNotes() async {
    if (_cache != null) {
      return _cache!;
    }

    try {
      final raw = await _bundle.loadString(_assetPath);
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final releases = decoded['releases'];
        if (releases is List) {
          _cache = releases
              .whereType<Map<String, dynamic>>()
              .map(ReleaseNote.fromMap)
              .toList();
        } else {
          _cache = const [];
        }
      } else {
        _cache = const [];
      }
    } catch (_) {
      _cache = const [];
    }

    return _cache!;
  }
}

final releaseNotesRepositoryProvider = Provider<ReleaseNotesRepository>((ref) {
  return ReleaseNotesRepository(rootBundle);
});
