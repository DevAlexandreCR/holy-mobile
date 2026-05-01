import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const double kDevotionalTextScaleMin = 0.9;
const double kDevotionalTextScaleMax = 1.5;

class DevotionalReadingSettingsState {
  const DevotionalReadingSettingsState({this.textScale = 1.0});

  final double textScale;

  DevotionalReadingSettingsState copyWith({double? textScale}) {
    return DevotionalReadingSettingsState(
      textScale: textScale ?? this.textScale,
    );
  }
}

class DevotionalReadingSettingsController
    extends Notifier<DevotionalReadingSettingsState> {
  static const String _textScaleKey = 'devotional_reader_text_scale';
  SharedPreferences? _prefs;
  bool _hasLocalUpdate = false;

  @override
  DevotionalReadingSettingsState build() {
    unawaited(_loadPersistedTextScale());
    return const DevotionalReadingSettingsState();
  }

  void updateTextScale(double value) {
    _hasLocalUpdate = true;
    _setTextScale(value);
  }

  void _setTextScale(double value) {
    final clamped = _clamp(value);
    if (clamped == state.textScale) {
      return;
    }
    state = state.copyWith(textScale: clamped);
  }

  Future<void> commitTextScale() {
    return _persistTextScale(state.textScale);
  }

  Future<void> resetTextScale() async {
    state = const DevotionalReadingSettingsState();
    await _persistTextScale(state.textScale);
  }

  Future<void> _loadPersistedTextScale() async {
    _prefs ??= await SharedPreferences.getInstance();
    if (!ref.mounted) {
      return;
    }
    final stored = _prefs?.getDouble(_textScaleKey);
    if (stored == null || _hasLocalUpdate) {
      return;
    }
    _setTextScale(stored);
  }

  Future<void> _persistTextScale(double value) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setDouble(_textScaleKey, _clamp(value));
  }

  double _clamp(double value) {
    return value
        .clamp(kDevotionalTextScaleMin, kDevotionalTextScaleMax)
        .toDouble();
  }
}

final devotionalReadingSettingsControllerProvider =
    NotifierProvider<
      DevotionalReadingSettingsController,
      DevotionalReadingSettingsState
    >(DevotionalReadingSettingsController.new);
