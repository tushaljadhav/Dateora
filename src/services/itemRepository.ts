import { eq, desc } from 'drizzle-orm';
import { getDatabase } from '../db/client';
import { items, notificationRecords, ItemRow } from '../db/schema';
import { Item, NewItemInput, UpdateItemInput, ItemLifecycleStatus } from '../types/item';
import { notificationService } from './notificationService';
import { generateUUID } from '../utils/uuid';

const WEB_STORAGE_KEY = 'dateora_items_data';

function getWebItems(): Item[] {
  if (typeof window !== 'undefined' && window.localStorage) {
    const raw = window.localStorage.getItem(WEB_STORAGE_KEY);
    if (raw) {
      try {
        return JSON.parse(raw);
      } catch {
        return [];
      }
    }
  }
  return [];
}

function saveWebItems(list: Item[]): void {
  if (typeof window !== 'undefined' && window.localStorage) {
    window.localStorage.setItem(WEB_STORAGE_KEY, JSON.stringify(list));
  }
}

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
    if (!db) {
      const webList = getWebItems();
      return webList.sort((a, b) => b.createdAt.localeCompare(a.createdAt));
    }
    const rows = await db.select().from(items).orderBy(desc(items.createdAt));
    return rows.map(mapRowToItem);
  }

  public async getAllIncludingHistory(): Promise<Item[]> {
    return this.getAllItems();
  }

  public async insertRawItem(item: Item, dailyNotificationTime: string = '09:00'): Promise<void> {
    const { db } = getDatabase();
    if (!db) {
      const list = getWebItems();
      const existingIdx = list.findIndex((i) => i.id === item.id);
      if (existingIdx >= 0) {
        list[existingIdx] = item;
      } else {
        list.push(item);
      }
      saveWebItems(list);
      if (item.status === 'active') {
        await notificationService.scheduleItemReminders(item, dailyNotificationTime);
      }
      return;
    }

    await db
      .insert(items)
      .values({
        id: item.id,
        name: item.name,
        category: item.category,
        expiryDate: item.expiryDate,
        photoUri: item.photoUri,
        quantity: item.quantity,
        unit: item.unit,
        location: item.location,
        notes: item.notes,
        reminderOffsets: JSON.stringify(item.reminderOffsets),
        status: item.status,
        statusChangedAt: item.statusChangedAt,
        createdAt: item.createdAt,
        updatedAt: item.updatedAt,
      })
      .onConflictDoUpdate({
        target: items.id,
        set: {
          name: item.name,
          category: item.category,
          expiryDate: item.expiryDate,
          photoUri: item.photoUri,
          quantity: item.quantity,
          unit: item.unit,
          location: item.location,
          notes: item.notes,
          reminderOffsets: JSON.stringify(item.reminderOffsets),
          status: item.status,
          statusChangedAt: item.statusChangedAt,
          updatedAt: item.updatedAt,
        },
      });

    if (item.status === 'active') {
      await notificationService.scheduleItemReminders(item, dailyNotificationTime);
    }
  }

  public async getActiveItems(): Promise<Item[]> {
    const { db } = getDatabase();
    if (!db) {
      const webList = getWebItems();
      return webList
        .filter((i) => i.status === 'active')
        .sort((a, b) => a.expiryDate.localeCompare(b.expiryDate));
    }
    const rows = await db.select().from(items).where(eq(items.status, 'active')).orderBy(items.expiryDate);
    return rows.map(mapRowToItem);
  }

  public async getHistoryItems(): Promise<Item[]> {
    const { db } = getDatabase();
    if (!db) {
      const webList = getWebItems();
      return webList
        .filter((i) => i.status !== 'active')
        .sort((a, b) => (b.statusChangedAt || '').localeCompare(a.statusChangedAt || ''));
    }
    const allRows = await db.select().from(items).orderBy(desc(items.statusChangedAt));
    return allRows.filter((r) => r.status !== 'active').map(mapRowToItem);
  }

  public async getItemById(id: string): Promise<Item | null> {
    const { db } = getDatabase();
    if (!db) {
      const webList = getWebItems();
      return webList.find((i) => i.id === id) || null;
    }
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

    if (!db) {
      const current = getWebItems();
      saveWebItems([...current, newItem]);
      await notificationService.scheduleItemReminders(newItem, dailyNotificationTime);
      return newItem;
    }

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

    if (!db) {
      const list = getWebItems().map((item) => (item.id === updated.id ? updated : item));
      saveWebItems(list);
      if (updated.status === 'active') {
        await notificationService.scheduleItemReminders(updated, dailyNotificationTime);
      } else {
        await notificationService.cancelItemReminders(updated.id);
      }
      return updated;
    }

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

    const updatedItem: Item = {
      ...existing,
      status: newStatus,
      statusChangedAt,
      updatedAt: nowIso,
    };

    if (!db) {
      const list = getWebItems().map((item) => (item.id === id ? updatedItem : item));
      saveWebItems(list);
      if (newStatus === 'active') {
        await notificationService.scheduleItemReminders(updatedItem, dailyNotificationTime);
      } else {
        await notificationService.cancelItemReminders(id);
      }
      return updatedItem;
    }

    await db
      .update(items)
      .set({
        status: newStatus,
        statusChangedAt,
        updatedAt: nowIso,
      })
      .where(eq(items.id, id));

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

    if (!db) {
      const list = getWebItems().filter((item) => item.id !== id);
      saveWebItems(list);
      return;
    }

    await db.delete(notificationRecords).where(eq(notificationRecords.itemId, id));
    await db.delete(items).where(eq(items.id, id));
  }
}

export const itemRepository = new ItemRepository();
