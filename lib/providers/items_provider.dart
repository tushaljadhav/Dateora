import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item.dart';
import '../models/status_evaluation.dart';
import '../services/analytics_service.dart';
import '../services/item_repository.dart';
import '../services/notification_service.dart';

class ItemsProvider with ChangeNotifier {
  final ItemRepository _repo = ItemRepository.instance;

  List<Item> _activeItems = [];
  List<Item> _historyItems = [];
  bool _isLoading = false;

  String _searchQuery = '';
  String _statusFilter = 'all'; // all, expiring_soon, expired, safe
  String? _selectedCategory;
  String _sortOption = 'soonest'; // soonest, recently_added, name_asc

  List<Item> get activeItems => _activeItems;
  List<Item> get historyItems => _historyItems;
  bool get isLoading => _isLoading;

  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;
  String? get selectedCategory => _selectedCategory;
  String get sortOption => _sortOption;

  // Stats
  int get totalCount => _activeItems.length;

  int get expiringSoonCount => _activeItems
      .where((i) => i.evaluateStatus().status == ComputedItemStatus.expiringSoon)
      .length;

  int get expiredCount => _activeItems
      .where((i) => i.evaluateStatus().status == ComputedItemStatus.expired)
      .length;

  int get safeCount => _activeItems
      .where((i) => i.evaluateStatus().status == ComputedItemStatus.safe)
      .length;

  // Filtered & Sorted items for Items Screen
  List<Item> get filteredItems {
    var list = List<Item>.from(_activeItems);

    // 1. Search Query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      list = list.where((i) => i.name.toLowerCase().contains(q) || i.category.toLowerCase().contains(q)).toList();
    }

    // 2. Category Filter
    if (_selectedCategory != null) {
      list = list.where((i) => i.category == _selectedCategory).toList();
    }

    // 3. Status Filter
    if (_statusFilter == 'expiring_soon') {
      list = list.where((i) => i.evaluateStatus().status == ComputedItemStatus.expiringSoon).toList();
    } else if (_statusFilter == 'expired') {
      list = list.where((i) => i.evaluateStatus().status == ComputedItemStatus.expired).toList();
    } else if (_statusFilter == 'safe') {
      list = list.where((i) => i.evaluateStatus().status == ComputedItemStatus.safe).toList();
    }

    // 4. Sorting
    if (_sortOption == 'soonest') {
      list.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    } else if (_sortOption == 'recently_added') {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_sortOption == 'name_asc') {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }

    return list;
  }

  // Next expiring items (for Home Screen preview)
  List<Item> get expiringSoonItems {
    final list = _activeItems.where((i) {
      final status = i.evaluateStatus().status;
      return status == ComputedItemStatus.expiringSoon || status == ComputedItemStatus.expired;
    }).toList();
    list.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return list;
  }

  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();

    try {
      _activeItems = await _repo.getActiveItems();
      _historyItems = await _repo.getHistoryItems();

      // Reschedule weekly summary if enabled
      try {
        final prefs = await SharedPreferences.getInstance();
        if (prefs.getBool('weekly_summary_enabled') ?? true) {
          final dailyTime = prefs.getString('daily_notification_time') ?? '09:00';
          final langStr = prefs.getString('app_language');
          final localeCode = (langStr == null || langStr == 'system') ? null : langStr;
          await NotificationService.instance.scheduleWeeklySummaryNotification(
            _activeItems,
            dailyNotificationTime: dailyTime,
            localeCode: localeCode,
          );
        }
      } catch (_) {}
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setStatusFilter(String filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  void setSelectedCategory(String? cat) {
    _selectedCategory = cat;
    notifyListeners();
  }

  void setSortOption(String sort) {
    _sortOption = sort;
    notifyListeners();
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
    final newItem = await _repo.addItem(
      name: name,
      category: category,
      expiryDate: expiryDate,
      photoUri: photoUri,
      quantity: quantity,
      unit: unit,
      location: location,
      notes: notes,
      reminderOffsets: reminderOffsets,
      price: price,
      status: status,
      statusChangedAt: statusChangedAt,
      dailyNotificationTime: dailyNotificationTime,
    );

    await loadItems();
    return newItem;
  }

  Future<void> clearAllItems() async {
    await _repo.clearAllItems();
    await loadItems();
  }

  Future<Item> updateItem(Item item, {String dailyNotificationTime = '09:00'}) async {
    final updated = await _repo.updateItem(item, dailyNotificationTime: dailyNotificationTime);
    await loadItems();
    return updated;
  }

  Future<void> deleteItem(Item item) async {
    await _repo.deleteItem(item);
    await loadItems();
  }

  Future<void> markItemStatus(Item item, String status) async {
    await _repo.markItemStatus(item, status);
    if (status == 'used') {
      AnalyticsService.instance.logItemMarkedUsed();
    } else if (status == 'disposed') {
      AnalyticsService.instance.logItemMarkedDisposed();
    }
    await loadItems();
  }

  Future<void> restoreItem(Item item, {String dailyNotificationTime = '09:00'}) async {
    await _repo.restoreItem(item, dailyNotificationTime: dailyNotificationTime);
    await loadItems();
  }

  /// Populates realistic grocery, dairy, household, and medicine items across staggered dates,
  /// plus consumed and disposed items to power authentic Bachat savings and history.
  Future<void> loadSampleData({bool clearExisting = true}) async {
    if (clearExisting) {
      await _repo.clearAllItems();
    }

    final now = DateTime.now();
    final dateFmt = DateFormat('yyyy-MM-dd');

    // 1. Realistic Active Products (Staggered from expired to today to upcoming months)
    final activeSamples = [
      {
        'name': 'Multi-Grain Sliced Bread',
        'category': 'groceries',
        'expiryDate': dateFmt.format(now.subtract(const Duration(days: 2))), // Expired 2 days ago
        'location': 'Kitchen Counter',
        'quantity': 1.0,
        'unit': 'pack',
        'price': 50.0,
        'photoUri': 'assets/demo/bread.jpg',
        'notes': 'Use for toast or dispose',
        'offsets': [3, 1],
      },
      {
        'name': 'Organic Whole Milk',
        'category': 'dairy',
        'expiryDate': dateFmt.format(now), // Expiring Today!
        'location': 'Fridge Door',
        'quantity': 1.0,
        'unit': 'L',
        'price': 65.0,
        'photoUri': 'assets/demo/milk.jpg',
        'notes': 'Fresh cow milk - finish today',
        'offsets': [1, 0],
      },
      {
        'name': 'Greek Yogurt Tub (400g)',
        'category': 'dairy',
        'expiryDate': dateFmt.format(now.add(const Duration(days: 2))), // In 2 days
        'location': 'Fridge Top Shelf',
        'quantity': 400.0,
        'unit': 'g',
        'price': 120.0,
        'photoUri': 'assets/demo/yogurt.jpg',
        'notes': 'Natural unsweetened probiotic yogurt',
        'offsets': [3, 1],
      },
      {
        'name': 'Fresh Strawberries Box',
        'category': 'groceries',
        'expiryDate': dateFmt.format(now.add(const Duration(days: 5))), // In 5 days
        'location': 'Crisper Drawer',
        'quantity': 250.0,
        'unit': 'g',
        'price': 140.0,
        'photoUri': 'assets/demo/strawberries.jpg',
        'notes': 'Sweet Mahabaleshwar berries',
        'offsets': [3, 1],
      },
      {
        'name': 'Farm Fresh Eggs (12-pack)',
        'category': 'dairy',
        'expiryDate': dateFmt.format(now.add(const Duration(days: 12))), // In 12 days
        'location': 'Fridge Middle Shelf',
        'quantity': 12.0,
        'unit': 'pcs',
        'price': 110.0,
        'photoUri': 'assets/demo/eggs.jpg',
        'notes': 'Grade A organic white eggs',
        'offsets': [5, 2],
      },
      {
        'name': 'Lemon Dishwashing Gel (500ml)',
        'category': 'household',
        'expiryDate': dateFmt.format(now.add(const Duration(days: 25))), // In 25 days (late this month)
        'location': 'Kitchen Sink',
        'quantity': 500.0,
        'unit': 'ml',
        'price': 125.0,
        'photoUri': 'assets/demo/dishwash.jpg',
        'notes': 'Degreasing concentrated formula',
        'offsets': [7, 3],
      },
      {
        'name': 'Herbal Cough Syrup (100ml)',
        'category': 'medicine',
        'expiryDate': dateFmt.format(now.add(const Duration(days: 45))), // Next month!
        'location': 'Medicine Cabinet',
        'quantity': 1.0,
        'unit': 'bottle',
        'price': 95.0,
        'photoUri': 'assets/demo/cough_syrup.jpg',
        'notes': 'Non-drowsy Ayurvedic syrup',
        'offsets': [14, 3],
      },
      {
        'name': 'Paracetamol 500mg Tablets',
        'category': 'medicine',
        'expiryDate': dateFmt.format(now.add(const Duration(days: 120))), // In 4 months
        'location': 'First Aid Box',
        'quantity': 10.0,
        'unit': 'tablets',
        'price': 35.0,
        'photoUri': 'assets/demo/medicine.jpg',
        'notes': 'Fever & headache relief strip',
        'offsets': [30, 7],
      },
      {
        'name': 'First Aid Antiseptic Liquid',
        'category': 'medicine',
        'expiryDate': dateFmt.format(now.add(const Duration(days: 300))), // In 10 months
        'location': 'Bathroom Shelf',
        'quantity': 500.0,
        'unit': 'ml',
        'price': 165.0,
        'photoUri': 'assets/demo/antiseptic.jpg',
        'notes': 'Hospital grade disinfectant',
        'offsets': [30, 7],
      },
    ];

    for (final s in activeSamples) {
      await _repo.addItem(
        name: s['name'] as String,
        category: s['category'] as String,
        expiryDate: s['expiryDate'] as String,
        photoUri: s['photoUri'] as String?,
        location: s['location'] as String?,
        quantity: s['quantity'] as double?,
        unit: s['unit'] as String?,
        price: s['price'] as double?,
        notes: s['notes'] as String?,
        reminderOffsets: s['offsets'] as List<int>?,
        status: 'active',
      );
    }

    // 2. Realistic Consumed Items (Powering Bachat ₹ Saved)
    final usedSamples = [
      {
        'name': 'Amul Pure Desi Ghee (1L)',
        'category': 'dairy',
        'expiryDate': dateFmt.format(now.subtract(const Duration(days: 4))),
        'location': 'Pantry Top Shelf',
        'quantity': 1.0,
        'unit': 'L',
        'price': 620.0,
        'photoUri': 'assets/demo/milk.jpg',
        'notes': 'Consumed completely before expiry',
        'statusChangedAt': now.subtract(const Duration(days: 3)).toIso8601String(),
      },
      {
        'name': 'Tata Sampann Toor Dal (1kg)',
        'category': 'groceries',
        'expiryDate': dateFmt.format(now.add(const Duration(days: 50))),
        'location': 'Kitchen Cabinet',
        'quantity': 1.0,
        'unit': 'kg',
        'price': 175.0,
        'photoUri': 'assets/demo/bread.jpg',
        'notes': 'Finished unpolished dal packet',
        'statusChangedAt': now.subtract(const Duration(days: 2)).toIso8601String(),
      },
      {
        'name': 'Dettol Handwash Refill (750ml)',
        'category': 'household',
        'expiryDate': dateFmt.format(now.add(const Duration(days: 80))),
        'location': 'Washroom Cabinet',
        'quantity': 750.0,
        'unit': 'ml',
        'price': 125.0,
        'photoUri': 'assets/demo/dishwash.jpg',
        'notes': 'Refilled dispenser bottles',
        'statusChangedAt': now.subtract(const Duration(days: 1)).toIso8601String(),
      },
    ];

    for (final u in usedSamples) {
      await _repo.addItem(
        name: u['name'] as String,
        category: u['category'] as String,
        expiryDate: u['expiryDate'] as String,
        photoUri: u['photoUri'] as String?,
        location: u['location'] as String?,
        quantity: u['quantity'] as double?,
        unit: u['unit'] as String?,
        price: u['price'] as double?,
        notes: u['notes'] as String?,
        status: 'used',
        statusChangedAt: u['statusChangedAt'] as String?,
      );
    }

    // 3. Realistic Disposed Item (Powering Bachat ₹ Wasted)
    final disposedSamples = [
      {
        'name': 'Organic Strawberries & Mint Leaves',
        'category': 'groceries',
        'expiryDate': dateFmt.format(now.subtract(const Duration(days: 5))),
        'location': 'Vegetable Basket',
        'quantity': 2.0,
        'unit': 'bunches',
        'price': 40.0,
        'photoUri': 'assets/demo/strawberries.jpg',
        'notes': 'Spoiled due to humidity',
        'statusChangedAt': now.subtract(const Duration(days: 3)).toIso8601String(),
      },
    ];

    for (final d in disposedSamples) {
      await _repo.addItem(
        name: d['name'] as String,
        category: d['category'] as String,
        expiryDate: d['expiryDate'] as String,
        photoUri: d['photoUri'] as String?,
        location: d['location'] as String?,
        quantity: d['quantity'] as double?,
        unit: d['unit'] as String?,
        price: d['price'] as double?,
        notes: d['notes'] as String?,
        status: 'disposed',
        statusChangedAt: d['statusChangedAt'] as String?,
      );
    }

    await loadItems();
  }
}
