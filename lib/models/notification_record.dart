class NotificationRecord {
  final String id; // itemId:offsetDays
  final String itemId;
  final String firesAt;

  const NotificationRecord({
    required this.id,
    required this.itemId,
    required this.firesAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_id': itemId,
      'fires_at': firesAt,
    };
  }

  factory NotificationRecord.fromMap(Map<String, dynamic> map) {
    return NotificationRecord(
      id: map['id'] as String,
      itemId: map['item_id'] as String,
      firesAt: map['fires_at'] as String,
    );
  }
}
