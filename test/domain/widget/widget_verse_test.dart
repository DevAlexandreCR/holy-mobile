import 'package:flutter_test/flutter_test.dart';
import 'package:holyverso/domain/widget/widget_verse.dart';

void main() {
  test(
    'keeps backward compatibility when legacy payload lacks display fields',
    () {
      final verse = WidgetVerse.fromJson({
        'date': '2026-03-27',
        'version_code': 'RVR1960',
        'version_name': 'Reina-Valera 1960',
        'reference': 'Juan 3:16',
        'text': 'Porque de tal manera amó Dios al mundo...',
        'font_size': 16.0,
      });

      expect(verse.displayVariant, WidgetVerseDisplayVariant.verseOnly);
      expect(verse.secondaryLine, isNull);
    },
  );

  test('serializes display variant fields when present', () {
    const verse = WidgetVerse(
      date: '2026-03-27',
      versionCode: 'RVR1960',
      versionName: 'Reina-Valera 1960',
      reference: 'Juan 3:16',
      text: 'Porque de tal manera amó Dios al mundo...',
      displayVariant: WidgetVerseDisplayVariant.presenceHint,
      secondaryLine: 'Nuevos devocionales hoy',
    );

    final json = verse.toJson();

    expect(json['display_variant'], 'presence_hint');
    expect(json['secondary_line'], 'Nuevos devocionales hoy');
  });
}
