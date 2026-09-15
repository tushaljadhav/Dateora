import { drizzle } from 'drizzle-orm/expo-sqlite';
import * as SQLite from 'expo-sqlite';
import { Platform } from 'react-native';
import * as schema from './schema';

export const DB_NAME = 'dateora.db';

export const isWeb = Platform.OS === 'web';

let expoDb: SQLite.SQLiteDatabase | null = null;
let dbInstance: ReturnType<typeof drizzle<typeof schema>> | null = null;

export function getDatabase() {
  if (isWeb) {
    return { db: null, expoDb: null };
  }

  if (!dbInstance) {
    try {
      expoDb = SQLite.openDatabaseSync(DB_NAME);
      dbInstance = drizzle(expoDb, { schema });
    } catch (e) {
      console.warn('Native SQLite not available, falling back:', e);
      return { db: null, expoDb: null };
    }
  }
  return { db: dbInstance, expoDb };
}

export async function initializeDatabase(): Promise<void> {
  if (isWeb) {
    // Web uses LocalStorage / in-memory adapter automatically
    return;
  }

  const { expoDb } = getDatabase();
  if (!expoDb) return;

  await expoDb.execAsync(`
    PRAGMA journal_mode = WAL;
    PRAGMA foreign_keys = ON;

    CREATE TABLE IF NOT EXISTS items (
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
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS notification_records (
      id TEXT PRIMARY KEY NOT NULL,
      item_id TEXT NOT NULL REFERENCES items(id) ON DELETE CASCADE,
      fires_at TEXT NOT NULL,
      notifee_trigger_id TEXT
    );

    CREATE TABLE IF NOT EXISTS app_settings (
      key TEXT PRIMARY KEY NOT NULL,
      value TEXT NOT NULL
    );

    CREATE INDEX IF NOT EXISTS idx_items_expiry ON items(expiry_date);
    CREATE INDEX IF NOT EXISTS idx_items_status ON items(status);
    CREATE INDEX IF NOT EXISTS idx_notifications_item ON notification_records(item_id);
  `);
}
