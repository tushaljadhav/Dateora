import { Platform } from 'react-native';
import { Item } from '../types/item';
import { AppSettings, DEFAULT_SETTINGS } from '../types/settings';
import { itemRepository } from './itemRepository';
import { getDatabase } from '../db/client';
import { appSettingsTable } from '../db/schema';
import { notificationService } from './notificationService';

export const CURRENT_SCHEMA_VERSION = 1;

export interface DateoraExportPayload {
  schemaVersion: number;
  appName: 'Dateora';
  exportedAt: string;
  items: Item[];
  settings: Partial<AppSettings>;
}

export interface ImportPreview {
  isValid: boolean;
  error?: string;
  totalInFile: number;
  newItemsCount: number;
  conflictItemsCount: number;
  newItems: Item[];
  conflictItems: Item[];
  parsedData?: DateoraExportPayload;
}

/**
 * Builds the complete export JSON payload for Dateora.
 */
export async function buildExportPayload(): Promise<DateoraExportPayload> {
  const allItems = await itemRepository.getAllIncludingHistory();

  let settings: Partial<AppSettings> = {};
  const { db } = getDatabase();
  if (db) {
    try {
      const rows = await db.select().from(appSettingsTable);
      const map: Record<string, string> = {};
      rows.forEach((r) => {
        map[r.key] = r.value;
      });
      settings = {
        theme: map['theme'] as any,
        expiringSoonWindowDays: map['expiringSoonWindowDays'] ? parseInt(map['expiringSoonWindowDays'], 10) : undefined,
        defaultReminderOffsets: map['defaultReminderOffsets'] ? JSON.parse(map['defaultReminderOffsets']) : undefined,
        dailyNotificationTime: map['dailyNotificationTime'],
        notificationsEnabled: map['notificationsEnabled'] !== 'false',
      };
    } catch {
      // Fallback
    }
  } else if (typeof window !== 'undefined' && window.localStorage) {
    try {
      const raw = window.localStorage.getItem('dateora_settings_data');
      if (raw) settings = JSON.parse(raw);
    } catch {
      // Ignore
    }
  }

  return {
    schemaVersion: CURRENT_SCHEMA_VERSION,
    appName: 'Dateora',
    exportedAt: new Date().toISOString(),
    items: allItems,
    settings,
  };
}

/**
 * Exports data to a file. Downloads in web or shares on mobile.
 */
export async function exportDataToFile(): Promise<{ success: boolean; filename: string }> {
  const payload = await buildExportPayload();
  const jsonStr = JSON.stringify(payload, null, 2);
  const dateStr = new Date().toISOString().split('T')[0];
  const filename = `dateora-backup-${dateStr}.json`;

  if (Platform.OS === 'web') {
    if (typeof window !== 'undefined' && typeof document !== 'undefined') {
      const blob = new Blob([jsonStr], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = filename;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      URL.revokeObjectURL(url);
      return { success: true, filename };
    }
  } else {
    try {
      const FileSystem = require('expo-file-system');
      const Sharing = require('expo-sharing');
      const fileUri = `${FileSystem.documentDirectory}${filename}`;
      await FileSystem.writeAsStringAsync(fileUri, jsonStr, {
        encoding: FileSystem.EncodingType.UTF8,
      });

      if (await Sharing.isAvailableAsync()) {
        await Sharing.shareAsync(fileUri, {
          mimeType: 'application/json',
          dialogTitle: 'Export Dateora Backup',
          UTI: 'public.json',
        });
      }
      return { success: true, filename };
    } catch (err) {
      console.error('Failed to export native file:', err);
      throw err;
    }
  }

  return { success: true, filename };
}

/**
 * Inspects a raw JSON string for validity and schema compliance before committing.
 */
export async function inspectImportJson(rawJson: string): Promise<ImportPreview> {
  let parsed: any;
  try {
    parsed = JSON.parse(rawJson);
  } catch {
    return {
      isValid: false,
      error: 'Invalid JSON file format. Could not parse data.',
      totalInFile: 0,
      newItemsCount: 0,
      conflictItemsCount: 0,
      newItems: [],
      conflictItems: [],
    };
  }

  if (!parsed || typeof parsed !== 'object') {
    return {
      isValid: false,
      error: 'The uploaded file does not contain a valid JSON object.',
      totalInFile: 0,
      newItemsCount: 0,
      conflictItemsCount: 0,
      newItems: [],
      conflictItems: [],
    };
  }

  if (parsed.schemaVersion !== CURRENT_SCHEMA_VERSION && parsed.appName !== 'Dateora') {
    return {
      isValid: false,
      error: `Unsupported backup version or format (schemaVersion: ${parsed.schemaVersion ?? 'unknown'}). Expected schemaVersion: ${CURRENT_SCHEMA_VERSION}.`,
      totalInFile: 0,
      newItemsCount: 0,
      conflictItemsCount: 0,
      newItems: [],
      conflictItems: [],
    };
  }

  if (!Array.isArray(parsed.items)) {
    return {
      isValid: false,
      error: 'The backup file is missing an items array.',
      totalInFile: 0,
      newItemsCount: 0,
      conflictItemsCount: 0,
      newItems: [],
      conflictItems: [],
    };
  }

  // Validate each item shape
  const validItems: Item[] = [];
  for (const item of parsed.items) {
    if (item && item.id && item.name && item.expiryDate) {
      validItems.push({
        id: String(item.id),
        name: String(item.name).trim(),
        category: String(item.category || 'other'),
        expiryDate: String(item.expiryDate),
        quantity: item.quantity !== undefined && item.quantity !== null ? Number(item.quantity) : null,
        unit: item.unit ? String(item.unit) : null,
        location: item.location ? String(item.location) : null,
        notes: item.notes ? String(item.notes) : null,
        reminderOffsets: Array.isArray(item.reminderOffsets) ? item.reminderOffsets : [3, 1, 0],
        status: ['active', 'used', 'finished', 'disposed'].includes(item.status) ? item.status : 'active',
        createdAt: item.createdAt || new Date().toISOString(),
        updatedAt: item.updatedAt || new Date().toISOString(),
        statusChangedAt: item.statusChangedAt || null,
      });
    }
  }

  // Compare against existing items in the repository
  const existingItems = await itemRepository.getAllIncludingHistory();
  const existingIdMap = new Set(existingItems.map((i) => i.id));

  const newItems: Item[] = [];
  const conflictItems: Item[] = [];

  for (const item of validItems) {
    if (existingIdMap.has(item.id)) {
      conflictItems.push(item);
    } else {
      newItems.push(item);
    }
  }

  return {
    isValid: true,
    totalInFile: validItems.length,
    newItemsCount: newItems.length,
    conflictItemsCount: conflictItems.length,
    newItems,
    conflictItems,
    parsedData: {
      ...parsed,
      items: validItems,
    },
  };
}

/**
 * Commits the imported items into the database or storage.
 * @param preview The inspected import preview
 * @param overwriteConflicts If true, overwrites existing items with the imported versions
 */
export async function commitImport(
  preview: ImportPreview,
  overwriteConflicts = false
): Promise<{ added: number; updated: number; skipped: number }> {
  if (!preview.isValid || !preview.parsedData) {
    throw new Error('Cannot commit invalid import');
  }

  let added = 0;
  let updated = 0;
  let skipped = 0;

  // 1. Add all new items
  for (const item of preview.newItems) {
    await itemRepository.insertRawItem(item);
    added++;
  }

  // 2. Handle conflicts
  for (const item of preview.conflictItems) {
    if (overwriteConflicts) {
      await itemRepository.insertRawItem(item);
      updated++;
    } else {
      skipped++;
    }
  }

  // 3. Reschedule active notifications
  await notificationService.rescheduleAll();

  return { added, updated, skipped };
}
