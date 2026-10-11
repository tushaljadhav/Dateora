import { Platform } from 'react-native';
import { Item } from '../types/item';
import { itemRepository } from './itemRepository';
import { getDatabase } from '../db/client';
import { appSettingsTable } from '../db/schema';

/**
 * The base URL of the Dateora API server.
 * 
 * - In development on Android emulator, 10.0.2.2 maps to host's localhost.
 * - On iOS simulator, localhost works directly.
 * - On web, localhost works directly.
 * - For physical devices, replace with your machine's LAN IP.
 */
function getApiBaseUrl(): string {
  if (Platform.OS === 'android') {
    // Android emulator routes 10.0.2.2 to host machine's localhost
    return 'http://10.0.2.2:3001/api';
  }
  // iOS simulator / web / physical device on same network
  return 'http://localhost:3001/api';
}

const API_BASE = getApiBaseUrl();

export interface SyncResult {
  success: boolean;
  itemsSynced?: number;
  settingsSynced?: number;
  itemsPulled?: number;
  error?: string;
}

/**
 * Pushes all local data (items + settings) to the remote MySQL server.
 * The local SQLite/localStorage is the source of truth.
 */
export async function pushToRemote(): Promise<SyncResult> {
  try {
    // 1. Gather all local items
    const allItems = await itemRepository.getAllIncludingHistory();

    // 2. Gather all local settings
    const settings = await getLocalSettings();

    // 3. POST to the sync/push endpoint
    const response = await fetch(`${API_BASE}/sync/push`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ items: allItems, settings }),
    });

    if (!response.ok) {
      const errBody = await response.json().catch(() => ({}));
      throw new Error(errBody.error || `HTTP ${response.status}`);
    }

    const result = await response.json();
    return {
      success: true,
      itemsSynced: result.itemsSynced,
      settingsSynced: result.settingsSynced,
    };
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Push sync failed';
    console.warn('Sync push error:', message);
    return { success: false, error: message };
  }
}

/**
 * Pulls all data from the remote MySQL server and merges into local storage.
 * Remote items that don't exist locally are inserted; existing ones are
 * updated if the remote version is newer (based on updatedAt).
 */
export async function pullFromRemote(): Promise<SyncResult> {
  try {
    const response = await fetch(`${API_BASE}/sync/pull`);
    if (!response.ok) {
      const errBody = await response.json().catch(() => ({}));
      throw new Error(errBody.error || `HTTP ${response.status}`);
    }

    const result = await response.json();
    const remoteItems: Item[] = result.data?.items || [];
    const remoteSettings: Record<string, string> = result.data?.settings || {};

    // Merge items: upsert remote items into local DB
    let itemsMerged = 0;
    for (const remoteItem of remoteItems) {
      const localItem = await itemRepository.getItemById(remoteItem.id);

      if (!localItem) {
        // New item from remote — insert locally
        await itemRepository.insertRawItem(remoteItem);
        itemsMerged++;
      } else if (remoteItem.updatedAt > localItem.updatedAt) {
        // Remote is newer — update local
        await itemRepository.insertRawItem(remoteItem);
        itemsMerged++;
      }
      // If local is newer or same, keep local version (local is source of truth)
    }

    // Merge settings
    await mergeRemoteSettings(remoteSettings);

    return {
      success: true,
      itemsPulled: itemsMerged,
    };
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Pull sync failed';
    console.warn('Sync pull error:', message);
    return { success: false, error: message };
  }
}

/**
 * Full bidirectional sync: push first, then pull.
 */
export async function syncAll(): Promise<SyncResult> {
  const pushResult = await pushToRemote();
  if (!pushResult.success) {
    return pushResult;
  }

  const pullResult = await pullFromRemote();
  return {
    success: pullResult.success,
    itemsSynced: pushResult.itemsSynced,
    settingsSynced: pushResult.settingsSynced,
    itemsPulled: pullResult.itemsPulled,
    error: pullResult.error,
  };
}

/**
 * Notify the remote server that an item was deleted locally.
 */
export async function deleteFromRemote(itemId: string): Promise<void> {
  try {
    await fetch(`${API_BASE}/sync/item/${itemId}`, { method: 'DELETE' });
  } catch (err) {
    console.warn('Remote delete failed (will retry on next sync):', err);
  }
}

/**
 * Check if the remote server is reachable.
 */
export async function checkServerHealth(): Promise<boolean> {
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 5000);
    
    const response = await fetch(`${API_BASE}/health`, {
      signal: controller.signal,
    });
    clearTimeout(timeout);
    
    return response.ok;
  } catch {
    return false;
  }
}

// ─── Helpers ───

async function getLocalSettings(): Promise<Record<string, string>> {
  const { db } = getDatabase();
  const settings: Record<string, string> = {};

  if (!db) {
    // Web fallback — read from localStorage
    if (typeof window !== 'undefined' && window.localStorage) {
      try {
        const raw = window.localStorage.getItem('dateora_settings_data');
        if (raw) {
          const parsed = JSON.parse(raw);
          for (const [key, value] of Object.entries(parsed)) {
            settings[key] = typeof value === 'string' ? value : JSON.stringify(value);
          }
        }
      } catch {
        // Ignore
      }
    }
    return settings;
  }

  try {
    const rows = await db.select().from(appSettingsTable);
    rows.forEach((r) => {
      settings[r.key] = r.value;
    });
  } catch {
    // Ignore
  }

  return settings;
}

async function mergeRemoteSettings(remoteSettings: Record<string, string>): Promise<void> {
  const { db } = getDatabase();

  if (!db) {
    // Web fallback
    if (typeof window !== 'undefined' && window.localStorage) {
      try {
        const raw = window.localStorage.getItem('dateora_settings_data');
        const local = raw ? JSON.parse(raw) : {};
        // Only add settings that don't exist locally
        for (const [key, value] of Object.entries(remoteSettings)) {
          if (!(key in local)) {
            local[key] = value;
          }
        }
        window.localStorage.setItem('dateora_settings_data', JSON.stringify(local));
      } catch {
        // Ignore
      }
    }
    return;
  }

  try {
    for (const [key, value] of Object.entries(remoteSettings)) {
      // Only insert if key doesn't exist (local takes precedence)
      await db
        .insert(appSettingsTable)
        .values({ key, value })
        .onConflictDoNothing();
    }
  } catch {
    // Ignore merge errors
  }
}

export const syncService = {
  pushToRemote,
  pullFromRemote,
  syncAll,
  deleteFromRemote,
  checkServerHealth,
};
