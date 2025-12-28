import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/domain/widget/widget_verse.dart';

class WidgetVerseStorage {
  WidgetVerseStorage({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName);

  static const _channelName = 'bible_widget/shared_verse';
  final MethodChannel _channel;

  Future<void> saveVerse(WidgetVerse verse) async {
    try {
      final jsonString = verse.toJsonString();
      debugPrint('[WidgetStorage] Saving verse: $jsonString');
      await _channel.invokeMethod<void>('saveVerse', jsonString);
      debugPrint('[WidgetStorage] Verse saved successfully');
    } catch (error, stackTrace) {
      debugPrint('[WidgetStorage] Failed to save verse: $error');
      debugPrint('$stackTrace');
    }
  }

  Future<WidgetVerse?> readVerse() async {
    try {
      final raw = await _channel.invokeMethod<String>('readVerse');
      return WidgetVerse.tryParse(raw);
    } catch (error, stackTrace) {
      debugPrint('Failed to read saved widget verse: $error');
      debugPrint('$stackTrace');
      return null;
    }
  }

  /// Returns the saved verse if it belongs to the current day
  Future<WidgetVerse?> getTodayVerse() async {
    try {
      final savedVerse = await readVerse();
      if (savedVerse == null) return null;

      // Check if the verse is from today
      final today = _getTodayDateString();
      if (savedVerse.date == today) {
        return savedVerse;
      }

      return null;
    } catch (error, stackTrace) {
      debugPrint('Failed to get today verse: $error');
      debugPrint('$stackTrace');
      return null;
    }
  }

  String _getTodayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> refreshWidgets() async {
    try {
      debugPrint('[WidgetStorage] Refreshing widgets...');
      await _channel.invokeMethod<void>('refreshWidgets');
      debugPrint('[WidgetStorage] Widgets refreshed successfully');
    } catch (error, stackTrace) {
      debugPrint('[WidgetStorage] Failed to request widget refresh: $error');
      debugPrint('$stackTrace');
    }
  }

  /// Requests an immediate widget update from the background worker
  Future<void> requestImmediateWidgetUpdate() async {
    try {
      await _channel.invokeMethod<void>('requestImmediateUpdate');
    } catch (error, stackTrace) {
      debugPrint('Failed to request immediate widget update: $error');
      debugPrint('$stackTrace');
    }
  }
}

final widgetVerseStorageProvider = Provider<WidgetVerseStorage>((ref) {
  return WidgetVerseStorage();
});
