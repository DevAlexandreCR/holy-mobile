import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppRuntimeStorage {
  static const _deviceIdKey = 'phase3.device_id';
  static const _pendingShareTokenKey = 'phase3.pending_share_token';
  static const _pushTokenKey = 'phase3.push_token';
  static const _lastSeenAppVersionKey = 'phase3.last_seen_app_version';
  static const _notificationPromptAttemptVersionKey =
      'phase3.notification_prompt_attempt_version';

  SharedPreferences? _preferences;

  Future<String> getOrCreateDeviceId() async {
    final preferences = await _instance;
    final existing = preferences.getString(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final value = _generateUuid();
    await preferences.setString(_deviceIdKey, value);
    return value;
  }

  Future<bool> hasDeviceId() async {
    final preferences = await _instance;
    final value = preferences.getString(_deviceIdKey);
    return value != null && value.isNotEmpty;
  }

  Future<void> savePendingShareToken(String token) async {
    final preferences = await _instance;
    await preferences.setString(_pendingShareTokenKey, token);
  }

  Future<String?> readPendingShareToken() async {
    final preferences = await _instance;
    final token = preferences.getString(_pendingShareTokenKey);
    if (token == null || token.isEmpty) {
      return null;
    }
    return token;
  }

  Future<void> clearPendingShareToken() async {
    final preferences = await _instance;
    await preferences.remove(_pendingShareTokenKey);
  }

  Future<void> savePushToken(String token) async {
    final preferences = await _instance;
    await preferences.setString(_pushTokenKey, token);
  }

  Future<String?> readPushToken() async {
    final preferences = await _instance;
    final token = preferences.getString(_pushTokenKey);
    if (token == null || token.isEmpty) {
      return null;
    }
    return token;
  }

  Future<void> clearPushToken() async {
    final preferences = await _instance;
    await preferences.remove(_pushTokenKey);
  }

  Future<void> saveLastSeenAppVersion(String version) async {
    final preferences = await _instance;
    await preferences.setString(_lastSeenAppVersionKey, version);
  }

  Future<String?> readLastSeenAppVersion() async {
    final preferences = await _instance;
    final version = preferences.getString(_lastSeenAppVersionKey);
    if (version == null || version.isEmpty) {
      return null;
    }
    return version;
  }

  Future<void> saveNotificationPromptAttemptVersion(String version) async {
    final preferences = await _instance;
    await preferences.setString(_notificationPromptAttemptVersionKey, version);
  }

  Future<String?> readNotificationPromptAttemptVersion() async {
    final preferences = await _instance;
    final version = preferences.getString(_notificationPromptAttemptVersionKey);
    if (version == null || version.isEmpty) {
      return null;
    }
    return version;
  }

  Future<SharedPreferences> get _instance async {
    _preferences ??= await SharedPreferences.getInstance();
    return _preferences!;
  }

  String _generateUuid() {
    final random = Random.secure();
    String segment(int length) => List.generate(
      length,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();

    return '${segment(8)}-${segment(4)}-4${segment(3)}-'
        '${['8', '9', 'a', 'b'][random.nextInt(4)]}${segment(3)}-'
        '${segment(12)}';
  }
}

final appRuntimeStorageProvider = Provider<AppRuntimeStorage>((ref) {
  return AppRuntimeStorage();
});
