import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VersionDetectorService {
  VersionDetectorService({SharedPreferences? preferences})
      : _preferences = preferences;

  static const _versionKey = 'last_seen_app_version';
  SharedPreferences? _preferences;

  Future<bool> shouldShowWhatsNew() async {
    final currentVersion = await getCurrentVersion();
    final lastSeenVersion = await getLastSeenVersion();

    if (lastSeenVersion == null || lastSeenVersion.isEmpty) {
      await _setLastSeenVersion(currentVersion);
      return false;
    }

    final comparison = _compareVersions(currentVersion, lastSeenVersion);
    if (comparison <= 0) {
      return false;
    }

    return true;
  }

  Future<void> markVersionAsSeen() async {
    final currentVersion = await getCurrentVersion();
    await _setLastSeenVersion(currentVersion);
  }

  Future<String> getCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  Future<String?> getLastSeenVersion() async {
    _preferences ??= await SharedPreferences.getInstance();
    return _preferences!.getString(_versionKey);
  }

  Future<void> _setLastSeenVersion(String version) async {
    _preferences ??= await SharedPreferences.getInstance();
    await _preferences!.setString(_versionKey, version);
  }

  int _compareVersions(String current, String lastSeen) {
    final currentParts = _parseVersion(current);
    final lastSeenParts = _parseVersion(lastSeen);
    final length = max(currentParts.length, lastSeenParts.length);

    for (var i = 0; i < length; i++) {
      final currentValue = i < currentParts.length ? currentParts[i] : 0;
      final lastSeenValue = i < lastSeenParts.length ? lastSeenParts[i] : 0;
      if (currentValue != lastSeenValue) {
        return currentValue.compareTo(lastSeenValue);
      }
    }

    return 0;
  }

  List<int> _parseVersion(String version) {
    return version
        .split('.')
        .map(
          (segment) =>
              int.tryParse(RegExp(r'\d+').stringMatch(segment) ?? '0') ?? 0,
        )
        .toList();
  }
}

final versionDetectorServiceProvider = Provider<VersionDetectorService>((ref) {
  return VersionDetectorService();
});
