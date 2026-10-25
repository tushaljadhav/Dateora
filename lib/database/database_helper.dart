import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/item.dart';
import '../models/notification_record.dart';

class DatabaseHelper {
  static const String _dbName = 'dateora.db';
  static const int _dbVersion = 3;

  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(_dbName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
    try {
      await db.rawQuery('PRAGMA journal_mode = WAL');
    } catch (_) {
      // Graceful fallback if platform does not return/allow journal_mode configuration
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE items (
        id TEXT PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        expiry_date TEXT NOT NULL,
        photo_uri TEXT,
        quantity REAL,
        unit TEXT,
        location TEXT,
        notes TEXT,
        reminder_offsets TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'active',
        status_changed_at TEXT,
        price REAL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE notification_records (
        id TEXT PRIMARY KEY NOT NULL,
        item_id TEXT NOT NULL,
        fires_at TEXT NOT NULL,
        FOREIGN KEY (item_id) REFERENCES items (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE app_settings (
        setting_key TEXT PRIMARY KEY NOT NULL,
        setting_value TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_items_expiry ON items(expiry_date)');
    await db.execute('CREATE INDEX idx_items_status ON items(status)');
    await db.execute('CREATE INDEX idx_notifications_item ON notification_records(item_id)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Task 3: Merge finished into used
      await db.execute("UPDATE items SET status = 'used' WHERE status = 'finished'");

      // Task 4: Safe removal of notifee_trigger_id via table swap
      await db.execute('''
        CREATE TABLE notification_records_new (
          id TEXT PRIMARY KEY NOT NULL,
          item_id TEXT NOT NULL,
          fires_at TEXT NOT NULL,
          FOREIGN KEY (item_id) REFERENCES items (id) ON DELETE CASCADE
        )
      ''');
      await db.execute('''
        INSERT INTO notification_records_new (id, item_id, fires_at)
        SELECT id, item_id, fires_at FROM notification_records
      ''');
      await db.execute('DROP TABLE notification_records');
      await db.execute('ALTER TABLE notification_records_new RENAME TO notification_records');
      await db.execute('CREATE INDEX idx_notifications_item ON notification_records(item_id)');
    }

    if (oldVersion < 3) {
      // Phase 3: Add price column to items for Bachat (savings tracker)
      await db.execute('ALTER TABLE items ADD COLUMN price REAL');
    }
  }

  // --- Items CRUD ---
  Future<int> insertItem(Item item) async {
    final db = await instance.database;
    return await db.insert('items', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateItem(Item item) async {
    final db = await instance.database;
    return await db.update('items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<int> deleteItem(String id) async {
    final db = await instance.database;
    return await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  Future<Item?> getItemById(String id) async {
    final db = await instance.database;
    final maps = await db.query('items', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Item.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Item>> getActiveItems() async {
    final db = await instance.database;
    final result = await db.query(
      'items',
      where: 'status = ?',
      whereArgs: ['active'],
      orderBy: 'expiry_date ASC',
    );
    return result.map((json) => Item.fromMap(json)).toList();
  }

  Future<List<Item>> getAllItems() async {
    final db = await instance.database;
    final result = await db.query('items', orderBy: 'expiry_date ASC');
    return result.map((json) => Item.fromMap(json)).toList();
  }

  Future<List<Item>> getHistoryItems() async {
    final db = await instance.database;
    final result = await db.query(
      'items',
      where: 'status != ?',
      whereArgs: ['active'],
      orderBy: 'status_changed_at DESC, updated_at DESC',
    );
    return result.map((json) => Item.fromMap(json)).toList();
  }

  // --- Notifications CRUD ---
  Future<void> replaceNotifications(String itemId, List<NotificationRecord> records) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('notification_records', where: 'item_id = ?', whereArgs: [itemId]);
      for (final r in records) {
        await txn.insert('notification_records', r.toMap());
      }
    });
  }

  Future<void> deleteNotificationsForItem(String itemId) async {
    final db = await instance.database;
    await db.delete('notification_records', where: 'item_id = ?', whereArgs: [itemId]);
  }

  // --- Settings ---
  Future<String?> getSetting(String key) async {
    final db = await instance.database;
    final res = await db.query('app_settings', where: 'setting_key = ?', whereArgs: [key]);
    if (res.isNotEmpty) {
      return res.first['setting_value'] as String?;
    }
    return null;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await instance.database;
    await db.insert(
      'app_settings',
      {'setting_key': key, 'setting_value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearAllItems() async {
    final db = await instance.database;
    await db.delete('notification_records');
    await db.delete('items');
  }

  Future<void> clearAllData() async {
    final db = await instance.database;
    await db.delete('notification_records');
    await db.delete('items');
    await db.delete('app_settings');
  }
}
