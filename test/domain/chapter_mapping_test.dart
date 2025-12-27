import 'package:flutter_test/flutter_test.dart';
import 'package:holyverso/domain/verse/chapter.dart';

void main() {
  test('maps chapter payload with verses', () {
    final chapter = Chapter.fromMap({
      'book': 'genesis',
      'chapter': 1,
      'reference': 'Génesis 1',
      'num_chapters': 50,
      'version_code': 'rv1960',
      'version_name': 'Reina-Valera 1960',
      'verses': [
        {
          'number': 1,
          'text': 'En el principio creó Dios los cielos y la tierra.',
          'study': 'La Creación',
        },
        {'number': 2, 'text': 'Y la tierra estaba desordenada y vacía...'},
      ],
    });

    expect(chapter.book, 'genesis');
    expect(chapter.chapter, 1);
    expect(chapter.reference, 'Génesis 1');
    expect(chapter.verses, hasLength(2));
    expect(chapter.verses.first.number, 1);
    expect(chapter.verses.first.study, 'La Creación');
    expect(chapter.displayVersionCode, 'RV1960');
  });
}
