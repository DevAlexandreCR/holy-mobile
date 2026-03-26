import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PushAuthorizationStatus { authorized, provisional, denied, notDetermined }

class PushNotificationSettings {
  const PushNotificationSettings({required this.authorizationStatus});

  final PushAuthorizationStatus authorizationStatus;
}

class PushNotificationMessage {
  const PushNotificationMessage({required this.data});

  final Map<String, String> data;
}

abstract class PushMessagingClient {
  Future<PushNotificationSettings> getNotificationSettings();

  Future<PushNotificationSettings> requestPermission();

  Future<void> setAutoInitEnabled(bool enabled);

  Future<void> setForegroundNotificationPresentationOptions({
    required bool alert,
    required bool badge,
    required bool sound,
  });

  Future<String?> getToken();

  Future<PushNotificationMessage?> getInitialMessage();

  Stream<String> get onTokenRefresh;

  Stream<PushNotificationMessage> get onMessageOpenedApp;
}

class FirebasePushMessagingClient implements PushMessagingClient {
  FirebasePushMessagingClient({FirebaseMessaging? messaging})
    : _messaging = messaging;

  FirebaseMessaging? _messaging;

  FirebaseMessaging get _instance => _messaging ??= FirebaseMessaging.instance;

  @override
  Future<PushNotificationSettings> getNotificationSettings() async {
    final settings = await _instance.getNotificationSettings();
    return PushNotificationSettings(
      authorizationStatus: _mapAuthorizationStatus(
        settings.authorizationStatus,
      ),
    );
  }

  @override
  Future<PushNotificationSettings> requestPermission() async {
    final settings = await _instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return PushNotificationSettings(
      authorizationStatus: _mapAuthorizationStatus(
        settings.authorizationStatus,
      ),
    );
  }

  @override
  Future<void> setAutoInitEnabled(bool enabled) {
    return _instance.setAutoInitEnabled(enabled);
  }

  @override
  Future<void> setForegroundNotificationPresentationOptions({
    required bool alert,
    required bool badge,
    required bool sound,
  }) {
    return _instance.setForegroundNotificationPresentationOptions(
      alert: alert,
      badge: badge,
      sound: sound,
    );
  }

  @override
  Future<String?> getToken() {
    return _instance.getToken();
  }

  @override
  Future<PushNotificationMessage?> getInitialMessage() async {
    final message = await _instance.getInitialMessage();
    if (message == null) {
      return null;
    }

    return PushNotificationMessage(
      data: Map<String, String>.from(message.data),
    );
  }

  @override
  Stream<String> get onTokenRefresh => _instance.onTokenRefresh;

  @override
  Stream<PushNotificationMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp.map(
        (message) => PushNotificationMessage(
          data: Map<String, String>.from(message.data),
        ),
      );

  PushAuthorizationStatus _mapAuthorizationStatus(AuthorizationStatus status) {
    return switch (status) {
      AuthorizationStatus.authorized => PushAuthorizationStatus.authorized,
      AuthorizationStatus.provisional => PushAuthorizationStatus.provisional,
      AuthorizationStatus.denied => PushAuthorizationStatus.denied,
      AuthorizationStatus.notDetermined =>
        PushAuthorizationStatus.notDetermined,
    };
  }
}

final pushMessagingClientProvider = Provider<PushMessagingClient>((ref) {
  return FirebasePushMessagingClient();
});
