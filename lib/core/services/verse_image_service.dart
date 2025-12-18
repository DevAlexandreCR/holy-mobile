import 'dart:io';
import 'package:flutter/material.dart';
import 'package:holyverso/domain/verse/verse_of_the_day.dart';
import 'package:holyverso/presentation/widgets/verse_image_card.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

/// Service for generating and sharing verses as images.
class VerseImageService {
  final ScreenshotController _screenshotController = ScreenshotController();

  /// Generates an image from a verse and shares it.
  ///
  /// [verse] - The verse to be rendered as an image.
  /// [sharePositionOrigin] - Optional rect for iPad share popover positioning.
  /// [subject] - Optional subject text for the share dialog.
  Future<void> shareVerseAsImage(
    VerseOfTheDay verse, {
    Rect? sharePositionOrigin,
    String? subject,
  }) async {
    try {
      // Capture the widget as an image
      final imageBytes = await _screenshotController.captureFromWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Material(
            color: Colors.transparent,
            child: VerseImageCard(verse: verse),
          ),
        ),
        delay: const Duration(milliseconds: 100),
        context: null,
        pixelRatio: 2.0,
      );

      // Save the image to a temporary file
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'holyverso_verse_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(imageBytes);

      // Share the image
      final xFile = XFile(file.path);
      await Share.shareXFiles(
        [xFile],
        subject: subject ?? 'Versículo del día',
        sharePositionOrigin: sharePositionOrigin,
      );

      // Clean up the temporary file after a delay
      Future.delayed(const Duration(seconds: 5), () {
        if (file.existsSync()) {
          file.delete();
        }
      });
    } catch (e) {
      debugPrint('Error sharing verse as image: $e');
      rethrow;
    }
  }

  /// Generates an image from a verse and saves it to the gallery.
  ///
  /// [verse] - The verse to be rendered as an image.
  /// Returns the path to the saved file.
  Future<String> saveVerseAsImage(VerseOfTheDay verse) async {
    try {
      // Capture the widget as an image
      final imageBytes = await _screenshotController.captureFromWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Material(
            color: Colors.transparent,
            child: VerseImageCard(verse: verse),
          ),
        ),
        delay: const Duration(milliseconds: 100),
        context: null,
        pixelRatio: 2.0,
      );

      // Save to app's documents directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'holyverso_verse_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      return filePath;
    } catch (e) {
      debugPrint('Error saving verse as image: $e');
      rethrow;
    }
  }
}
