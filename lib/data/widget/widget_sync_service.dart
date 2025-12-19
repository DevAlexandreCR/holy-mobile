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
    bool requestImmediateUpdate = false,
  }) async {
    final widgetVerse = WidgetVerse.fromVerseOfTheDay(
      verse,
      fontSize: fontSize,
    );
    try {
      debugPrint(
        '[WidgetSyncService] Starting sync for verse: ${verse.reference}',
      );

      // Guardar el verso
      await _storage.saveVerse(widgetVerse);

      // Esperar un poco más para asegurar que se guardó en UserDefaults compartido
      await Future.delayed(const Duration(milliseconds: 300));

      // Refrescar los widgets inmediatamente (primera vez)
      await _storage.refreshWidgets();

      // Esperar un poco y refrescar de nuevo para asegurar que el widget lo detecte
      await Future.delayed(const Duration(milliseconds: 200));
      await _storage.refreshWidgets();

      debugPrint('[WidgetSyncService] Sync completed successfully');

      // Si se solicita, programar una actualización inmediata del background worker
      if (requestImmediateUpdate) {
        debugPrint(
          '[WidgetSyncService] Requesting immediate background update',
        );
        await _storage.requestImmediateWidgetUpdate();
      }
    } catch (error, stackTrace) {
      debugPrint('[WidgetSyncService] Widget sync failed (non-fatal): $error');
      debugPrint('$stackTrace');
    }
  }
}

final widgetSyncServiceProvider = Provider<WidgetSyncService>((ref) {
  return WidgetSyncService(ref.watch(widgetVerseStorageProvider));
});
