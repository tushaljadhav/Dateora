import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/item.dart';
import '../models/notification_record.dart';
import 'analytics_service.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  NotificationService._init();

  static const String channelId = 'expiry_reminders';
  static const String channelName = 'Expiry Reminders';
  static const int weeklySummaryNotifId = 888888;

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        AnalyticsService.instance.logNotificationOpened();
      },
    );

    // If app was launched via notification click
    try {
      final launchDetails = await _notifications.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp ?? false) {
        AnalyticsService.instance.logNotificationOpened();
      }
    } catch (_) {}

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          channelId,
          channelName,
          description: 'Notifications for upcoming item expirations',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );
    }
  }

  Future<bool> canScheduleExactAlarms() async {
    return false;
  }

  Future<bool> requestExactAlarmsPermission() async {
    return false;
  }

  Future<bool> requestPermissions() async {
    final android = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  int _generateIntId(String itemId, int offsetDays) {
    return (itemId.hashCode ^ offsetDays).abs() % 2147483647;
  }

  String getNotificationTitle([String? localeCode]) {
    if (localeCode == 'hi') return 'Dateora एक्सपायरी अलर्ट';
    if (localeCode == 'mr') return 'Dateora मुदत सूचना';
    return 'Dateora Expiry Alert';
  }

  String getNotificationBody(String itemName, int offsetDays, [String? localeCode]) {
    if (localeCode == 'hi') {
      if (offsetDays == 0) return '$itemName आज एक्सपायर हो रहा है।';
      if (offsetDays == 1) return '$itemName कल एक्सपायर हो रहा है।';
      return '$itemName $offsetDays दिनों में एक्सपायर हो रहा है।';
    } else if (localeCode == 'mr') {
      if (offsetDays == 0) return '$itemName ची मुदत आज संपत आहे.';
      if (offsetDays == 1) return '$itemName ची मुदत उद्या संपत आहे.';
      return '$itemName ची मुदत $offsetDays दिवसांत संपत आहे.';
    }

    if (offsetDays == 0) return '$itemName expires today.';
    if (offsetDays == 1) return '$itemName expires tomorrow.';
    return '$itemName expires in $offsetDays days.';
  }

  String getWeeklySummaryTitle([String? localeCode]) {
    if (localeCode == 'hi') return 'Dateora साप्ताहिक सारांश';
    if (localeCode == 'mr') return 'Dateora साप्ताहिक आढावा';
    return 'Dateora Weekly Summary';
  }

  String getWeeklySummaryBody(int count, [String? localeCode]) {
    if (count > 0) {
      if (localeCode == 'hi') {
        return 'इस हफ्ते $count सामान एक्सपायर हो रहे हैं। खराब होने से पहले जांच लें!';
      } else if (localeCode == 'mr') {
        return 'या आठवड्यात $count वस्तूंची मुदत संपत आहे. खराब होण्यापूर्वी वापरून घ्या!';
      }
      return '$count items expire this week. Check them before they go bad!';
    } else {
      if (localeCode == 'hi') {
        return 'सब कुछ सुरक्षित! इस हफ्ते कोई भी सामान एक्सपायर नहीं हो रहा।';
      } else if (localeCode == 'mr') {
        return 'सर्व काही सुरक्षित! या आठवड्यात कोणत्याही वस्तूची मुदत संपत नाही.';
      }
      return 'All clear! No items expiring this week. Enjoy your fresh supplies.';
    }
  }

  DateTime calculateFiresAt(String expiryDateStr, int offsetDays, [String dailyTime = '09:00']) {
    final parts = expiryDateStr.split('-');
    final timeParts = dailyTime.split(':');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    final target = DateTime(year, month, day, hour, minute);
    return target.subtract(Duration(days: offsetDays));
  }

  /// Calculates the next Sunday target DateTime at the configured daily time (e.g. 09:00).
  DateTime calculateNextSundayTarget([String dailyTime = '09:00', DateTime? refDate]) {
    final now = refDate ?? DateTime.now();
    final timeParts = dailyTime.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    // Sunday is weekday 7
    int daysUntilSunday = (DateTime.sunday - now.weekday) % 7;
    var targetDate = DateTime(now.year, now.month, now.day, hour, minute).add(Duration(days: daysUntilSunday));

    // If today is Sunday and target time is already in the past, schedule for next Sunday
    if (daysUntilSunday == 0 && targetDate.isBefore(now)) {
      targetDate = targetDate.add(const Duration(days: 7));
    }

    return targetDate;
  }

  Future<List<NotificationRecord>> scheduleItemReminders(
    Item item, {
    String dailyNotificationTime = '09:00',
    String? localeCode,
  }) async {
    await cancelItemReminders(item);

    if (item.status != 'active') return [];

    final records = <NotificationRecord>[];
    final now = DateTime.now();

    for (final offset in item.reminderOffsets) {
      final firesAt = calculateFiresAt(item.expiryDate, offset, dailyNotificationTime);
      final idString = '${item.id}:$offset';

      if (firesAt.isAfter(now)) {
        final notifId = _generateIntId(item.id, offset);
        final tzFiresAt = tz.TZDateTime.from(firesAt, tz.local);

        const androidDetails = AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'Notifications for upcoming item expirations',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        );

        const notifDetails = NotificationDetails(android: androidDetails);

        try {
          await _notifications.zonedSchedule(
            notifId,
            getNotificationTitle(localeCode),
            getNotificationBody(item.name, offset, localeCode),
            tzFiresAt,
            notifDetails,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
        } catch (_) {
          // Fallback to inexact scheduling
          try {
            await _notifications.zonedSchedule(
              notifId,
              getNotificationTitle(localeCode),
              getNotificationBody(item.name, offset, localeCode),
              tzFiresAt,
              notifDetails,
              uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
              androidScheduleMode: AndroidScheduleMode.inexact,
            );
          } catch (_) {}
        }

        records.add(NotificationRecord(
          id: idString,
          itemId: item.id,
          firesAt: firesAt.toIso8601String(),
        ));
      }
    }

    return records;
  }

  Future<void> cancelItemReminders(Item item) async {
    for (final offset in [0, 1, 3, 7, 14, 30]) {
      try {
        final notifId = _generateIntId(item.id, offset);
        await _notifications.cancel(notifId);
      } catch (_) {
        // Silently handle if notification cancel fails
      }
    }
  }

  Future<void> cancelAll() async {
    try {
      await _notifications.cancelAll();
    } catch (_) {}
  }

  /// Schedules a weekly summary push notification every Sunday at 09:00 (or user's daily alert time).
  /// Calculates count of active items expiring in the next 7 days from that Sunday.
  Future<void> scheduleWeeklySummaryNotification(
    List<Item> activeItems, {
    String dailyNotificationTime = '09:00',
    String? localeCode,
  }) async {
    await cancelWeeklySummaryNotification();

    final sundayTarget = calculateNextSundayTarget(dailyNotificationTime);
    final sundayStart = DateTime(sundayTarget.year, sundayTarget.month, sundayTarget.day);
    final sundayEnd = sundayStart.add(const Duration(days: 7));

    // Count items whose expiry date falls within [sundayStart, sundayEnd]
    int count = 0;
    for (final item in activeItems) {
      if (item.status != 'active') continue;
      try {
        final parts = item.expiryDate.split('-');
        final exp = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        if (!exp.isBefore(sundayStart) && exp.isBefore(sundayEnd)) {
          count++;
        }
      } catch (_) {}
    }

    final title = getWeeklySummaryTitle(localeCode);
    final body = getWeeklySummaryBody(count, localeCode);

    final tzFiresAt = tz.TZDateTime.from(sundayTarget, tz.local);

    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Weekly overview of upcoming item expirations',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const notifDetails = NotificationDetails(android: androidDetails);

    try {
      await _notifications.zonedSchedule(
        weeklySummaryNotifId,
        title,
        body,
        tzFiresAt,
        notifDetails,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (_) {
      try {
        await _notifications.zonedSchedule(
          weeklySummaryNotifId,
          title,
          body,
          tzFiresAt,
          notifDetails,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.inexact,
        );
      } catch (_) {}
    }
  }

  Future<void> cancelWeeklySummaryNotification() async {
    await _notifications.cancel(weeklySummaryNotifId);
  }

  /// Schedules a test push notification after delaySeconds (default 10s).
  Future<void> scheduleTestNotification({int delaySeconds = 10}) async {
    final scheduledDate = tz.TZDateTime.now(tz.local).add(Duration(seconds: delaySeconds));

    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Notifications for upcoming item expirations',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const notifDetails = NotificationDetails(android: androidDetails);

    try {
      await _notifications.zonedSchedule(
        999999,
        'Dateora Test Alert ⏰',
        'Notification system bilkul sahi kaam kar raha hai! App band hone ke baad bhi alert deliver hua.',
        scheduledDate,
        notifDetails,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (_) {
      try {
        await _notifications.zonedSchedule(
          999999,
          'Dateora Test Alert ⏰',
          'Notification system bilkul sahi kaam kar raha hai! App band hone ke baad bhi alert deliver hua.',
          scheduledDate,
          notifDetails,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.inexact,
        );
      } catch (_) {
        // Fallback to immediate notification if background alarms are blocked
        await _notifications.show(
          999999,
          'Dateora Test Alert ⏰',
          'Notification system active hai! Alert delivered successfully.',
          notifDetails,
        );
      }
    }
  }
}
