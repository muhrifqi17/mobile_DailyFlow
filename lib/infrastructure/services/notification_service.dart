import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class LocalNotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    
    // Initialize timezones
    tz.initializeTimeZones();
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    String timeZoneName = tzInfo.toString();
    
    // Parse "TimezoneInfo(Asia/Jakarta, ...)" to "Asia/Jakarta" if needed
    if (timeZoneName.startsWith('TimezoneInfo(')) {
      timeZoneName = timeZoneName.substring(13).split(',')[0].trim();
    }
    
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await _plugin.initialize(initSettings);
    
    // Request Android 13 permissions
    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestExactAlarmsPermission();

    _initialized = true;
  }

  /// 2-Stage Notification defined in PRD
  Future<void> scheduleTwoStageNotification({
    required int id,
    required String title,
    required DateTime scheduledTime,
  }) async {
    if (!_initialized) await init();

    final now = DateTime.now();
    if (scheduledTime.isBefore(now)) return;

    // Stage 1: Advance Warning (15 mins prior)
    final warningTime = scheduledTime.subtract(const Duration(minutes: 15));
    if (warningTime.isAfter(now)) {
      await _plugin.zonedSchedule(
        id,
        'Upcoming Habit in 15 mins',
        title,
        tz.TZDateTime.from(warningTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails('stage1_channel', 'Advance Warnings', channelDescription: '15 mins before habit', importance: Importance.high),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
    
    // Stage 2: Action Trigger (exact time)
    await _plugin.zonedSchedule(
      id + 1000,
      'Time to execute!',
      title,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails('stage2_channel', 'Action Triggers', channelDescription: 'Exact time for habit', importance: Importance.max, priority: Priority.max),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Add Notification
  Future<void> showAddHabitNotification({
      required int id,
      required String title,
      }) async {
    if (!_initialized) await init();
    await _plugin.show(
      id + 7000,
      'New Habit Sucessfully Added',
      title,
      const NotificationDetails(
        android: AndroidNotificationDetails('add_habit_channel', 'Add Habit Notification', channelDescription: 'Add Habit Notification', importance: Importance.max, priority: Priority.max),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
