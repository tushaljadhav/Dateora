import 'package:flutter_test/flutter_test.dart';
import 'package:dateora/models/item.dart';
import 'package:dateora/services/savings_service.dart';

void main() {
  group('Bachat Savings Calculation Tests', () {
    test('Calculates saved amount for used items and wasted for disposed items', () {
      final items = [
        const Item(
          id: '1',
          name: 'Milk',
          category: 'dairy',
          expiryDate: '2026-10-10',
          price: 65.0,
          status: 'used',
          statusChangedAt: '2026-10-05T14:30:00.000',
          reminderOffsets: [3],
          createdAt: '2026-10-01T00:00:00.000',
          updatedAt: '2026-10-05T14:30:00.000',
        ),
        const Item(
          id: '2',
          name: 'Bread',
          category: 'groceries',
          expiryDate: '2026-10-08',
          price: 40.0,
          status: 'disposed',
          statusChangedAt: '2026-10-08T18:00:00.000',
          reminderOffsets: [1],
          createdAt: '2026-10-03T00:00:00.000',
          updatedAt: '2026-10-08T18:00:00.000',
        ),
        const Item(
          id: '3',
          name: 'Eggs',
          category: 'dairy',
          expiryDate: '2026-10-20',
          price: 120.0,
          status: 'used',
          statusChangedAt: '2026-10-15T09:00:00.000',
          reminderOffsets: [3],
          createdAt: '2026-10-01T00:00:00.000',
          updatedAt: '2026-10-15T09:00:00.000',
        ),
      ];

      final savings = SavingsService.calculateMonthSavings(items, year: 2026, month: 10);

      expect(savings.savedAmount, 185.0); // 65 + 120
      expect(savings.wastedAmount, 40.0);
      expect(savings.usedCount, 2);
      expect(savings.disposedCount, 1);
      expect(savings.netSavings, 145.0);
    });

    test('Items with null price are ignored in money totals but counted in numbers', () {
      final items = [
        const Item(
          id: '1',
          name: 'Homecooked Jam',
          category: 'pantry',
          expiryDate: '2026-10-25',
          price: null, // No price entered
          status: 'used',
          statusChangedAt: '2026-10-12T10:00:00.000',
          reminderOffsets: [3],
          createdAt: '2026-10-01T00:00:00.000',
          updatedAt: '2026-10-12T10:00:00.000',
        ),
        const Item(
          id: '2',
          name: 'Leftover Rice',
          category: 'pantry',
          expiryDate: '2026-10-14',
          price: null, // No price entered
          status: 'disposed',
          statusChangedAt: '2026-10-14T11:00:00.000',
          reminderOffsets: [1],
          createdAt: '2026-10-10T00:00:00.000',
          updatedAt: '2026-10-14T11:00:00.000',
        ),
        const Item(
          id: '3',
          name: 'Butter',
          category: 'dairy',
          expiryDate: '2026-10-30',
          price: 55.0,
          status: 'used',
          statusChangedAt: '2026-10-18T16:00:00.000',
          reminderOffsets: [3],
          createdAt: '2026-10-05T00:00:00.000',
          updatedAt: '2026-10-18T16:00:00.000',
        ),
      ];

      final savings = SavingsService.calculateMonthSavings(items, year: 2026, month: 10);

      // Money only counts Butter (55.0)
      expect(savings.savedAmount, 55.0);
      expect(savings.wastedAmount, 0.0);
      // Both null-price items are counted in numbers
      expect(savings.usedCount, 2); // Jam + Butter
      expect(savings.disposedCount, 1); // Rice
      expect(savings.totalItems, 3);
    });

    test('Month boundaries are respected accurately', () {
      final items = [
        // Exactly at start of October
        const Item(
          id: '1',
          name: 'Oct Start Item',
          category: 'groceries',
          expiryDate: '2026-10-05',
          price: 100.0,
          status: 'used',
          statusChangedAt: '2026-10-01T00:00:01.000',
          reminderOffsets: [3],
          createdAt: '2026-09-25T00:00:00.000',
          updatedAt: '2026-10-01T00:00:01.000',
        ),
        // Just before October (September 30th 23:59:59)
        const Item(
          id: '2',
          name: 'Sep End Item',
          category: 'groceries',
          expiryDate: '2026-09-30',
          price: 50.0,
          status: 'used',
          statusChangedAt: '2026-09-30T23:59:59.000',
          reminderOffsets: [3],
          createdAt: '2026-09-20T00:00:00.000',
          updatedAt: '2026-09-30T23:59:59.000',
        ),
        // Exactly at end of October
        const Item(
          id: '3',
          name: 'Oct End Item',
          category: 'groceries',
          expiryDate: '2026-10-31',
          price: 75.0,
          status: 'disposed',
          statusChangedAt: '2026-10-31T23:59:59.000',
          reminderOffsets: [3],
          createdAt: '2026-10-20T00:00:00.000',
          updatedAt: '2026-10-31T23:59:59.000',
        ),
        // Just into November (November 1st 00:00:01)
        const Item(
          id: '4',
          name: 'Nov Start Item',
          category: 'groceries',
          expiryDate: '2026-11-05',
          price: 80.0,
          status: 'used',
          statusChangedAt: '2026-11-01T00:00:01.000',
          reminderOffsets: [3],
          createdAt: '2026-10-25T00:00:00.000',
          updatedAt: '2026-11-01T00:00:01.000',
        ),
      ];

      // October savings
      final octSavings = SavingsService.calculateMonthSavings(items, year: 2026, month: 10);
      expect(octSavings.savedAmount, 100.0); // Only Oct Start Item
      expect(octSavings.wastedAmount, 75.0); // Only Oct End Item
      expect(octSavings.usedCount, 1);
      expect(octSavings.disposedCount, 1);

      // September savings
      final sepSavings = SavingsService.calculateMonthSavings(items, year: 2026, month: 9);
      expect(sepSavings.savedAmount, 50.0);
      expect(sepSavings.usedCount, 1);

      // November savings
      final novSavings = SavingsService.calculateMonthSavings(items, year: 2026, month: 11);
      expect(novSavings.savedAmount, 80.0);
      expect(novSavings.usedCount, 1);
    });

    test('calculateLastNMonths returns 6 consecutive months in descending order', () {
      final ref = DateTime(2026, 3, 15); // March 2026
      final months = SavingsService.calculateLastNMonths([], referenceDate: ref, monthCount: 6);

      expect(months.length, 6);
      expect(months[0].year, 2026);
      expect(months[0].month, 3); // Mar 2026
      expect(months[1].year, 2026);
      expect(months[1].month, 2); // Feb 2026
      expect(months[2].year, 2026);
      expect(months[2].month, 1); // Jan 2026
      expect(months[3].year, 2025);
      expect(months[3].month, 12); // Dec 2025 (year rollover)
      expect(months[4].year, 2025);
      expect(months[4].month, 11); // Nov 2025
      expect(months[5].year, 2025);
      expect(months[5].month, 10); // Oct 2025
    });

    test('Active items are not counted towards savings or waste', () {
      final items = [
        const Item(
          id: '1',
          name: 'Active Milk',
          category: 'dairy',
          expiryDate: '2026-10-30',
          price: 50.0,
          status: 'active',
          reminderOffsets: [3],
          createdAt: '2026-10-01T00:00:00.000',
          updatedAt: '2026-10-01T00:00:00.000',
        ),
      ];

      final savings = SavingsService.calculateMonthSavings(items, year: 2026, month: 10);
      expect(savings.savedAmount, 0.0);
      expect(savings.wastedAmount, 0.0);
      expect(savings.usedCount, 0);
      expect(savings.disposedCount, 0);
    });
  });
}
