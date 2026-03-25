import 'package:flutter_test/flutter_test.dart';
import 'package:holyverso/domain/verse/bible_book.dart';

void main() {
  test('maps bible book payload', () {
    final book = BibleBook.fromMap({
      'name': 'Génesis',
      'abbrev': 'gen',
      'chapters': 50,
      'testament': 'old',
    });

    expect(book.name, 'Génesis');
    expect(book.abbrev, 'gen');
    expect(book.chapters, 50);
    expect(book.testament, 'old');
  });

  test('maps bible api payload with names and abrev', () {
    final book = BibleBook.fromMap({
      'names': ['Juan', 'John'],
      'abrev': 'JN',
      'chapters': 21,
      'testament': 'Nuevo Testamento',
    });

    expect(book.name, 'Juan');
    expect(book.abbrev, 'JN');
    expect(book.chapters, 21);
    expect(book.testament, 'Nuevo Testamento');
  });
}
