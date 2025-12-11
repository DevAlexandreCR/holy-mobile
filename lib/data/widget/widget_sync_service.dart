import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holy_mobile/data/widget/widget_verse_storage.dart';
import 'package:holy_mobile/domain/verse/verse_of_the_day.dart';
import 'package:holy_mobile/domain/widget/widget_verse.dart';

class WidgetSyncService {
  WidgetSyncService(this._storage);

  final WidgetVerseStorage _storage;

  Future<void> syncLatestVerse(VerseOfTheDay verse) async {
    final widgetVerse = WidgetVerse.fromVerseOfTheDay(verse);
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
