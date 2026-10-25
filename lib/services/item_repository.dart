import 'package:uuid/uuid.dart';
import '../models/item.dart';
import '../database/database_helper.dart';
import 'notification_service.dart';
import 'photo_service.dart';

class ItemRepository {
  static final ItemRepository instance = ItemRepository._init();
  final DatabaseHelper _db = DatabaseHelper.instance;
  final NotificationService _notifications = NotificationService.instance;
  final Uuid _uuid = const Uuid();

  ItemRepository._init();

  Future<List<Item>> getActiveItems() async {
    return await _db.getActiveItems();
  }

  Future<List<Item>> getHistoryItems() async {
    return await _db.getHistoryItems();
  }

  Future<List<Item>> getAllItems() async {
    return await _db.getAllItems();
  }

  Future<Item?> getItem(String id) async {
    return await _db.getItemById(id);
  }

  Future<Item> addItem({
    required String name,
    required String category,
    required String expiryDate,
    String? photoUri,
    double? quantity,
    String? unit,
    String? location,
    String? notes,
    List<int>? reminderOffsets,
    double? price,
    String status = 'active',
    String? statusChangedAt,
    String dailyNotificationTime = '09:00',
  }) async {
    final now = DateTime.now().toIso8601String();
    final item = Item(
      id: _uuid.v4(),
      name: name.trim(),
      category: category,
      expiryDate: expiryDate,
      photoUri: photoUri,
      quantity: quantity,
      unit: unit,
      location: location,
      notes: notes,
      reminderOffsets: reminderOffsets ?? [3],
      status: status,
      statusChangedAt: statusChangedAt,
      price: price,
      createdAt: now,
      updatedAt: now,
    );

    await _db.insertItem(item);

    // Schedule notifications only for active items
    if (status == 'active') {
      try {
        final records = await _notifications.scheduleItemReminders(
          item,
          dailyNotificationTime: dailyNotificationTime,
        );
        await _db.replaceNotifications(item.id, records);
      } catch (_) {}
    }

    return item;
  }

  Future<void> clearAllItems() async {
    try {
      await _notifications.cancelAll();
    } catch (_) {}
    await _db.clearAllItems();
  }

  Future<Item> updateItem(
    Item updatedItem, {
    String dailyNotificationTime = '09:00',
  }) async {
    final item = updatedItem.copyWith(
      updatedAt: DateTime.now().toIso8601String(),
    );

    await _db.updateItem(item);

    // Reschedule notifications
    try {
      final records = await _notifications.scheduleItemReminders(
        item,
        dailyNotificationTime: dailyNotificationTime,
      );
      await _db.replaceNotifications(item.id, records);
    } catch (_) {}

    return item;
  }

  Future<void> deleteItem(Item item) async {
    await PhotoService.deletePhotoFile(item.photoUri);
    try {
      await _notifications.cancelItemReminders(item);
    } catch (_) {}
    await _db.deleteNotificationsForItem(item.id);
    await _db.deleteItem(item.id);
  }

  Future<Item> markItemStatus(
    Item item,
    String newStatus, // used, disposed
  ) async {
    final status = newStatus == 'finished' ? 'used' : newStatus;
    final now = DateTime.now().toIso8601String();
    final updated = item.copyWith(
      status: status,
      statusChangedAt: now,
      updatedAt: now,
    );

    await _db.updateItem(updated);
    // Cancel active notifications when marked used/disposed
    try {
      await _notifications.cancelItemReminders(item);
    } catch (_) {}
    await _db.deleteNotificationsForItem(item.id);

    return updated;
  }

  Future<Item> restoreItem(
    Item item, {
    String dailyNotificationTime = '09:00',
  }) async {
    final now = DateTime.now().toIso8601String();
    final updated = item.copyWith(
      status: 'active',
      clearStatusChangedAt: true,
      updatedAt: now,
    );

    await _db.updateItem(updated);

    // Re-schedule reminders
    try {
      final records = await _notifications.scheduleItemReminders(
        updated,
        dailyNotificationTime: dailyNotificationTime,
      );
      await _db.replaceNotifications(updated.id, records);
    } catch (_) {}

    return updated;
  }
}
