import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holyverso/core/config/app_config.dart';
import 'package:holyverso/core/services/app_runtime_storage.dart';
import 'package:holyverso/core/services/phase_three_runtime_service.dart';
import 'package:holyverso/core/services/push_messaging_client.dart';
import 'package:holyverso/data/analytics/analytics_api_client.dart';
import 'package:holyverso/data/notifications/notification_api_client.dart';
import 'package:holyverso/data/share_attribution/share_attribution_api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  group('PhaseThreeRuntimeService automatic notification prompt', () {
    test(
      'prompts on first authenticated entry after version change when permission is not granted',
      () async {
        final harness = await _createHarness(
          currentVersion: '1.1.3+13',
          initialStatus: PushAuthorizationStatus.notDetermined,
          initialValues: {
            'phase3.device_id': 'device-1',
            'phase3.last_seen_app_version': '1.1.2+12',
          },
        );

        await harness.service.syncSession(
          isAuthenticated: true,
          userId: 'user-1',
          forceSessionStart: true,
        );

        expect(harness.messagingClient.requestPermissionCallCount, 1);
        expect(
          await harness.storage.readNotificationPromptAttemptVersion(),
          '1.1.3+13',
        );
      },
    );

    test('does not prompt when permission is already authorized', () async {
      final harness = await _createHarness(
        currentVersion: '1.1.3+13',
        initialStatus: PushAuthorizationStatus.authorized,
        initialValues: {
          'phase3.device_id': 'device-1',
          'phase3.last_seen_app_version': '1.1.2+12',
        },
      );

      await harness.service.syncSession(
        isAuthenticated: true,
        userId: 'user-1',
        forceSessionStart: true,
      );

      expect(harness.messagingClient.requestPermissionCallCount, 0);
      expect(
        await harness.storage.readNotificationPromptAttemptVersion(),
        isNull,
      );
    });

    test('does not prompt when permission is already provisional', () async {
      final harness = await _createHarness(
        currentVersion: '1.1.3+13',
        initialStatus: PushAuthorizationStatus.provisional,
        initialValues: {
          'phase3.device_id': 'device-1',
          'phase3.last_seen_app_version': '1.1.2+12',
        },
      );

      await harness.service.syncSession(
        isAuthenticated: true,
        userId: 'user-1',
        forceSessionStart: true,
      );

      expect(harness.messagingClient.requestPermissionCallCount, 0);
    });

    test('does not prompt twice in the same app version', () async {
      final harness = await _createHarness(
        currentVersion: '1.1.3+13',
        initialStatus: PushAuthorizationStatus.notDetermined,
        initialValues: {
          'phase3.device_id': 'device-1',
          'phase3.last_seen_app_version': '1.1.3+13',
          'phase3.notification_prompt_attempt_version': '1.1.3+13',
        },
      );

      await harness.service.syncSession(
        isAuthenticated: true,
        userId: 'user-1',
        forceSessionStart: true,
      );

      expect(harness.messagingClient.requestPermissionCallCount, 0);
    });

    test('prompts again after a later app version upgrade', () async {
      final harness = await _createHarness(
        currentVersion: '1.1.4+14',
        initialStatus: PushAuthorizationStatus.denied,
        initialValues: {
          'phase3.device_id': 'device-1',
          'phase3.last_seen_app_version': '1.1.3+13',
          'phase3.notification_prompt_attempt_version': '1.1.3+13',
        },
      );

      await harness.service.syncSession(
        isAuthenticated: true,
        userId: 'user-1',
        forceSessionStart: true,
      );

      expect(harness.messagingClient.requestPermissionCallCount, 1);
      expect(
        await harness.storage.readNotificationPromptAttemptVersion(),
        '1.1.4+14',
      );
    });

    test('does not prompt for guests', () async {
      final harness = await _createHarness(
        currentVersion: '1.1.3+13',
        initialStatus: PushAuthorizationStatus.notDetermined,
        initialValues: {
          'phase3.device_id': 'device-1',
          'phase3.last_seen_app_version': '1.1.2+12',
        },
      );

      await harness.service.syncSession(
        isAuthenticated: false,
        userId: null,
        forceSessionStart: false,
      );

      expect(harness.messagingClient.requestPermissionCallCount, 0);
      expect(
        await harness.storage.readNotificationPromptAttemptVersion(),
        isNull,
      );
    });

    test('denied permission continues safely and syncs push state', () async {
      final harness = await _createHarness(
        currentVersion: '1.1.3+13',
        initialStatus: PushAuthorizationStatus.notDetermined,
        requestStatus: PushAuthorizationStatus.denied,
        token: 'push-token-1',
        initialValues: {
          'phase3.device_id': 'device-1',
          'phase3.last_seen_app_version': '1.1.2+12',
        },
      );

      await harness.service.syncSession(
        isAuthenticated: true,
        userId: 'user-1',
        forceSessionStart: true,
      );

      expect(harness.messagingClient.requestPermissionCallCount, 1);
      expect(harness.notifications.registerCalls, hasLength(1));
      expect(
        harness.notifications.registerCalls.single.osPermissionStatus,
        'DENIED',
      );
    });
  });
}

Future<_Harness> _createHarness({
  required String currentVersion,
  required PushAuthorizationStatus initialStatus,
  PushAuthorizationStatus? requestStatus,
  String? token,
  Map<String, Object> initialValues = const {},
}) async {
  SharedPreferences.setMockInitialValues(initialValues);

  final storage = AppRuntimeStorage();
  final messagingClient = _FakePushMessagingClient(
    currentStatus: initialStatus,
    requestStatus: requestStatus,
    token: token,
  );
  final notifications = _FakeNotificationApiClient();

  final service = PhaseThreeRuntimeService(
    appConfig: const AppConfig(
      baseApiUrl: 'https://api.example.com',
      requestTimeout: Duration(seconds: 15),
      genericErrorMessage: 'Error',
      networkErrorMessage: 'Network',
      firebaseOptions: null,
    ),
    storage: storage,
    pushMessagingClient: messagingClient,
    analyticsApiClient: _FakeAnalyticsApiClient(),
    notificationApiClient: notifications,
    shareAttributionApiClient: _FakeShareAttributionApiClient(),
    appVersionResolver: () async => currentVersion,
    firebaseBootstrapper: (_) async => true,
  );

  return _Harness(
    service: service,
    storage: storage,
    messagingClient: messagingClient,
    notifications: notifications,
  );
}

class _Harness {
  const _Harness({
    required this.service,
    required this.storage,
    required this.messagingClient,
    required this.notifications,
  });

  final PhaseThreeRuntimeService service;
  final AppRuntimeStorage storage;
  final _FakePushMessagingClient messagingClient;
  final _FakeNotificationApiClient notifications;
}

class _FakePushMessagingClient implements PushMessagingClient {
  _FakePushMessagingClient({
    required PushAuthorizationStatus currentStatus,
    PushAuthorizationStatus? requestStatus,
    this.token,
  }) : _currentStatus = currentStatus,
       _requestStatus = requestStatus ?? currentStatus;

  PushAuthorizationStatus _currentStatus;
  final PushAuthorizationStatus _requestStatus;
  final String? token;
  int requestPermissionCallCount = 0;

  @override
  Future<PushNotificationSettings> getNotificationSettings() async {
    return PushNotificationSettings(authorizationStatus: _currentStatus);
  }

  @override
  Future<PushNotificationMessage?> getInitialMessage() async => null;

  @override
  Future<String?> getToken() async => token;

  @override
  Stream<PushNotificationMessage> get onMessageOpenedApp =>
      const Stream.empty();

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Future<PushNotificationSettings> requestPermission() async {
    requestPermissionCallCount += 1;
    _currentStatus = _requestStatus;
    return PushNotificationSettings(authorizationStatus: _currentStatus);
  }

  @override
  Future<void> setAutoInitEnabled(bool enabled) async {}

  @override
  Future<void> setForegroundNotificationPresentationOptions({
    required bool alert,
    required bool badge,
    required bool sound,
  }) async {}
}

class _RegisterCall {
  const _RegisterCall({
    required this.token,
    required this.platform,
    required this.osPermissionStatus,
  });

  final String token;
  final String platform;
  final String osPermissionStatus;
}

class _FakeNotificationApiClient extends NotificationApiClient {
  _FakeNotificationApiClient() : super(Dio());

  final List<_RegisterCall> registerCalls = [];
  final List<String> deleteCalls = [];

  @override
  Future<void> deleteDeviceToken({required String token}) async {
    deleteCalls.add(token);
  }

  @override
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
    required String osPermissionStatus,
  }) async {
    registerCalls.add(
      _RegisterCall(
        token: token,
        platform: platform,
        osPermissionStatus: osPermissionStatus,
      ),
    );
  }
}

class _FakeAnalyticsApiClient extends AnalyticsApiClient {
  _FakeAnalyticsApiClient() : super(Dio());

  @override
  Future<void> recordAppSession({String? deviceId}) async {}
}

class _FakeShareAttributionApiClient extends ShareAttributionApiClient {
  _FakeShareAttributionApiClient() : super(Dio());

  @override
  Future<void> recordAppOpen({
    required String token,
    String? deviceId,
    bool installDetected = false,
    bool registrationCompleted = false,
  }) async {}
}
