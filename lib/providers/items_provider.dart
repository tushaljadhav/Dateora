import 'package:flutter/material.dart';
import '../models/item.dart';
import '../models/status_evaluation.dart';
import '../services/item_repository.dart';

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
    await loadItems();
  }

  Future<void> restoreItem(Item item, {String dailyNotificationTime = '09:00'}) async {
    await _repo.restoreItem(item, dailyNotificationTime: dailyNotificationTime);
    await loadItems();
  }
}
