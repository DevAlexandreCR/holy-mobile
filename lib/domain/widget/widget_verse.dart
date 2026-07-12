import 'dart:convert';
import 'dart:math';

import 'package:holyverso/domain/verse/verse_of_the_day.dart';

enum WidgetVerseDisplayVariant {
  verseOnly('verse_only'),
  continuation('continuation'),
  presenceHint('presence_hint');

  const WidgetVerseDisplayVariant(this.value);

  final String value;

  static WidgetVerseDisplayVariant fromValue(String? value) {
    return switch (value) {
      'continuation' => WidgetVerseDisplayVariant.continuation,
      'presence_hint' => WidgetVerseDisplayVariant.presenceHint,
      _ => WidgetVerseDisplayVariant.verseOnly,
    };
  }
}

class WidgetVerseDisplaySelection {
  const WidgetVerseDisplaySelection({
    required this.variant,
    this.secondaryLine,
  });

  final WidgetVerseDisplayVariant variant;
  final String? secondaryLine;

  static const _continuationLines = [
    'Descubre el mensaje de hoy',
    'Hoy hay más para ti',
  ];

  static const _presenceHintLines = [
    'Nuevos devocionales hoy',
    'Otros están leyendo hoy',
  ];

  static const fallbackSecondaryLine = 'Descubre el mensaje de hoy';

  static WidgetVerseDisplaySelection pick([Random? random]) {
    final resolvedRandom = random ?? Random();
    final roll = resolvedRandom.nextInt(100);

    if (roll < 65) {
      return WidgetVerseDisplaySelection(
        variant: WidgetVerseDisplayVariant.continuation,
        secondaryLine:
            _continuationLines[resolvedRandom.nextInt(
              _continuationLines.length,
            )],
      );
    }

    return WidgetVerseDisplaySelection(
      variant: WidgetVerseDisplayVariant.presenceHint,
      secondaryLine:
          _presenceHintLines[resolvedRandom.nextInt(_presenceHintLines.length)],
    );
  }
}

class WidgetVerse {
  const WidgetVerse({
    required this.date,
    required this.versionCode,
    required this.versionName,
    required this.reference,
    required this.text,
    this.fontSize = 16.0,
    this.libraryVerseId,
    this.isSaved = false,
    this.theme,
    this.displayVariant = WidgetVerseDisplayVariant.verseOnly,
    this.secondaryLine,
    this.streakCount,
    this.completedToday,
  });

  final String date;
  final String versionCode;
  final String versionName;
  final String reference;
  final String text;
  final double fontSize;
  final int? libraryVerseId;
  final bool isSaved;
  final String? theme;
  final WidgetVerseDisplayVariant displayVariant;
  final String? secondaryLine;
  final int? streakCount;
  final bool? completedToday;

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'version_code': versionCode,
      'version_name': versionName,
      'reference': reference,
      'text': text,
      'font_size': fontSize,
      if (libraryVerseId != null) 'library_verse_id': libraryVerseId,
      'is_saved': isSaved,
      if (theme != null) 'theme': theme,
      'display_variant': displayVariant.value,
      if (secondaryLine != null) 'secondary_line': secondaryLine,
      if (streakCount != null) 'streak_count': streakCount,
      if (completedToday != null) 'completed_today': completedToday,
    };
  }

  factory WidgetVerse.fromJson(Map<String, dynamic> json) {
    return WidgetVerse(
      date: json['date'] as String? ?? '',
      versionCode:
          json['version_code'] as String? ??
          json['versionCode'] as String? ??
          '',
      versionName:
          json['version_name'] as String? ??
          json['versionName'] as String? ??
          '',
      reference: json['reference'] as String? ?? '',
      text: json['text'] as String? ?? '',
      fontSize: (json['font_size'] as num?)?.toDouble() ?? 16.0,
      libraryVerseId:
          (json['library_verse_id'] as num?)?.toInt() ??
          (json['libraryVerseId'] as num?)?.toInt(),
      isSaved: json['is_saved'] as bool? ?? json['isSaved'] as bool? ?? false,
      theme: json['theme'] as String?,
      displayVariant: WidgetVerseDisplayVariant.fromValue(
        json['display_variant'] as String? ?? json['displayVariant'] as String?,
      ),
      secondaryLine:
          json['secondary_line'] as String? ?? json['secondaryLine'] as String?,
      streakCount:
          (json['streak_count'] as num?)?.toInt() ??
          (json['streakCount'] as num?)?.toInt(),
      completedToday:
          json['completed_today'] as bool? ?? json['completedToday'] as bool?,
    );
  }

  factory WidgetVerse.fromVerseOfTheDay(
    VerseOfTheDay verse, {
    double fontSize = 16.0,
    WidgetVerseDisplayVariant displayVariant =
        WidgetVerseDisplayVariant.verseOnly,
    String? secondaryLine,
    int? streakCount,
    bool? completedToday,
  }) {
    return WidgetVerse(
      date: verse.date,
      versionCode: verse.versionCode,
      versionName: verse.versionName,
      reference: verse.reference,
      text: verse.text,
      fontSize: fontSize,
      libraryVerseId: verse.libraryVerseId,
      isSaved: verse.isSaved,
      theme: verse.theme,
      displayVariant: displayVariant,
      secondaryLine: secondaryLine,
      streakCount: streakCount,
      completedToday: completedToday,
    );
  }

  WidgetVerse copyWith({
    String? date,
    String? versionCode,
    String? versionName,
    String? reference,
    String? text,
    double? fontSize,
    int? libraryVerseId,
    bool? isSaved,
    String? theme,
    WidgetVerseDisplayVariant? displayVariant,
    String? secondaryLine,
    int? streakCount,
    bool? completedToday,
  }) {
    return WidgetVerse(
      date: date ?? this.date,
      versionCode: versionCode ?? this.versionCode,
      versionName: versionName ?? this.versionName,
      reference: reference ?? this.reference,
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
      libraryVerseId: libraryVerseId ?? this.libraryVerseId,
      isSaved: isSaved ?? this.isSaved,
      theme: theme ?? this.theme,
      displayVariant: displayVariant ?? this.displayVariant,
      secondaryLine: secondaryLine ?? this.secondaryLine,
      streakCount: streakCount ?? this.streakCount,
      completedToday: completedToday ?? this.completedToday,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  static WidgetVerse? tryParse(String? rawJson) {
    if (rawJson == null || rawJson.isEmpty) return null;
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is Map) {
        return WidgetVerse.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      // Ignore malformed data
    }
    return null;
  }
}
