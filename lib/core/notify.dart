import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'dart:io' show Platform;

class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _inited = false;

  Future<void> init() async {
    if (_inited) return;
    // tz database
    tzdata.initializeTimeZones();
    // Assume device's local timezone is correct.
    tz.setLocalLocation(tz.getLocation(DateTime.now().timeZoneName));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings);
    _inited = true;

    if (Platform.isAndroid) {
      // Android 13+ runtime permission is handled by plugin on show; ensure channel exists.
      const channel = AndroidNotificationChannel(
        'daily_reminder',
        'Daily Reminder',
        description: '매일 기록 알림',
        importance: Importance.defaultImportance,
      );
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(channel);
    }
  }

  Future<void> scheduleDailyReminder({required int hour, required int minute}) async {
    await init();
    const details = NotificationDetails(
      android: AndroidNotificationDetails('daily_reminder', 'Daily Reminder', channelDescription: '매일 기록 알림'),
      iOS: DarwinNotificationDetails(),
    );

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      1001,
      '오늘의 기록',
      '오늘 하루를 일기로 남겨볼까요?',
      scheduled,
      details,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailyReminder() async {
    await _plugin.cancel(1001);
  }
}
