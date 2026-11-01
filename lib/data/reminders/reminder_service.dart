import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
// latest_all includes alias zones such as Africa/Addis_Ababa, which
// Ethiopian phones report (the smaller database does not).
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../core/utils/logger.dart';

/// The next moment the reminder should fire: today at [time] if that is
/// still ahead of [now], otherwise tomorrow. Pure, so it can be tested.
tz.TZDateTime nextReminder(tz.TZDateTime now, TimeOfDay time) {
  var next = tz.TZDateTime(
    now.location,
    now.year,
    now.month,
    now.day,
    time.hour,
    time.minute,
  );
  if (!next.isAfter(now)) {
    next = tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day + 1,
      time.hour,
      time.minute,
    );
  }
  return next;
}

/// One local daily reminder. Inexact on purpose: no exact-alarm
/// permission (AGENTS.md section 3); Android may shift it by a few
/// minutes to save battery. The plugin reschedules it after a reboot.
class ReminderService {
  ReminderService([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  static const int _id = 1;
  static const _channel = AndroidNotificationDetails(
    'daily_reminder',
    'Daily reminder',
    channelDescription: 'One gentle reminder a day to plan your three tasks.',
    icon: 'ic_stat_planner',
  );

  Future<void> _init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } on Object catch (e, s) {
      // Unknown zone: fall back to UTC rather than not reminding at all.
      Log.error('Could not read the time zone', e, s);
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_planner'),
      ),
    );
    _ready = true;
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  /// Asks for notification permission (Android 13+). Returns whether
  /// notifications are allowed. The app works either way.
  Future<bool> requestPermission() async {
    await _init();
    final android = _android;
    if (android == null) return false;
    if (await android.areNotificationsEnabled() ?? false) return true;
    return await android.requestNotificationsPermission() ?? false;
  }

  /// Schedules the daily reminder at [time], or cancels it when null.
  Future<void> sync(TimeOfDay? time) async {
    try {
      await _init();
      await _plugin.cancel(id: _id);
      if (time == null) return;
      await _plugin.zonedSchedule(
        id: _id,
        title: 'Plan your day',
        body: 'Pick up to three things that matter today.',
        scheduledDate: nextReminder(tz.TZDateTime.now(tz.local), time),
        notificationDetails: const NotificationDetails(android: _channel),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } on Object catch (e, s) {
      // A reminder must never break the app.
      Log.error('Could not schedule the daily reminder', e, s);
    }
  }
}

final reminderServiceProvider = Provider<ReminderService>(
  (ref) => ReminderService(),
);
