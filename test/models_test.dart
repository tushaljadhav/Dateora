import 'package:flutter_test/flutter_test.dart';
import 'package:dateora/models/status_evaluation.dart';
import 'package:dateora/models/item.dart';
import 'package:dateora/models/notification_record.dart';

void main() {
  group('StatusEvaluation Tests', () {
    test('Calculates expired item correctly', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 2));
      final dateStr = '${pastDate.year}-${pastDate.month.toString().padLeft(2, '0')}-${pastDate.day.toString().padLeft(2, '0')}';
      final status = StatusEvaluation.evaluate(dateStr);

      expect(status.status, ComputedItemStatus.expired);
      expect(status.label, 'Expired');
    });

    test('Calculates expires today correctly', () {
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final status = StatusEvaluation.evaluate(dateStr);

      expect(status.status, ComputedItemStatus.expiringSoon);
      expect(status.label, 'Expires Today');
    });

    test('Calculates safe item correctly', () {
      final futureDate = DateTime.now().add(const Duration(days: 30));
      final dateStr = '${futureDate.year}-${futureDate.month.toString().padLeft(2, '0')}-${futureDate.day.toString().padLeft(2, '0')}';
      final status = StatusEvaluation.evaluate(dateStr);

      expect(status.status, ComputedItemStatus.safe);
      expect(status.label, 'Safe');
    });
  });

  group('Item Model Tests', () {
    test('toMap and fromMap preserves item properties', () {
      const item = Item(
        id: 'test-uuid-1',
        name: 'Whole Milk',
        category: 'dairy',
        expiryDate: '2026-10-25',
        quantity: 2.0,
        unit: 'cartons',
        location: 'Fridge',
        notes: 'Organic milk',
        reminderOffsets: [7, 3, 1],
        createdAt: '2026-10-13T00:00:00.000Z',
        updatedAt: '2026-10-13T00:00:00.000Z',
      );

      final map = item.toMap();
      final restored = Item.fromMap(map);

      expect(restored.id, item.id);
      expect(restored.name, item.name);
      expect(restored.category, item.category);
      expect(restored.expiryDate, item.expiryDate);
      expect(restored.quantity, 2.0);
      expect(restored.unit, 'cartons');
      expect(restored.reminderOffsets, [7, 3, 1]);
    });
  });

  group('NotificationRecord Model Tests', () {
    test('toMap and fromMap works without legacy notifee_trigger_id', () {
      const record = NotificationRecord(
        id: 'item-1:3',
        itemId: 'item-1',
        firesAt: '2026-10-20T09:00:00.000',
      );

      final map = record.toMap();
      expect(map.containsKey('notifee_trigger_id'), false);
      expect(map['id'], 'item-1:3');
      expect(map['item_id'], 'item-1');
      expect(map['fires_at'], '2026-10-20T09:00:00.000');

      final fromMap = NotificationRecord.fromMap(map);
      expect(fromMap.id, record.id);
      expect(fromMap.itemId, record.itemId);
      expect(fromMap.firesAt, record.firesAt);
    });
  });
}
