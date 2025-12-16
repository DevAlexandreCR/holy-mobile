import 'dart:convert';

import 'package:holyverso/domain/verse/verse_of_the_day.dart';

class WidgetVerse {
  const WidgetVerse({
    required this.date,
    required this.versionCode,
    required this.versionName,
    required this.reference,
    required this.text,
  });

  final String date;
  final String versionCode;
  final String versionName;
  final String reference;
  final String text;

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'version_code': versionCode,
      'version_name': versionName,
      'reference': reference,
      'text': text,
    };
  }

  factory WidgetVerse.fromJson(Map<String, dynamic> json) {
    return WidgetVerse(
      date: json['date'] as String? ?? '',
      versionCode: json['version_code'] as String? ?? json['versionCode'] as String? ?? '',
      versionName: json['version_name'] as String? ?? json['versionName'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
      text: json['text'] as String? ?? '',
    );
  }

  factory WidgetVerse.fromVerseOfTheDay(VerseOfTheDay verse) {
    return WidgetVerse(
      date: verse.date,
      versionCode: verse.versionCode,
      versionName: verse.versionName,
      reference: verse.reference,
      text: verse.text,
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
