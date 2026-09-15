import { sqliteTable, text, real } from 'drizzle-orm/sqlite-core';

export const items = sqliteTable('items', {
  id: text('id').primaryKey(),
  name: text('name').notNull(),
  category: text('category').notNull(),
  expiryDate: text('expiry_date').notNull(), // ISO date (YYYY-MM-DD)
  photoUri: text('photo_uri'),
  quantity: real('quantity'),
  unit: text('unit'),
  location: text('location'),
  notes: text('notes'),
  reminderOffsets: text('reminder_offsets').notNull(), // JSON array e.g. "[7,3,1,0]"
  status: text('status').notNull().default('active'), // 'active' | 'used' | 'finished' | 'disposed'
  statusChangedAt: text('status_changed_at'),
  createdAt: text('created_at').notNull(),
  updatedAt: text('updated_at').notNull(),
});

export const notificationRecords = sqliteTable('notification_records', {
  id: text('id').primaryKey(), // Deterministic: `${itemId}:${offsetDays}`
  itemId: text('item_id').notNull().references(() => items.id, { onDelete: 'cascade' }),
  firesAt: text('fires_at').notNull(),
  notifeeTriggerId: text('notifee_trigger_id'),
});

export const appSettingsTable = sqliteTable('app_settings', {
  key: text('key').primaryKey(),
  value: text('value').notNull(),
});

export type ItemRow = typeof items.$inferSelect;
export type InsertItemRow = typeof items.$inferInsert;
export type NotificationRecordRow = typeof notificationRecords.$inferSelect;
