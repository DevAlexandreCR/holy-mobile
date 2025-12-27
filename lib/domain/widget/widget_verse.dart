import 'dart:convert';

import 'package:holyverso/domain/verse/verse_of_the_day.dart';

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
      isSaved: json['is_saved'] as bool? ??
          json['isSaved'] as bool? ??
          false,
      theme: json['theme'] as String?,
    );
  }

  factory WidgetVerse.fromVerseOfTheDay(
    VerseOfTheDay verse, {
    double fontSize = 16.0,
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
