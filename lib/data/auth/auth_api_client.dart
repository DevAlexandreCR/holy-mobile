import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/data/auth/models/auth_payload.dart';
import 'package:holyverso/data/auth/models/user_settings.dart';
import 'package:holyverso/data/network/api_client.dart';

class AuthApiClient {
  AuthApiClient(this._dio);

  final Dio _dio;

  Future<AuthPayload> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/register',
      data: {'name': name, 'email': email, 'password': password},
    );

    return AuthPayload.fromMap(response.data as Map<String, dynamic>);
  }

  Future<AuthPayload> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );

    return AuthPayload.fromMap(response.data as Map<String, dynamic>);
  }

  Future<void> forgotPassword({required String email}) {
    return _dio.post('/auth/forgot-password', data: {'email': email});
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) {
    return _dio.post(
      '/auth/reset-password',
      data: {'token': token, 'new_password': newPassword},
    );
  }

  Future<AuthPayload> me() async {
    final response = await _dio.get(
      '/auth/me',
      options: Options(extra: {'deferAuthStateHandling': true}),
    );
    return AuthPayload.fromMap(response.data as Map<String, dynamic>);
  }

  Future<void> deleteAccount() async {
    await _dio.delete('/user/account');
  }

  Future<UserSettings> updatePreferredVersion(int versionId) async {
    final response = await _dio.put(
      '/user/settings/version',
      data: {'version_id': versionId},
    );

    final rawData = response.data;
    final data = rawData is Map ? rawData['data'] ?? rawData : rawData;
    return UserSettings.fromMap(Map<String, dynamic>.from(data as Map));
  }

  Future<UserSettings> updateWidgetFontSize(String fontSize) async {
    final response = await _dio.put(
      '/user/settings/widget-font-size',
      data: {'widget_font_size': fontSize},
    );

    final rawData = response.data;
    final data = rawData is Map ? rawData['data'] ?? rawData : rawData;
    return UserSettings.fromMap(Map<String, dynamic>.from(data as Map));
  }

  Future<UserSettings> updateTimezone(String timezone) async {
    final response = await _dio.put(
      '/user/settings/timezone',
      data: {'timezone': timezone},
    );

    final rawData = response.data;
    final data = rawData is Map ? rawData['data'] ?? rawData : rawData;
    return UserSettings.fromMap(Map<String, dynamic>.from(data as Map));
  }

  Future<UserSettings> getNotificationPreferences() async {
    final response = await _dio.get('/users/me/notification-preferences');
    final rawData = response.data;
    final data = rawData is Map ? rawData['data'] ?? rawData : rawData;
    return UserSettings.fromMap(Map<String, dynamic>.from(data as Map));
  }

  Future<UserSettings> updateNotificationPreferences({
    required bool devotionalNotificationsEnabled,
    required bool followedCreatorNotificationsEnabled,
    required bool featuredDevotionalNotificationsEnabled,
    required bool streakRiskNotificationsEnabled,
    required bool authorModerationNotificationsEnabled,
    required bool editorReviewNotificationsEnabled,
    required bool socialActivityNotificationsEnabled,
    required bool commentNotificationsEnabled,
    required bool followNotificationsEnabled,
    required bool reactionNotificationsEnabled,
    int? dailyReminderHour,
    required bool dailyReminderNotificationsEnabled,
    required bool streakMilestoneNotificationsEnabled,
    required bool winbackNotificationsEnabled,
  }) async {
    final response = await _dio.put(
      '/users/me/notification-preferences',
      data: {
        'devotional_notifications_enabled': devotionalNotificationsEnabled,
        'followed_creator_notifications_enabled':
            followedCreatorNotificationsEnabled,
        'featured_devotional_notifications_enabled':
            featuredDevotionalNotificationsEnabled,
        'streak_risk_notifications_enabled': streakRiskNotificationsEnabled,
        'author_moderation_notifications_enabled':
            authorModerationNotificationsEnabled,
        'editor_review_notifications_enabled': editorReviewNotificationsEnabled,
        'social_activity_notifications_enabled':
            socialActivityNotificationsEnabled,
        'comment_notifications_enabled': commentNotificationsEnabled,
        'follow_notifications_enabled': followNotificationsEnabled,
        'reaction_notifications_enabled': reactionNotificationsEnabled,
        'daily_reminder_hour': dailyReminderHour,
        'daily_reminder_notifications_enabled':
            dailyReminderNotificationsEnabled,
        'streak_milestone_notifications_enabled':
            streakMilestoneNotificationsEnabled,
        'winback_notifications_enabled': winbackNotificationsEnabled,
      },
    );

    final rawData = response.data;
    final data = rawData is Map ? rawData['data'] ?? rawData : rawData;
    return UserSettings.fromMap(Map<String, dynamic>.from(data as Map));
  }
}

final authApiClientProvider = Provider<AuthApiClient>((ref) {
  return AuthApiClient(ref.watch(dioProvider));
});
