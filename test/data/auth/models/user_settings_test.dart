import 'package:flutter_test/flutter_test.dart';
import 'package:holyverso/data/auth/models/user_settings.dart';

void main() {
  test('daily-engagement fields default when absent from the map', () {
    final settings = UserSettings.fromMap({});

    expect(settings.dailyReminderHour, isNull);
    expect(settings.dailyReminderNotificationsEnabled, isTrue);
    expect(settings.streakMilestoneNotificationsEnabled, isTrue);
    expect(settings.winbackNotificationsEnabled, isTrue);
  });

  test('parses daily-engagement fields from a snake_case payload', () {
    final settings = UserSettings.fromMap({
      'daily_reminder_hour': 7,
      'daily_reminder_notifications_enabled': false,
      'streak_milestone_notifications_enabled': false,
      'winback_notifications_enabled': false,
    });

    expect(settings.dailyReminderHour, 7);
    expect(settings.dailyReminderNotificationsEnabled, isFalse);
    expect(settings.streakMilestoneNotificationsEnabled, isFalse);
    expect(settings.winbackNotificationsEnabled, isFalse);
  });

  test('parses a stringified daily_reminder_hour', () {
    final settings = UserSettings.fromMap({'daily_reminder_hour': '20'});

    expect(settings.dailyReminderHour, 20);
  });

  test('round-trips daily-engagement fields through toMap', () {
    const settings = UserSettings(
      dailyReminderHour: 12,
      dailyReminderNotificationsEnabled: false,
      streakMilestoneNotificationsEnabled: false,
      winbackNotificationsEnabled: false,
    );

    final map = settings.toMap();

    expect(map['daily_reminder_hour'], 12);
    expect(map['daily_reminder_notifications_enabled'], isFalse);
    expect(map['streak_milestone_notifications_enabled'], isFalse);
    expect(map['winback_notifications_enabled'], isFalse);
  });
}
