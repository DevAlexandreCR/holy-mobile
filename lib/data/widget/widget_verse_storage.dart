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
      await _channel.invokeMethod<void>('saveVerse', verse.toJsonString());
    } catch (error, stackTrace) {
      debugPrint('Failed to save verse for widgets: $error');
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

  /// Verifica si hay un verso guardado para el día actual
  Future<WidgetVerse?> getTodayVerse() async {
    try {
      final savedVerse = await readVerse();
      if (savedVerse == null) return null;

      // Verificar si el verso es de hoy
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
      await _channel.invokeMethod<void>('refreshWidgets');
    } catch (error, stackTrace) {
      debugPrint('Failed to request widget refresh: $error');
      debugPrint('$stackTrace');
    }
  }
}

final widgetVerseStorageProvider = Provider<WidgetVerseStorage>((ref) {
  return WidgetVerseStorage();
});
