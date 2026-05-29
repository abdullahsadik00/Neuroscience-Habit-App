// TODO SETUP — Android manifest entries (already documented in README.md):
// Add to android/app/src/main/AndroidManifest.xml inside <manifest>:
//   <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
//   <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
//
// NOTE: We intentionally use inexactAllowWhileIdle (not exactAllowWhileIdle).
// Exact alarms require SCHEDULE_EXACT_ALARM permission which Android 12+
// forces users to grant manually in Settings. Inexact alarms fire within
// ~15 min of the scheduled time — perfectly fine for habit reminders.

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _channelId = 'neurosync_main';
  static const _channelName = 'NeuroSync Reminders';

  static const _idDailyReminder = 1;
  static const _idLossAversion = 2;
  static const _idComebackNudge = 3;
  static const _idEveningCheckin = 4;

  static Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // request explicitly later at onboarding
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
    _initialized = true;
  }

  static Future<bool> requestPermission() async {
    try {
      final ios = await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      final android = await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      return ios == true || android == true;
    } catch (_) {
      return false;
    }
  }

  static AndroidNotificationDetails get _androidDetails => const AndroidNotificationDetails(
        _channelId,
        _channelName,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

  static NotificationDetails get _details => NotificationDetails(
        android: _androidDetails,
        iOS: const DarwinNotificationDetails(),
      );

  // Daily habit reminder at 8 AM — repeating
  static Future<void> scheduleDailyReminder() async {
    try {
      await _plugin.zonedSchedule(
        _idDailyReminder,
        'Build your neural pathway',
        "Tap to log today's habits and strengthen your myelination.",
        _nextInstanceOf(hour: 8, minute: 0),
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {}
  }

  // Evening check-in at 8 PM — repeating
  static Future<void> scheduleEveningCheckin() async {
    try {
      await _plugin.zonedSchedule(
        _idEveningCheckin,
        "How'd today go?",
        'Log any slips or comebacks — data turns into recovery insights.',
        _nextInstanceOf(hour: 20, minute: 0),
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {}
  }

  // Loss aversion nudge — fires N days after the last app open.
  // Called on app pause/background; cancelled on resume.
  static Future<void> scheduleLossAversionNudge({int daysFromNow = 3}) async {
    try {
      await _plugin.cancel(_idLossAversion);
      final fireAt = tz.TZDateTime.now(tz.local).add(Duration(days: daysFromNow));
      await _plugin.zonedSchedule(
        _idLossAversion,
        '🧠 Your myelination is decaying',
        'Without reinforcement, neural pathways weaken. 3 minutes is all it takes to reverse this.',
        tz.TZDateTime(tz.local, fireAt.year, fireAt.month, fireAt.day, 9, 0),
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}
  }

  // Comeback streak nudge — fires if 2 days pass without a comeback.
  static Future<void> scheduleComebackNudge() async {
    try {
      await _plugin.cancel(_idComebackNudge);
      final fireAt = tz.TZDateTime.now(tz.local).add(const Duration(days: 2));
      await _plugin.zonedSchedule(
        _idComebackNudge,
        '↩ Your comeback streak is at risk',
        'You missed a habit yesterday. Open your Comeback Protocol before the pathway fades.',
        tz.TZDateTime(tz.local, fireAt.year, fireAt.month, fireAt.day, 10, 0),
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}
  }

  static Future<void> cancelLossAversionNudge() async {
    try {
      await _plugin.cancel(_idLossAversion);
    } catch (_) {}
  }

  static Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  static tz.TZDateTime _nextInstanceOf({required int hour, required int minute}) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));
    return scheduled;
  }
}
