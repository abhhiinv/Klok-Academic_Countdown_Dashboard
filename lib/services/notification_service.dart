import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/event.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    _initialized = true;
  }

  /// Schedule a notification at [scheduledDate].
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'klok_channel',
          'Klok Reminders',
          channelDescription: 'Academic event countdown reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Schedules notifications at 1 day and 3 hours before the event.
  static Future<void> scheduleEventNotifications(Event event) async {
    final oneDayBefore =
        event.date.subtract(const Duration(days: 1));
    final threeHoursBefore =
        event.date.subtract(const Duration(hours: 3));

    final baseId = event.id.hashCode.abs();

    if (oneDayBefore.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: baseId,
        title: '⏰ Tomorrow: ${event.title}',
        body: '${event.category.toUpperCase()} is due tomorrow!',
        scheduledDate: oneDayBefore,
      );
    }

    if (threeHoursBefore.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: baseId + 1,
        title: '🔴 In 3 hours: ${event.title}',
        body: '${event.category.toUpperCase()} is due in 3 hours!',
        scheduledDate: threeHoursBefore,
      );
    }
  }

  static Future<void> cancelEventNotifications(Event event) async {
    final baseId = event.id.hashCode.abs();
    await _plugin.cancel(baseId);
    await _plugin.cancel(baseId + 1);
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
