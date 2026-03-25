import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';

class AppConfig {
  final String baseApiUrl;
  final Duration requestTimeout;
  final String genericErrorMessage;
  final String networkErrorMessage;
  final FirebaseOptions? firebaseOptions;

  const AppConfig({
    required this.baseApiUrl,
    required this.requestTimeout,
    required this.genericErrorMessage,
    required this.networkErrorMessage,
    required this.firebaseOptions,
  });

  /// Load configuration from .env files (dotenv must be loaded first in main)
  static AppConfig load() {
    const l10n = AppLocalizations(Locale('es'));

    return AppConfig(
      baseApiUrl: _getEnv('API_URL', fallback: 'http://localhost:3000'),
      requestTimeout: Duration(
        seconds: int.parse(_getEnv('REQUEST_TIMEOUT', fallback: '15')),
      ),
      genericErrorMessage: l10n.genericError,
      networkErrorMessage: l10n.networkError,
      firebaseOptions: _loadFirebaseOptions(),
    );
  }

  static FirebaseOptions? _loadFirebaseOptions() {
    final projectId = _maybeGetEnv('FIREBASE_PROJECT_ID');
    final messagingSenderId = _maybeGetEnv('FIREBASE_MESSAGING_SENDER_ID');
    final storageBucket = _maybeGetEnv('FIREBASE_STORAGE_BUCKET');

    if (projectId == null ||
        projectId.isEmpty ||
        messagingSenderId == null ||
        messagingSenderId.isEmpty) {
      return null;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final apiKey = _maybeGetEnv('FIREBASE_ANDROID_API_KEY');
        final appId = _maybeGetEnv('FIREBASE_ANDROID_APP_ID');
        if (apiKey == null ||
            apiKey.isEmpty ||
            appId == null ||
            appId.isEmpty) {
          return null;
        }

        return FirebaseOptions(
          apiKey: apiKey,
          appId: appId,
          messagingSenderId: messagingSenderId,
          projectId: projectId,
          storageBucket: storageBucket,
        );
      case TargetPlatform.iOS:
        final apiKey = _maybeGetEnv('FIREBASE_IOS_API_KEY');
        final appId = _maybeGetEnv('FIREBASE_IOS_APP_ID');
        final bundleId = _maybeGetEnv('FIREBASE_IOS_BUNDLE_ID');
        if (apiKey == null ||
            apiKey.isEmpty ||
            appId == null ||
            appId.isEmpty) {
          return null;
        }

        return FirebaseOptions(
          apiKey: apiKey,
          appId: appId,
          messagingSenderId: messagingSenderId,
          projectId: projectId,
          storageBucket: storageBucket,
          iosBundleId: bundleId,
        );
      default:
        return null;
    }
  }

  static String _getEnv(String key, {required String fallback}) {
    try {
      return dotenv.get(key, fallback: fallback);
    } catch (_) {
      return fallback;
    }
  }

  static String? _maybeGetEnv(String key) {
    try {
      final value = dotenv.maybeGet(key);
      if (value == null || value.isEmpty) {
        return null;
      }
      return value;
    } catch (_) {
      return null;
    }
  }
}

final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.load();
});
