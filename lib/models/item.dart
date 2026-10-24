import 'dart:convert';
import 'status_evaluation.dart';

class Item {
  final String id;
  final String name;
  final String category;
  final String expiryDate; // YYYY-MM-DD
  final String? photoUri;
  final double? quantity;
  final String? unit;
  final String? location;
  final String? notes;
  final List<int> reminderOffsets;
  final String status; // active, used, disposed
  final String? statusChangedAt;
  final double? price;
  final String createdAt;
  final String updatedAt;

  const Item({
    required this.id,
    required this.name,
    required this.category,
    required this.expiryDate,
    this.photoUri,
    this.quantity,
    this.unit,
    this.location,
    this.notes,
    required this.reminderOffsets,
    this.status = 'active',
    this.statusChangedAt,
    this.price,
    required this.createdAt,
    required this.updatedAt,
  });

  StatusEvaluation evaluateStatus([int windowDays = 7]) {
    return StatusEvaluation.evaluate(expiryDate, windowDays: windowDays);
  }

  bool get isActive => status == 'active';

  Item copyWith({
    String? id,
    String? name,
    String? category,
    String? expiryDate,
    String? photoUri,
    double? quantity,
    String? unit,
    String? location,
    String? notes,
    List<int>? reminderOffsets,
    String? status,
    String? statusChangedAt,
    bool clearStatusChangedAt = false,
    double? price,
    bool clearPrice = false,
    String? createdAt,
    String? updatedAt,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      expiryDate: expiryDate ?? this.expiryDate,
      photoUri: photoUri ?? this.photoUri,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      reminderOffsets: reminderOffsets ?? this.reminderOffsets,
      status: status ?? this.status,
      statusChangedAt: clearStatusChangedAt ? null : (statusChangedAt ?? this.statusChangedAt),
      price: clearPrice ? null : (price ?? this.price),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Database map (SQLite column names)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'expiry_date': expiryDate,
      'photo_uri': photoUri,
      'quantity': quantity,
      'unit': unit,
      'location': location,
      'notes': notes,
      'reminder_offsets': jsonEncode(reminderOffsets),
      'status': status,
      'status_changed_at': statusChangedAt,
      'price': price,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // API JSON map (camelCase matching server sync API)
  Map<String, dynamic> toApiJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'expiryDate': expiryDate,
      'photoUri': photoUri,
      'quantity': quantity,
      'unit': unit,
      'location': location,
      'notes': notes,
      'reminderOffsets': reminderOffsets,
      'status': status,
      'statusChangedAt': statusChangedAt,
      'price': price,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    List<int> offsets = [3];
    final rawOffsets = map['reminder_offsets'] ?? map['reminderOffsets'];
    if (rawOffsets != null) {
      if (rawOffsets is List) {
        offsets = rawOffsets.map((e) => (e as num).toInt()).toList();
      } else if (rawOffsets is String) {
        try {
          final decoded = jsonDecode(rawOffsets);
          if (decoded is List) {
            offsets = decoded.map((e) => (e as num).toInt()).toList();
          }
        } catch (_) {
          offsets = [3];
        }
      }
    }

    final expiryDate = (map['expiry_date'] ?? map['expiryDate'] ?? '') as String;
    final photoUri = (map['photo_uri'] ?? map['photoUri']) as String?;
    final statusChangedAt = (map['status_changed_at'] ?? map['statusChangedAt']) as String?;
    final price = map['price'] != null ? (map['price'] as num).toDouble() : null;
    final createdAt = (map['created_at'] ?? map['createdAt'] ?? DateTime.now().toIso8601String()) as String;
    final updatedAt = (map['updated_at'] ?? map['updatedAt'] ?? DateTime.now().toIso8601String()) as String;

    String itemStatus = map['status'] as String? ?? 'active';
    if (itemStatus == 'finished') {
      itemStatus = 'used';
    }

    return Item(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      expiryDate: expiryDate,
      photoUri: photoUri,
      quantity: map['quantity'] != null ? (map['quantity'] as num).toDouble() : null,
      unit: map['unit'] as String?,
      location: map['location'] as String?,
      notes: map['notes'] as String?,
      reminderOffsets: offsets,
      status: itemStatus,
      statusChangedAt: statusChangedAt,
      price: price,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() => toApiJson();

  factory Item.fromJson(Map<String, dynamic> json) => Item.fromMap(json);
}
