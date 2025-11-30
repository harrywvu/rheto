import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import 'progress_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  static const String _notificationSentTodayKey = 'notification_sent_today';
  static const String _lastNotificationDateKey = 'last_notification_date';

  Future<void> initialize() async {
    tz_data.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);
    _scheduleNotifications();
  }

  Future<void> _scheduleNotifications() async {
    await _cancelAllNotifications();

    const List<int> notificationHours = [7, 14, 21];

    for (int i = 0; i < notificationHours.length; i++) {
      final hour = notificationHours[i];
      final scheduledDate = _getNextScheduledTime(hour);

      await _notificationsPlugin.zonedSchedule(
        i,
        'Time to stimulate your mind',
        'Complete your daily activities',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'rheto_channel',
            'Rheto Reminders',
            channelDescription: 'Daily activity reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  tz.TZDateTime _getNextScheduledTime(int hour) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  Future<void> showContextualNotification() async {
    final hasNotificationSentToday = await _hasNotificationSentToday();
    if (hasNotificationSentToday) return;

    final progress = await ProgressService.getProgress();
    final today = DateTime.now();

    final completedModules = progress.modulesCompletedToday.values
        .where((count) => count > 0)
        .length;
    final remainingModules = 3 - completedModules;

    String title;
    String body;

    if (remainingModules == 0) {
      title = 'Incredible! 🎉';
      body = 'You\'ve completed all domains today. Rest well!';
      await _markNotificationSentToday();
      return;
    }

    if (progress.currentStreak > 0 &&
        !_isSameDay(progress.lastActivityDate, today)) {
      title = 'Streak at Risk! 🔥';
      body =
          'Giving up so soon? Guess you\'re not built for intelligence. Complete $remainingModules more domain${remainingModules > 1 ? 's' : ''}.';
    } else {
      title = 'Keep Going! 💪';
      body =
          'You still have $remainingModules domain${remainingModules > 1 ? 's' : ''} to stimulate today';
    }

    await _notificationsPlugin.show(
      999,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'rheto_contextual',
          'Contextual Reminders',
          channelDescription: 'Contextual activity reminders',
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

    await _markNotificationSentToday();
  }

  Future<bool> _hasNotificationSentToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_lastNotificationDateKey);

    if (lastDate == null) return false;

    final lastNotificationDate = DateTime.parse(lastDate);
    final today = DateTime.now();

    return _isSameDay(lastNotificationDate, today);
  }

  Future<void> _markNotificationSentToday() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _lastNotificationDateKey,
      DateTime.now().toIso8601String(),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Future<void> _cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> resetDailyNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastNotificationDateKey);
    await _scheduleNotifications();
  }
}
