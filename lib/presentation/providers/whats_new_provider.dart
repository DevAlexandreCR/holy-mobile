import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/core/services/version_detector_service.dart';
import 'package:holyverso/data/repositories/release_notes_repository.dart';
import 'package:holyverso/domain/models/release_note.dart';

final whatsNewProvider = FutureProvider<ReleaseNote?>((ref) async {
  final versionDetector = ref.read(versionDetectorServiceProvider);
  final shouldShow = await versionDetector.shouldShowWhatsNew();
  if (!shouldShow) {
    return null;
  }

  final currentVersion = await versionDetector.getCurrentVersion();
  final repository = ref.read(releaseNotesRepositoryProvider);
  final note = await repository.getReleaseNote(currentVersion);

  if (note == null) {
    await versionDetector.markVersionAsSeen();
  }

  return note;
});
