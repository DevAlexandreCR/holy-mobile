import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/data/widget/widget_verse_storage.dart';
import 'package:holyverso/domain/verse/verse_of_the_day.dart';
import 'package:holyverso/domain/widget/widget_verse.dart';

class WidgetSyncService {
  WidgetSyncService(this._storage);

  final WidgetVerseStorage _storage;

  Future<void> syncLatestVerse(
    VerseOfTheDay verse, {
    double fontSize = 16.0,
  }) async {
    final widgetVerse = WidgetVerse.fromVerseOfTheDay(
      verse,
      fontSize: fontSize,
    );
    try {
      await _storage.saveVerse(widgetVerse);
      await _storage.refreshWidgets();
    } catch (error, stackTrace) {
      debugPrint('Widget sync failed (non-fatal): $error');
      debugPrint('$stackTrace');
    }
  }
}

final widgetSyncServiceProvider = Provider<WidgetSyncService>((ref) {
  return WidgetSyncService(ref.watch(widgetVerseStorageProvider));
});
