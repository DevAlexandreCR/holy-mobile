import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:holyverso/core/config/app_config.dart';
import 'package:holyverso/core/services/app_runtime_storage.dart';
import 'package:holyverso/core/services/push_messaging_client.dart';
import 'package:holyverso/data/analytics/analytics_api_client.dart';
import 'package:holyverso/data/notifications/notification_api_client.dart';
import 'package:holyverso/data/share_attribution/share_attribution_api_client.dart';
import 'package:package_info_plus/package_info_plus.dart';

enum PushPermissionRequestResult { granted, denied, unavailable }

class PhaseThreeRuntimeService {
  PhaseThreeRuntimeService({
    required AppConfig appConfig,
    required AppRuntimeStorage storage,
    required PushMessagingClient pushMessagingClient,
    required AnalyticsApiClient analyticsApiClient,
    required NotificationApiClient notificationApiClient,
    required ShareAttributionApiClient shareAttributionApiClient,
    AppLinks? appLinks,
    Future<String?> Function()? appVersionResolver,
    Future<bool> Function(AppConfig appConfig)? firebaseBootstrapper,
  }) : _appConfig = appConfig,
       _storage = storage,
       _pushMessagingClient = pushMessagingClient,
       _analyticsApiClient = analyticsApiClient,
       _notificationApiClient = notificationApiClient,
       _shareAttributionApiClient = shareAttributionApiClient,
       _appLinks = appLinks,
       _appVersionResolver = appVersionResolver ?? _defaultAppVersionResolver,
       _firebaseBootstrapper =
           firebaseBootstrapper ?? _defaultFirebaseBootstrapper;

  final AppConfig _appConfig;
  final AppRuntimeStorage _storage;
  final PushMessagingClient _pushMessagingClient;
  final AnalyticsApiClient _analyticsApiClient;
  final NotificationApiClient _notificationApiClient;
  final ShareAttributionApiClient _shareAttributionApiClient;
  final AppLinks? _appLinks;
  final Future<String?> Function() _appVersionResolver;
  final Future<bool> Function(AppConfig appConfig) _firebaseBootstrapper;

  StreamSubscription<Uri>? _appLinkSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<PushNotificationMessage>? _notificationOpenSubscription;
  GoRouter? _router;
  String? _deviceId;
  String? _currentUserId;
  DateTime? _lastAppSessionAt;
  bool _installDetectedThisLaunch = false;
  bool _isAuthenticated = false;
  bool _isFirebaseReady = false;
  bool _started = false;
  bool _hasCheckedAutomaticPermissionPromptThisLaunch = false;

  bool get _supportsPush =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  void attachRouter(GoRouter router) {
    _router = router;
  }

  Future<void> start(GoRouter router) async {
    attachRouter(router);
    if (_started) {
      return;
    }

    _started = true;
    final hadDeviceId = await _storage.hasDeviceId();
    _deviceId = await _storage.getOrCreateDeviceId();
    _installDetectedThisLaunch = !hadDeviceId;

    _listenToAppLinks();
    await _consumeInitialLink();

    if (!await _ensureFirebaseReady()) {
      return;
    }

    _notificationOpenSubscription = _pushMessagingClient.onMessageOpenedApp
        .listen(_handleNotificationOpen);
    _tokenRefreshSubscription = _pushMessagingClient.onTokenRefresh.listen(
      _handleTokenRefresh,
    );
    await _consumeInitialNotification();
  }

  Future<void> syncSession({
    required bool isAuthenticated,
    String? userId,
    bool forceSessionStart = false,
  }) async {
    _isAuthenticated = isAuthenticated;
    _currentUserId = isAuthenticated ? userId : null;

    if (!isAuthenticated || userId == null || userId.isEmpty) {
      return;
    }

    await _recordAppSessionIfNeeded(force: forceSessionStart);
    await _maybePromptForNotificationPermissionOnVersionEntry();
    await _syncPushState();
  }

  Future<void> handleAppResumed() async {
    if (!_isAuthenticated || _currentUserId == null) {
      return;
    }

    await _recordAppSessionIfNeeded();
    await _syncPushState();
  }

  Future<PushPermissionRequestResult> requestNotificationPermission() async {
    if (!await _ensureFirebaseReady()) {
      return PushPermissionRequestResult.unavailable;
    }

    final currentSettings = await _pushMessagingClient
        .getNotificationSettings();
    if (_isAuthorized(currentSettings.authorizationStatus)) {
      await _syncPushState();
      return PushPermissionRequestResult.granted;
    }

    final updatedSettings = await _pushMessagingClient.requestPermission();
    await _syncPushState();

    return _isAuthorized(updatedSettings.authorizationStatus)
        ? PushPermissionRequestResult.granted
        : PushPermissionRequestResult.denied;
  }

  Future<void> prepareForSignOut() async {
    final token = await _storage.readPushToken();
    if (token == null || token.isEmpty || !_isAuthenticated) {
      return;
    }

    try {
      await _notificationApiClient.deleteDeviceToken(token: token);
    } catch (_) {}

    await _storage.clearPushToken();
  }

  Future<void> discardPendingShareAttribution() {
    return _storage.clearPendingShareToken();
  }

  Future<void> handleRegistrationCompleted() async {
    final token = await _storage.readPendingShareToken();
    if (token == null || token.isEmpty) {
      return;
    }

    try {
      await _shareAttributionApiClient.recordAppOpen(
        token: token,
        deviceId: await _resolveDeviceId(),
        registrationCompleted: true,
      );
      await _storage.clearPendingShareToken();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _appLinkSubscription?.cancel();
    await _tokenRefreshSubscription?.cancel();
    await _notificationOpenSubscription?.cancel();
  }

  Future<bool> _ensureFirebaseReady() async {
    if (!_supportsPush) {
      return false;
    }

    if (_isFirebaseReady) {
      return true;
    }

    try {
      final bootstrapped = await _firebaseBootstrapper(_appConfig);
      if (!bootstrapped) {
        return false;
      }

      await _pushMessagingClient.setAutoInitEnabled(true);
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _pushMessagingClient.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      _isFirebaseReady = true;
      return true;
    } catch (error) {
      debugPrint('[Phase3Runtime] Firebase initialization failed: $error');
      return false;
    }
  }

  void _listenToAppLinks() {
    final appLinks = _appLinks;
    if (appLinks == null) {
      return;
    }

    _appLinkSubscription = appLinks.uriLinkStream.listen((uri) {
      unawaited(_handleIncomingUri(uri));
    });
  }

  Future<void> _consumeInitialLink() async {
    final appLinks = _appLinks;
    if (appLinks == null) {
      return;
    }

    try {
      final uri = await appLinks.getInitialLink();
      if (uri != null) {
        await _handleIncomingUri(uri);
      }
    } catch (_) {}
  }

  Future<void> _consumeInitialNotification() async {
    try {
      final message = await _pushMessagingClient.getInitialMessage();
      if (message != null) {
        await _handleNotificationOpen(message);
      }
    } catch (_) {}
  }

  Future<void> _handleNotificationOpen(PushNotificationMessage message) async {
    final devotionalId = message.data['devotional_id'];
    final type = message.data['type'];

    if (devotionalId == null || devotionalId.isEmpty) {
      return;
    }

    if (_isAuthenticated &&
        type != null &&
        type.isNotEmpty &&
        _currentUserId != null) {
      try {
        await _notificationApiClient.markNotificationOpened(
          devotionalId: devotionalId,
          type: type,
        );
      } catch (_) {}
    }

    _navigate('/devotionals/$devotionalId');
  }

  Future<void> _handleTokenRefresh(String token) async {
    if (!_isAuthenticated || _currentUserId == null || token.isEmpty) {
      return;
    }

    final previousToken = await _storage.readPushToken();
    if (previousToken != null &&
        previousToken.isNotEmpty &&
        previousToken != token) {
      try {
        await _notificationApiClient.deleteDeviceToken(token: previousToken);
      } catch (_) {}
    }

    await _registerPushToken(token);
  }

  Future<void> _syncPushState() async {
    if (!_isAuthenticated || _currentUserId == null) {
      return;
    }

    if (!await _ensureFirebaseReady()) {
      return;
    }

    final settings = await _pushMessagingClient.getNotificationSettings();
    final token = await _pushMessagingClient.getToken();
    final storedToken = await _storage.readPushToken();

    if (token == null || token.isEmpty) {
      if (storedToken != null && storedToken.isNotEmpty) {
        try {
          await _notificationApiClient.deleteDeviceToken(token: storedToken);
        } catch (_) {}
        await _storage.clearPushToken();
      }
      return;
    }

    if (storedToken != null && storedToken.isNotEmpty && storedToken != token) {
      try {
        await _notificationApiClient.deleteDeviceToken(token: storedToken);
      } catch (_) {}
    }

    try {
      await _notificationApiClient.registerDeviceToken(
        token: token,
        platform: _platformValue,
        osPermissionStatus: _mapPermissionStatus(settings.authorizationStatus),
      );
      await _storage.savePushToken(token);
    } catch (_) {}
  }

  Future<void> _registerPushToken(String token) async {
    final settings = await _pushMessagingClient.getNotificationSettings();
    try {
      await _notificationApiClient.registerDeviceToken(
        token: token,
        platform: _platformValue,
        osPermissionStatus: _mapPermissionStatus(settings.authorizationStatus),
      );
      await _storage.savePushToken(token);
    } catch (_) {}
  }

  Future<void> _recordAppSessionIfNeeded({bool force = false}) async {
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      return;
    }

    final now = DateTime.now().toUtc();
    if (!force &&
        _lastAppSessionAt != null &&
        now.difference(_lastAppSessionAt!) < const Duration(minutes: 5)) {
      return;
    }

    try {
      await _analyticsApiClient.recordAppSession(
        deviceId: await _resolveDeviceId(),
      );
      _lastAppSessionAt = now;
    } catch (_) {}
  }

  Future<void> _maybePromptForNotificationPermissionOnVersionEntry() async {
    if (_hasCheckedAutomaticPermissionPromptThisLaunch) {
      return;
    }

    _hasCheckedAutomaticPermissionPromptThisLaunch = true;

    if (!await _ensureFirebaseReady()) {
      return;
    }

    final currentVersion = await _appVersionResolver();
    if (currentVersion == null || currentVersion.isEmpty) {
      return;
    }

    final previousSeenVersion = await _storage.readLastSeenAppVersion();
    final promptAttemptVersion = await _storage
        .readNotificationPromptAttemptVersion();

    await _storage.saveLastSeenAppVersion(currentVersion);

    final settings = await _pushMessagingClient.getNotificationSettings();
    if (_isAuthorized(settings.authorizationStatus)) {
      return;
    }

    final isNewVersionEntry =
        previousSeenVersion == null || previousSeenVersion != currentVersion;
    if (!isNewVersionEntry || promptAttemptVersion == currentVersion) {
      return;
    }

    var attempted = false;
    try {
      attempted = true;
      await _pushMessagingClient.requestPermission();
    } catch (_) {
      if (!attempted) {
        return;
      }
    } finally {
      if (attempted) {
        await _storage.saveNotificationPromptAttemptVersion(currentVersion);
      }
    }
  }

  Future<void> _handleIncomingUri(Uri uri) async {
    final target = _parseDeepLink(uri);
    if (target == null) {
      return;
    }

    final shareToken = target.shareToken;
    if (shareToken != null && shareToken.isNotEmpty) {
      if (_isAuthenticated && _currentUserId != null) {
        try {
          await _shareAttributionApiClient.recordAppOpen(
            token: shareToken,
            deviceId: await _resolveDeviceId(),
            installDetected: _consumeInstallDetectedFlag(),
          );
          await _storage.clearPendingShareToken();
        } catch (_) {}
      } else {
        await _storage.savePendingShareToken(shareToken);
        try {
          await _shareAttributionApiClient.recordAppOpen(
            token: shareToken,
            deviceId: await _resolveDeviceId(),
            installDetected: _consumeInstallDetectedFlag(),
          );
        } catch (_) {}
      }
    }

    _navigate(target.location);
  }

  _DeepLinkTarget? _parseDeepLink(Uri uri) {
    final isCustomScheme = uri.scheme == 'holyverso' && uri.host == 'app';
    final isWebLink =
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        (uri.host == 'holyverso.com' || uri.host == 'www.holyverso.com');

    if (!isCustomScheme && !isWebLink) {
      return null;
    }

    final segments = uri.pathSegments.where((segment) => segment.isNotEmpty);
    final pathSegments = segments.toList(growable: false);

    if (pathSegments.length == 1 && pathSegments.first == 'devotionals') {
      final tab = uri.queryParameters['tab'];
      final normalizedTab = switch (tab) {
        'following' => 'following',
        'mine' => 'mine',
        'review' => 'review',
        _ => 'for_you',
      };
      final query = Uri(queryParameters: {'tab': normalizedTab}).query;
      return _DeepLinkTarget(location: '/devotionals?$query');
    }

    if (pathSegments.length >= 2 && pathSegments.first == 'devotionals') {
      final devotionalId = pathSegments[1];
      final shareToken = uri.queryParameters['share_token'];
      final queryParameters = <String, String>{};
      if (shareToken != null && shareToken.isNotEmpty) {
        queryParameters['share_token'] = shareToken;
      }

      final query = queryParameters.isEmpty
          ? ''
          : '?${Uri(queryParameters: queryParameters).query}';

      return _DeepLinkTarget(
        location: '/devotionals/$devotionalId$query',
        shareToken: shareToken,
      );
    }

    if (pathSegments.length == 1 && pathSegments.first == 'reset-password') {
      final token = uri.queryParameters['token'];
      final query = (token == null || token.isEmpty)
          ? ''
          : '?${Uri(queryParameters: {'token': token}).query}';
      return _DeepLinkTarget(location: '/reset-password$query');
    }

    return null;
  }

  void _navigate(String location) {
    final router = _router;
    if (router == null) {
      return;
    }

    scheduleMicrotask(() {
      router.go(location);
    });
  }

  Future<String> _resolveDeviceId() async {
    _deviceId ??= await _storage.getOrCreateDeviceId();
    return _deviceId!;
  }

  bool _consumeInstallDetectedFlag() {
    final value = _installDetectedThisLaunch;
    _installDetectedThisLaunch = false;
    return value;
  }

  bool _isAuthorized(PushAuthorizationStatus status) {
    return status == PushAuthorizationStatus.authorized ||
        status == PushAuthorizationStatus.provisional;
  }

  String _mapPermissionStatus(PushAuthorizationStatus status) {
    return switch (status) {
      PushAuthorizationStatus.authorized => 'AUTHORIZED',
      PushAuthorizationStatus.provisional => 'PROVISIONAL',
      PushAuthorizationStatus.denied => 'DENIED',
      PushAuthorizationStatus.notDetermined => 'NOT_DETERMINED',
    };
  }

  String get _platformValue => switch (defaultTargetPlatform) {
    TargetPlatform.android => 'ANDROID',
    TargetPlatform.iOS => 'IOS',
    _ => throw UnsupportedError(
      'Push notifications are only supported on mobile',
    ),
  };
}

Future<String?> _defaultAppVersionResolver() async {
  final info = await PackageInfo.fromPlatform();
  final version = info.version.trim();
  if (version.isEmpty) {
    return null;
  }

  final buildNumber = info.buildNumber.trim();
  return buildNumber.isEmpty ? version : '$version+$buildNumber';
}

Future<bool> bootstrapFirebaseApp(AppConfig appConfig) async {
  if (Firebase.apps.isNotEmpty) {
    return true;
  }

  try {
    await Firebase.initializeApp();
    return true;
  } catch (_) {
    final options = appConfig.firebaseOptions;
    if (options == null) {
      return false;
    }

    await Firebase.initializeApp(options: options);
    return true;
  }
}

Future<bool> _defaultFirebaseBootstrapper(AppConfig appConfig) async {
  return bootstrapFirebaseApp(appConfig);
}

class _DeepLinkTarget {
  const _DeepLinkTarget({required this.location, this.shareToken});

  final String location;
  final String? shareToken;
}

final phaseThreeRuntimeServiceProvider = Provider<PhaseThreeRuntimeService>((
  ref,
) {
  return PhaseThreeRuntimeService(
    appConfig: ref.watch(appConfigProvider),
    storage: ref.watch(appRuntimeStorageProvider),
    pushMessagingClient: ref.watch(pushMessagingClientProvider),
    analyticsApiClient: ref.watch(analyticsApiClientProvider),
    notificationApiClient: ref.watch(notificationApiClientProvider),
    shareAttributionApiClient: ref.watch(shareAttributionApiClientProvider),
    appLinks: AppLinks(),
  );
});
