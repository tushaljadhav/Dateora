import '../models/item.dart';

/// Represents monthly savings and waste metrics.
class MonthlySavings {
  final int year;
  final int month;
  final double savedAmount;
  final double wastedAmount;
  final int usedCount;
  final int disposedCount;

  const MonthlySavings({
    required this.year,
    required this.month,
    required this.savedAmount,
    required this.wastedAmount,
    required this.usedCount,
    required this.disposedCount,
  });

  /// Net savings (saved - wasted)
  double get netSavings => savedAmount - wastedAmount;

  /// Total items processed (used + disposed)
  int get totalItems => usedCount + disposedCount;
}

/// Service to calculate savings ("Bachat") based on used and disposed items.
class SavingsService {
  /// Extracts the effective action date for an item.
  /// Priority: statusChangedAt -> updatedAt -> createdAt.
  static DateTime? getItemActionDate(Item item) {
    final dateStr = item.statusChangedAt ?? item.updatedAt;
    try {
      return DateTime.parse(dateStr).toLocal();
    } catch (_) {
      try {
        return DateTime.parse(item.createdAt).toLocal();
      } catch (_) {
        return null;
      }
    }
  }

  /// Calculates savings and waste for a specific year and month.
  static MonthlySavings calculateMonthSavings(
    List<Item> items, {
    required int year,
    required int month,
  }) {
    double saved = 0.0;
    double wasted = 0.0;
    int usedCount = 0;
    int disposedCount = 0;

    for (final item in items) {
      if (item.status != 'used' && item.status != 'disposed') {
        continue;
      }

      final actionDate = getItemActionDate(item);
      if (actionDate == null) continue;

      if (actionDate.year == year && actionDate.month == month) {
        if (item.status == 'used') {
          usedCount++;
          if (item.price != null && !item.price!.isNaN && item.price! > 0) {
            saved += item.price!;
          }
        } else if (item.status == 'disposed') {
          disposedCount++;
          if (item.price != null && !item.price!.isNaN && item.price! > 0) {
            wasted += item.price!;
          }
        }
      }
    }

    return MonthlySavings(
      year: year,
      month: month,
      savedAmount: saved,
      wastedAmount: wasted,
      usedCount: usedCount,
      disposedCount: disposedCount,
    );
  }

  /// Calculates the last N months of savings (including the reference month), descending (most recent first).
  static List<MonthlySavings> calculateLastNMonths(
    List<Item> items, {
    DateTime? referenceDate,
    int monthCount = 6,
  }) {
    final ref = (referenceDate ?? DateTime.now()).toLocal();
    final results = <MonthlySavings>[];

    for (int i = 0; i < monthCount; i++) {
      int targetMonth = ref.month - i;
      int targetYear = ref.year;
      while (targetMonth <= 0) {
        targetMonth += 12;
        targetYear -= 1;
      }

      results.add(calculateMonthSavings(items, year: targetYear, month: targetMonth));
    }

    return results;
  }
}
