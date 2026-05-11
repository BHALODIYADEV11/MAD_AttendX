import 'dart:ui' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);
  }

  Future<void> requestPermissions() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  /// Schedule a 20-minute before reminder for a lecture
  Future<void> scheduleLectureReminder({
    required int id,
    required String subjectName,
    required double currentPercentage,
    required DateTime lectureTime,
    required int minutesBefore,
  }) async {
    final scheduledTime = lectureTime.subtract(Duration(minutes: minutesBefore));
    if (scheduledTime.isBefore(DateTime.now())) return;

    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _plugin.zonedSchedule(
      id,
      '📚 ${subjectName} starts in $minutesBefore min',
      currentPercentage < 75
          ? '⚠️ Attendance: ${currentPercentage.toStringAsFixed(1)}% — You really need this class!'
          : '✅ Attendance: ${currentPercentage.toStringAsFixed(1)}% — Keep it up!',
      tzScheduledTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'lecture_reminders',
          'Lecture Reminders',
          channelDescription: '20-minute reminders before lectures',
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFF6C63FF),
          styleInformation: BigTextStyleInformation(
            '$subjectName lecture begins in $minutesBefore minutes.\n'
            'Current attendance: ${currentPercentage.toStringAsFixed(1)}%',
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Schedule an end-of-day reminder to mark attendance
  Future<void> scheduleEndOfDayReminder({
    required int id,
    required DateTime endOfDayTime,
  }) async {
    if (endOfDayTime.isBefore(DateTime.now())) return;

    final tzScheduledTime = tz.TZDateTime.from(endOfDayTime, tz.local);

    await _plugin.zonedSchedule(
      id,
      '🔔 Don\'t forget to mark attendance!',
      'You haven\'t marked attendance for today\'s lectures yet.',
      tzScheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'end_of_day',
          'End-of-Day Reminders',
          channelDescription: 'Reminder to mark daily attendance',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFF6C63FF),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Schedule all today's lecture reminders
  Future<void> scheduleAllTodayReminders({
    required List<Map<String, dynamic>> lectures, // [{subjectName, startTime, currentPct}]
    required int minutesBefore,
  }) async {
    // Cancel existing lecture reminders first
    for (int i = 0; i < 50; i++) {
      await _plugin.cancel(1000 + i);
    }

    final now = DateTime.now();
    int notifId = 1000;

    for (final lecture in lectures) {
      final timeParts = (lecture['startTime'] as String).split(':');
      final lectureTime = DateTime(
        now.year, now.month, now.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );

      await scheduleLectureReminder(
        id: notifId++,
        subjectName: lecture['subjectName'] as String,
        currentPercentage: (lecture['currentPct'] as double?) ?? 0.0,
        lectureTime: lectureTime,
        minutesBefore: minutesBefore,
      );
    }

    // End-of-day at 9 PM
    await scheduleEndOfDayReminder(
      id: 999,
      endOfDayTime: DateTime(now.year, now.month, now.day, 21, 0),
    );
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  /// Show an immediate notification (for testing)
  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      0,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'attendance_alerts',
          'Attendance Alerts',
          channelDescription: 'Reminders for low attendance subjects',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}
