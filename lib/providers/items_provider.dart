import 'package:flutter/material.dart';
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
      dailyNotificationTime: dailyNotificationTime,
    );

    await loadItems();
    return newItem;
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

  /// Populates realistic grocery, dairy, and medicine items with high-res photos for Play Store screenshots
  Future<void> loadSampleData() async {
    final now = DateTime.now();
    final samples = [
      {
        'name': 'Organic Whole Milk',
        'category': 'dairy',
        'expiryDate': now.add(const Duration(days: 2)).toIso8601String(),
        'location': 'Fridge Door',
        'quantity': 1.0,
        'unit': 'L',
        'price': 65.0,
        'photoUri': 'assets/demo/milk.jpg',
      },
      {
        'name': 'Greek Yogurt Tub',
        'category': 'dairy',
        'expiryDate': now.add(const Duration(days: 4)).toIso8601String(),
        'location': 'Fridge Top Shelf',
        'quantity': 400.0,
        'unit': 'g',
        'price': 120.0,
        'photoUri': 'assets/demo/yogurt.jpg',
      },
      {
        'name': 'Multi-Grain Bread',
        'category': 'groceries',
        'expiryDate': now.add(const Duration(days: 3)).toIso8601String(),
        'location': 'Kitchen Counter',
        'quantity': 1.0,
        'unit': 'pack',
        'price': 50.0,
        'photoUri': 'assets/demo/bread.jpg',
      },
      {
        'name': 'Fresh Strawberries',
        'category': 'groceries',
        'expiryDate': now.add(const Duration(days: 6)).toIso8601String(),
        'location': 'Crisper Drawer',
        'quantity': 250.0,
        'unit': 'g',
        'price': 140.0,
        'photoUri': 'assets/demo/strawberries.jpg',
      },
      {
        'name': 'Farm Fresh Eggs (12-pack)',
        'category': 'dairy',
        'expiryDate': now.add(const Duration(days: 14)).toIso8601String(),
        'location': 'Fridge Middle Shelf',
        'quantity': 12.0,
        'unit': 'pcs',
        'price': 110.0,
        'photoUri': 'assets/demo/eggs.jpg',
      },
      {
        'name': 'Paracetamol 500mg',
        'category': 'medicine',
        'expiryDate': now.add(const Duration(days: 180)).toIso8601String(),
        'location': 'First Aid Box',
        'quantity': 10.0,
        'unit': 'tablets',
        'price': 35.0,
        'photoUri': 'assets/demo/medicine.jpg',
      },
    ];

    for (final s in samples) {
      await addItem(
        name: s['name'] as String,
        category: s['category'] as String,
        expiryDate: s['expiryDate'] as String,
        photoUri: s['photoUri'] as String?,
        location: s['location'] as String?,
        quantity: s['quantity'] as double?,
        unit: s['unit'] as String?,
        price: s['price'] as double?,
        reminderOffsets: [3, 1],
      );
    }
    await loadItems();
  }
}
