import 'package:flutter_test/flutter_test.dart';
import 'package:holyverso/domain/verse/verse_of_the_day.dart';
import 'package:holyverso/domain/widget/widget_verse.dart';

void main() {
  test('maps snake_case payload into VerseOfTheDay', () {
    final verse = VerseOfTheDay.fromMap({
      'date': '2024-06-01',
      'version_code': 'rv1960',
      'version_name': 'Reina-Valera 1960',
      'reference': 'Juan 3:16',
      'text': 'Porque de tal manera amó Dios al mundo...',
    });

    expect(verse.date, '2024-06-01');
    expect(verse.versionCode, 'rv1960');
    expect(verse.versionName, 'Reina-Valera 1960');
    expect(verse.reference, 'Juan 3:16');
    expect(verse.text, startsWith('Porque de tal'));
    expect(verse.displayVersionCode, 'RV1960');
  });

  test('maps camelCase payload into VerseOfTheDay', () {
    final verse = VerseOfTheDay.fromMap({
      'date': '2024-06-02',
      'versionCode': 'ntv',
      'versionName': 'Nueva Traducción Viviente',
      'reference': 'Salmos 23:1',
      'text': 'El Señor es mi pastor; tengo todo lo que necesito.',
    });

    expect(verse.versionCode, 'ntv');
    expect(verse.versionName, 'Nueva Traducción Viviente');
  });

  test('WidgetVerse parses and mirrors VerseOfTheDay', () {
    final verse = VerseOfTheDay.fromMap({
      'date': '2024-06-03',
      'version_code': 'dHH',
      'version_name': 'Dios Habla Hoy',
      'reference': 'Génesis 1:1',
      'text': 'En el principio creó Dios los cielos y la tierra.',
    });

    final widgetVerse = WidgetVerse.fromVerseOfTheDay(verse);
    expect(widgetVerse.versionCode, 'dHH');
    expect(widgetVerse.versionName, verse.versionName);
    expect(widgetVerse.reference, verse.reference);

    final encoded = widgetVerse.toJsonString();
    final decoded = WidgetVerse.tryParse(encoded);

    expect(decoded, isNotNull);
    expect(decoded!.versionCode, widgetVerse.versionCode);
    expect(WidgetVerse.tryParse('not-json'), isNull);
  });
}
