import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:dateora/models/item.dart';
import 'package:dateora/models/category_model.dart';
import 'package:dateora/models/status_evaluation.dart';
import 'package:dateora/services/notification_service.dart';
import 'package:dateora/services/ai_expiry_scan_service.dart';

void main() {
  group('Category Model Tests', () {
    test('Preset categories are loaded and found by ID', () {
      expect(CategoryModel.presetCategories.length, 9);
      final groceries = CategoryModel.getById('groceries');
      expect(groceries.name, 'Groceries');

      final unknown = CategoryModel.getById('non_existent');
      expect(unknown.id, 'custom');
    });
  });

  group('Item Filtering and Sorting Logic', () {
    final now = DateTime.now();
    final items = [
      Item(
        id: '1',
        name: 'Organic Almond Milk',
        category: 'dairy',
        expiryDate: '${now.year}-${now.month.toString().padLeft(2, '0')}-${(now.day + 2).toString().padLeft(2, '0')}',
        reminderOffsets: [3, 1],
        createdAt: '2026-10-01T10:00:00.000Z',
        updatedAt: '2026-10-01T10:00:00.000Z',
      ),
      Item(
        id: '2',
        name: 'Paracetamol 500mg',
        category: 'medicine',
        expiryDate: '${now.year}-${now.month.toString().padLeft(2, '0')}-${(now.day + 20).toString().padLeft(2, '0')}',
        reminderOffsets: [7],
        createdAt: '2026-10-05T12:00:00.000Z',
        updatedAt: '2026-10-05T12:00:00.000Z',
      ),
      Item(
        id: '3',
        name: 'Greek Yogurt',
        category: 'dairy',
        expiryDate: '${now.year}-${now.month.toString().padLeft(2, '0')}-${(now.day - 1).toString().padLeft(2, '0')}',
        reminderOffsets: [1],
        createdAt: '2026-09-20T08:00:00.000Z',
        updatedAt: '2026-09-20T08:00:00.000Z',
      ),
    ];

    test('Search filter matches item name case-insensitively', () {
      const q = 'milk';
      final matches = items.where((i) => i.name.toLowerCase().contains(q)).toList();
      expect(matches.length, 1);
      expect(matches.first.id, '1');
    });

    test('Category filter correctly isolates category items', () {
      final dairyItems = items.where((i) => i.category == 'dairy').toList();
      expect(dairyItems.length, 2);
    });

    test('Status calculation classifies expiring soon and expired', () {
      final expiringSoon = items.where((i) => i.evaluateStatus().status == ComputedItemStatus.expiringSoon).toList();
      final expired = items.where((i) => i.evaluateStatus().status == ComputedItemStatus.expired).toList();
      final safe = items.where((i) => i.evaluateStatus().status == ComputedItemStatus.safe).toList();

      expect(expiringSoon.length, 1); // Almond Milk in 2 days
      expect(expired.length, 1);      // Greek Yogurt expired yesterday
      expect(safe.length, 1);         // Paracetamol in 20 days
    });

    test('Sorting by expiry date orders soonest first', () {
      final sorted = List<Item>.from(items)..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
      expect(sorted[0].id, '3'); // Greek Yogurt (-1 day)
      expect(sorted[1].id, '1'); // Almond Milk (+2 days)
      expect(sorted[2].id, '2'); // Paracetamol (+20 days)
    });
  });

  group('Lifecycle State Transitions', () {
    test('Marking item as used/disposed updates status correctly', () {
      const active = Item(
        id: 'item-10',
        name: 'Bread',
        category: 'groceries',
        expiryDate: '2026-10-15',
        reminderOffsets: [1],
        status: 'active',
        createdAt: '2026-10-10T10:00:00.000Z',
        updatedAt: '2026-10-10T10:00:00.000Z',
      );

      final used = active.copyWith(status: 'used', statusChangedAt: '2026-10-12T15:00:00.000Z');
      expect(used.isActive, false);
      expect(used.status, 'used');
      expect(used.statusChangedAt, isNotNull);

      final disposed = active.copyWith(status: 'disposed', statusChangedAt: '2026-10-12T15:00:00.000Z');
      expect(disposed.isActive, false);
      expect(disposed.status, 'disposed');

      final restored = used.copyWith(status: 'active', clearStatusChangedAt: true);
      expect(restored.isActive, true);
      expect(restored.status, 'active');
      expect(restored.statusChangedAt, isNull);
    });

    test('Item.fromMap maps legacy finished status to used for imports and migrations', () {
      final legacyFinishedItemMap = {
        'id': 'legacy-item-1',
        'name': 'Oat Milk',
        'category': 'dairy',
        'expiry_date': '2026-10-01',
        'reminder_offsets': [3],
        'status': 'finished',
        'created_at': '2026-09-20T10:00:00.000Z',
        'updated_at': '2026-09-25T10:00:00.000Z',
      };

      final item = Item.fromMap(legacyFinishedItemMap);
      expect(item.status, 'used');
      expect(item.isActive, false);
    });
  });

  group('Notification Time Calculation', () {
    test('Calculates firesAt date correctly subtracting offset days', () {
      final notifService = NotificationService.instance;
      final firesAt = notifService.calculateFiresAt('2026-10-20', 3, '09:00');

      expect(firesAt.year, 2026);
      expect(firesAt.month, 10);
      expect(firesAt.day, 17); // 20 - 3 = 17
      expect(firesAt.hour, 9);
      expect(firesAt.minute, 0);
    });
  });

  group('AI Expiry Scan & Date Normalization', () {
    test('Correctly normalizes various date formats into YYYY-MM-DD', () {
      expect(GeminiExpiryScanService.parseDateToIso('2026-11-25'), '2026-11-25');
      expect(GeminiExpiryScanService.parseDateToIso('25/11/2026'), '2026-11-25');
      expect(GeminiExpiryScanService.parseDateToIso('25-11-2026'), '2026-11-25');
      expect(GeminiExpiryScanService.parseDateToIso('2026/11/25'), '2026-11-25');
      expect(GeminiExpiryScanService.parseDateToIso('25 Oct 2026'), '2026-10-25');
    });

    test('MockExpiryScanService safely returns offline status without fake data', () async {
      final mock = MockExpiryScanService();
      final file = File('test_image.jpg');
      final result = await mock.scanImage(file);

      expect(result.isSuccess, false);
      expect(result.hasDetectedDate, false);
      expect(result.productName, isNull);
      expect(result.expiryDate, isNull);
      expect(result.confidence, 0.0);
    });
  });
}
