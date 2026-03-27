import 'package:flutter_test/flutter_test.dart';
import 'package:holyverso/domain/devotionals/devotional_publish_validator.dart';

void main() {
  test('marks very short text as not ready', () {
    final result = DevotionalPublishValidator.evaluatePlainText('Hola');

    expect(result.isReady, isFalse);
    expect(result.wordCount, 1);
    expect(result.reason, DevotionalPublishFailureReason.needsMoreReflection);
  });

  test('requires sentence or paragraph structure in addition to length', () {
    final longSingleBlock = List.generate(
      48,
      (index) => 'palabra${index + 1}',
    ).join(' ');

    final result = DevotionalPublishValidator.evaluatePlainText(
      longSingleBlock,
    );

    expect(result.wordCount, 48);
    expect(result.plainTextLength, greaterThanOrEqualTo(220));
    expect(result.sentenceCount, 1);
    expect(result.meaningfulParagraphCount, 1);
    expect(result.isReady, isFalse);
  });

  test('accepts text with at least 45 words and 3 sentences', () {
    const text =
        'Cuando el cansancio pesa sobre el alma, Dios sigue acercandose con paciencia para recordarte que su gracia no depende de tu fuerza, sino de su fidelidad constante en medio del proceso. '
        'Aun en los dias donde no entiendes el rumbo, su palabra abre espacio para respirar, ordenar el corazon y volver a escuchar la verdad que sostiene tu fe. '
        'Si hoy avanzas despacio, camina igual, porque el Senor tambien trabaja en silencio y transforma tu historia mientras aprendes a confiar otra vez.';

    final result = DevotionalPublishValidator.evaluatePlainText(text);

    expect(result.wordCount, greaterThanOrEqualTo(45));
    expect(result.sentenceCount, 3);
    expect(result.isReady, isTrue);
    expect(result.reason, isNull);
  });

  test('accepts text with two meaningful paragraphs', () {
    final firstParagraph = List.generate(
      24,
      (index) => 'camino${index + 1}',
    ).join(' ');
    final secondParagraph = List.generate(
      24,
      (index) => 'esperanza${index + 1}',
    ).join(' ');

    final text = '$firstParagraph\n\n$secondParagraph';
    final result = DevotionalPublishValidator.evaluatePlainText(text);

    expect(result.wordCount, 48);
    expect(result.meaningfulParagraphCount, 2);
    expect(result.isReady, isTrue);
  });

  test('normalizes whitespace and newlines like the editor plain text', () {
    const text =
        '  Uno   dos  tres \n\n  cuatro cinco seis  \n\n\n siete ocho  ';

    final result = DevotionalPublishValidator.evaluatePlainText(text);

    expect(result.wordCount, 8);
    expect(result.sentenceCount, 1);
    expect(result.meaningfulParagraphCount, 0);
    expect(
      result.plainTextLength,
      'Uno dos tres cuatro cinco seis siete ocho'.length,
    );
  });
}
