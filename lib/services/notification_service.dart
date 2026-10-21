import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/item.dart';
import '../models/notification_record.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  NotificationService._init();

  static const String channelId = 'expiry_reminders';
  static const String channelName = 'Expiry Reminders';

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

    await _notifications.initialize(initSettings);

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

  String getNotificationBody(String itemName, int offsetDays) {
    if (offsetDays == 0) return '$itemName expires today.';
    if (offsetDays == 1) return '$itemName expires tomorrow.';
    return '$itemName expires in $offsetDays days.';
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

  Future<List<NotificationRecord>> scheduleItemReminders(
    Item item, {
    String dailyNotificationTime = '09:00',
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
            'Dateora Expiry Alert',
            getNotificationBody(item.name, offset),
            tzFiresAt,
            notifDetails,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        } catch (_) {
          // Fallback to inexact scheduling if exact alarms are not permitted
          try {
            await _notifications.zonedSchedule(
              notifId,
              'Dateora Expiry Alert',
              getNotificationBody(item.name, offset),
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
      final notifId = _generateIntId(item.id, offset);
      await _notifications.cancel(notifId);
    }
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
