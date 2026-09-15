import { eq, desc } from 'drizzle-orm';
import { getDatabase } from '../db/client';
import { items, notificationRecords, ItemRow } from '../db/schema';
import { Item, NewItemInput, UpdateItemInput, ItemLifecycleStatus } from '../types/item';
import { notificationService } from './notificationService';
import { generateUUID } from '../utils/uuid';

function mapRowToItem(row: ItemRow): Item {
  let reminderOffsets: number[] = [3];
  try {
    reminderOffsets = JSON.parse(row.reminderOffsets);
  } catch {
    reminderOffsets = [3];
  }

  return {
    id: row.id,
    name: row.name,
    category: row.category,
    expiryDate: row.expiryDate,
    photoUri: row.photoUri,
    quantity: row.quantity,
    unit: row.unit,
    location: row.location,
    notes: row.notes,
    reminderOffsets,
    status: row.status as ItemLifecycleStatus,
    statusChangedAt: row.statusChangedAt,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  };
}

export class ItemRepository {
  public async getAllItems(): Promise<Item[]> {
    const { db } = getDatabase();
    const rows = await db.select().from(items).orderBy(desc(items.createdAt));
    return rows.map(mapRowToItem);
  }

  public async getActiveItems(): Promise<Item[]> {
    const { db } = getDatabase();
    const rows = await db.select().from(items).where(eq(items.status, 'active')).orderBy(items.expiryDate);
    return rows.map(mapRowToItem);
  }

  public async getHistoryItems(): Promise<Item[]> {
    const { db } = getDatabase();
    const rows = await db
      .select()
      .from(items)
      .where(eq(items.status, 'used'))
      .orderBy(desc(items.statusChangedAt));
    // Also include finished and disposed in history
    const allRows = await db.select().from(items).orderBy(desc(items.statusChangedAt));
    return allRows.filter((r) => r.status !== 'active').map(mapRowToItem);
  }

  public async getItemById(id: string): Promise<Item | null> {
    const { db } = getDatabase();
    const rows = await db.select().from(items).where(eq(items.id, id)).limit(1);
    if (!rows.length) return null;
    return mapRowToItem(rows[0]);
  }

  public async createItem(input: NewItemInput, dailyNotificationTime: string = '09:00'): Promise<Item> {
    const { db } = getDatabase();
    const nowIso = new Date().toISOString();
    const id = generateUUID();

    const newItem: Item = {
      id,
      name: input.name.trim(),
      category: input.category,
      expiryDate: input.expiryDate,
      photoUri: input.photoUri ?? null,
      quantity: input.quantity ?? null,
      unit: input.unit ?? null,
      location: input.location?.trim() ?? null,
      notes: input.notes?.trim() ?? null,
      reminderOffsets: input.reminderOffsets || [3],
      status: input.status || 'active',
      statusChangedAt: null,
      createdAt: nowIso,
      updatedAt: nowIso,
    };

    await db.insert(items).values({
      id: newItem.id,
      name: newItem.name,
      category: newItem.category,
      expiryDate: newItem.expiryDate,
      photoUri: newItem.photoUri,
      quantity: newItem.quantity,
      unit: newItem.unit,
      location: newItem.location,
      notes: newItem.notes,
      reminderOffsets: JSON.stringify(newItem.reminderOffsets),
      status: newItem.status,
      statusChangedAt: newItem.statusChangedAt,
      createdAt: newItem.createdAt,
      updatedAt: newItem.updatedAt,
    });

    // Handle deterministic notification scheduling
    if (newItem.status === 'active') {
      const records = await notificationService.scheduleItemReminders(newItem, dailyNotificationTime);
      for (const record of records) {
        await db.insert(notificationRecords).values({
          id: record.id,
          itemId: record.itemId,
          firesAt: record.firesAt,
          notifeeTriggerId: record.notifeeTriggerId,
        });
      }
    }

    return newItem;
  }

  public async updateItem(input: UpdateItemInput, dailyNotificationTime: string = '09:00'): Promise<Item> {
    const { db } = getDatabase();
    const existing = await this.getItemById(input.id);
    if (!existing) {
      throw new Error(`Item with id ${input.id} not found`);
    }

    const nowIso = new Date().toISOString();
    const updated: Item = {
      ...existing,
      ...input,
      name: input.name !== undefined ? input.name.trim() : existing.name,
      location: input.location !== undefined ? (input.location ? input.location.trim() : null) : existing.location,
      notes: input.notes !== undefined ? (input.notes ? input.notes.trim() : null) : existing.notes,
      reminderOffsets: input.reminderOffsets || existing.reminderOffsets,
      updatedAt: nowIso,
    };

    await db
      .update(items)
      .set({
        name: updated.name,
        category: updated.category,
        expiryDate: updated.expiryDate,
        photoUri: updated.photoUri,
        quantity: updated.quantity,
        unit: updated.unit,
        location: updated.location,
        notes: updated.notes,
        reminderOffsets: JSON.stringify(updated.reminderOffsets),
        status: updated.status,
        statusChangedAt: updated.statusChangedAt,
        updatedAt: updated.updatedAt,
      })
      .where(eq(items.id, updated.id));

    // Cancel existing notification records and reschedule
    await db.delete(notificationRecords).where(eq(notificationRecords.itemId, updated.id));
    if (updated.status === 'active') {
      const records = await notificationService.scheduleItemReminders(updated, dailyNotificationTime);
      for (const record of records) {
        await db.insert(notificationRecords).values({
          id: record.id,
          itemId: record.itemId,
          firesAt: record.firesAt,
          notifeeTriggerId: record.notifeeTriggerId,
        });
      }
    } else {
      await notificationService.cancelItemReminders(updated.id);
    }

    return updated;
  }

  public async updateItemStatus(
    id: string,
    newStatus: ItemLifecycleStatus,
    dailyNotificationTime: string = '09:00'
  ): Promise<Item> {
    const { db } = getDatabase();
    const existing = await this.getItemById(id);
    if (!existing) {
      throw new Error(`Item with id ${id} not found`);
    }

    const nowIso = new Date().toISOString();
    const statusChangedAt = newStatus === 'active' ? null : nowIso;

    await db
      .update(items)
      .set({
        status: newStatus,
        statusChangedAt,
        updatedAt: nowIso,
      })
      .where(eq(items.id, id));

    const updatedItem: Item = {
      ...existing,
      status: newStatus,
      statusChangedAt,
      updatedAt: nowIso,
    };

    // Manage notifications based on status change
    await db.delete(notificationRecords).where(eq(notificationRecords.itemId, id));
    if (newStatus === 'active') {
      const records = await notificationService.scheduleItemReminders(updatedItem, dailyNotificationTime);
      for (const record of records) {
        await db.insert(notificationRecords).values({
          id: record.id,
          itemId: record.itemId,
          firesAt: record.firesAt,
          notifeeTriggerId: record.notifeeTriggerId,
        });
      }
    } else {
      await notificationService.cancelItemReminders(id);
    }

    return updatedItem;
  }

  public async deleteItem(id: string): Promise<void> {
    const { db } = getDatabase();
    await notificationService.cancelItemReminders(id);
    await db.delete(notificationRecords).where(eq(notificationRecords.itemId, id));
    await db.delete(items).where(eq(items.id, id));
  }
}

export const itemRepository = new ItemRepository();
