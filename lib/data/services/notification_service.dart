import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

/// Wraps flutter_local_notifications. All scheduling is local — no push
/// service, no server, fully offline (spec requirement).
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);

    const channel = AndroidNotificationDetails(
      'finmate_reminders',
      'FinMate Reminders',
      channelDescription:
          'Budget warnings, subscription renewals, and savings reminders',
      importance: Importance.high,
      priority: Priority.high,
    );
    _details = const NotificationDetails(android: channel);
    _initialized = true;
  }

  late final NotificationDetails _details;

  Future<void> _show(int id, String title, String body) async {
    await init();
    await _plugin.show(id, title, body, _details);
  }

  Future<void> _schedule(int id, String title, String body, DateTime when) async {
    await init();
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(when, tz.local),
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> budgetWarning(String category, double percentUsed) => _show(
        category.hashCode,
        'Budget Warning',
        'You\'ve used ${percentUsed.toStringAsFixed(0)}% of your $category budget this month.',
      );

  Future<void> subscriptionReminder(String name, DateTime renewalDate) =>
      _schedule(
        name.hashCode,
        'Subscription Renewing Soon',
        '$name renews on ${renewalDate.day}/${renewalDate.month}.',
        renewalDate.subtract(const Duration(days: 1)),
      );

  Future<void> savingsReminder(String goalTitle) => _show(
        goalTitle.hashCode,
        'Savings Reminder',
        'Don\'t forget to add to your "$goalTitle" savings goal this week.',
      );

  Future<void> futureExpenseReminder(String title, DateTime plannedDate) =>
      _schedule(
        title.hashCode,
        'Planned Purchase Coming Up',
        '$title is planned for ${plannedDate.day}/${plannedDate.month}.',
        plannedDate.subtract(const Duration(days: 2)),
      );

  Future<void> expenseReminder() => _show(
        9999,
        'Log Today\'s Expenses',
        'Take a minute to add any expenses you made today.',
      );

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }
}
