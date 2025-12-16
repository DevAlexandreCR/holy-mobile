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
