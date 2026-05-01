import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holyverso/presentation/state/devotionals/devotional_reading_settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const key = 'devotional_reader_text_scale';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('clamps text scale to devotional reading bounds', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(devotionalReadingSettingsControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final controller = container.read(
      devotionalReadingSettingsControllerProvider.notifier,
    );

    controller.updateTextScale(2);
    expect(
      container.read(devotionalReadingSettingsControllerProvider).textScale,
      kDevotionalTextScaleMax,
    );

    controller.updateTextScale(0.2);
    expect(
      container.read(devotionalReadingSettingsControllerProvider).textScale,
      kDevotionalTextScaleMin,
    );
  });

  test('updates text scale transiently before persisting it', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(devotionalReadingSettingsControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final controller = container.read(
      devotionalReadingSettingsControllerProvider.notifier,
    );
    final prefs = await SharedPreferences.getInstance();

    controller.updateTextScale(1.24);
    expect(
      container.read(devotionalReadingSettingsControllerProvider).textScale,
      1.24,
    );
    expect(prefs.getDouble(key), isNull);

    await controller.commitTextScale();

    expect(prefs.getDouble(key), 1.24);
  });

  test('restores persisted text scale', () async {
    SharedPreferences.setMockInitialValues({key: 1.18});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(devotionalReadingSettingsControllerProvider);

    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(
      container.read(devotionalReadingSettingsControllerProvider).textScale,
      1.18,
    );
  });
}
