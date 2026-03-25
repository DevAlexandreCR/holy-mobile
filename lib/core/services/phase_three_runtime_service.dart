import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:holyverso/core/config/app_config.dart';
import 'package:holyverso/core/services/app_runtime_storage.dart';
import 'package:holyverso/data/analytics/analytics_api_client.dart';
import 'package:holyverso/data/notifications/notification_api_client.dart';
import 'package:holyverso/data/share_attribution/share_attribution_api_client.dart';

enum PushPermissionRequestResult { granted, denied, unavailable }

class PhaseThreeRuntimeService {
  PhaseThreeRuntimeService({
    required AppConfig appConfig,
    required AppRuntimeStorage storage,
    required AnalyticsApiClient analyticsApiClient,
    required NotificationApiClient notificationApiClient,
    required ShareAttributionApiClient shareAttributionApiClient,
    AppLinks? appLinks,
  }) : _appConfig = appConfig,
       _storage = storage,
       _analyticsApiClient = analyticsApiClient,
       _notificationApiClient = notificationApiClient,
       _shareAttributionApiClient = shareAttributionApiClient,
       _appLinks = appLinks;

  final AppConfig _appConfig;
  final AppRuntimeStorage _storage;
  final AnalyticsApiClient _analyticsApiClient;
  final NotificationApiClient _notificationApiClient;
  final ShareAttributionApiClient _shareAttributionApiClient;
  final AppLinks? _appLinks;
  FirebaseMessaging? _firebaseMessaging;

  StreamSubscription<Uri>? _appLinkSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _notificationOpenSubscription;
  GoRouter? _router;
  String? _deviceId;
  String? _currentUserId;
  DateTime? _lastAppSessionAt;
  bool _installDetectedThisLaunch = false;
  bool _isAuthenticated = false;
  bool _isFirebaseReady = false;
  bool _started = false;

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

    _notificationOpenSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _handleNotificationOpen,
    );
    final messaging = _resolveMessaging();
    if (messaging != null) {
      _tokenRefreshSubscription = messaging.onTokenRefresh.listen(
        _handleTokenRefresh,
      );
    }
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

    final messaging = _resolveMessaging();
    if (messaging == null) {
      return PushPermissionRequestResult.unavailable;
    }

    final currentSettings = await messaging.getNotificationSettings();
    if (_isAuthorized(currentSettings.authorizationStatus)) {
      await _syncPushState();
      return PushPermissionRequestResult.granted;
    }

    final updatedSettings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
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
      if (Firebase.apps.isEmpty) {
        try {
          await Firebase.initializeApp();
        } catch (_) {
          final options = _appConfig.firebaseOptions;
          if (options == null) {
            return false;
          }
          await Firebase.initializeApp(options: options);
        }
      }

      final messaging = _resolveMessaging();
      if (messaging == null) {
        return false;
      }

      await messaging.setAutoInitEnabled(true);
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await messaging.setForegroundNotificationPresentationOptions(
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
    final messaging = _resolveMessaging();
    if (messaging == null) {
      return;
    }

    try {
      final message = await messaging.getInitialMessage();
      if (message != null) {
        await _handleNotificationOpen(message);
      }
    } catch (_) {}
  }

  Future<void> _handleNotificationOpen(RemoteMessage message) async {
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

    final messaging = _resolveMessaging();
    if (messaging == null) {
      return;
    }

    final settings = await messaging.getNotificationSettings();
    final token = await messaging.getToken();
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
    final messaging = _resolveMessaging();
    if (messaging == null) {
      return;
    }

    final settings = await messaging.getNotificationSettings();
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

  bool _isAuthorized(AuthorizationStatus status) {
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }

  String _mapPermissionStatus(AuthorizationStatus status) {
    return switch (status) {
      AuthorizationStatus.authorized => 'AUTHORIZED',
      AuthorizationStatus.provisional => 'PROVISIONAL',
      AuthorizationStatus.denied => 'DENIED',
      AuthorizationStatus.notDetermined => 'NOT_DETERMINED',
    };
  }

  String get _platformValue => switch (defaultTargetPlatform) {
    TargetPlatform.android => 'ANDROID',
    TargetPlatform.iOS => 'IOS',
    _ => throw UnsupportedError(
      'Push notifications are only supported on mobile',
    ),
  };

  FirebaseMessaging? _resolveMessaging() {
    if (!_supportsPush) {
      return null;
    }

    try {
      _firebaseMessaging ??= FirebaseMessaging.instance;
      return _firebaseMessaging;
    } catch (_) {
      return null;
    }
  }
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
    analyticsApiClient: ref.watch(analyticsApiClientProvider),
    notificationApiClient: ref.watch(notificationApiClientProvider),
    shareAttributionApiClient: ref.watch(shareAttributionApiClientProvider),
    appLinks: AppLinks(),
  );
});
