import { create } from 'zustand';
import { Item, NewItemInput, UpdateItemInput, ItemLifecycleStatus } from '../types/item';
import { itemRepository } from '../services/itemRepository';
import { syncService } from '../services/syncService';

// Fire-and-forget background sync after mutations
function backgroundSync() {
  syncService.pushToRemote().catch((err) =>
    console.warn('Background sync failed:', err)
  );
}

interface ItemsState {
  items: Item[];
  historyItems: Item[];
  isLoading: boolean;
  error: string | null;
  isSyncing: boolean;
  lastSyncAt: string | null;
  syncError: string | null;

  loadItems: () => Promise<void>;
  loadHistory: () => Promise<void>;
  addItem: (input: NewItemInput, dailyNotificationTime?: string) => Promise<Item>;
  updateItem: (input: UpdateItemInput, dailyNotificationTime?: string) => Promise<Item>;
  markItemStatus: (id: string, status: ItemLifecycleStatus, dailyNotificationTime?: string) => Promise<Item>;
  deleteItem: (id: string) => Promise<void>;
  restoreItem: (id: string, dailyNotificationTime?: string) => Promise<Item>;
  syncToCloud: () => Promise<void>;
  syncFromCloud: () => Promise<void>;
}

export const useItemsStore = create<ItemsState>((set, get) => ({
  items: [],
  historyItems: [],
  isLoading: false,
  error: null,
  isSyncing: false,
  lastSyncAt: null,
  syncError: null,

  loadItems: async () => {
    set({ isLoading: true, error: null });
    try {
      const activeItems = await itemRepository.getActiveItems();
      set({ items: activeItems, isLoading: false });
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Failed to load items';
      set({ error: message, isLoading: false });
    }
  },

  loadHistory: async () => {
    try {
      const history = await itemRepository.getHistoryItems();
      set({ historyItems: history });
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Failed to load history';
      set({ error: message });
    }
  },

  addItem: async (input: NewItemInput, dailyNotificationTime?: string) => {
    set({ isLoading: true, error: null });
    try {
      const newItem = await itemRepository.createItem(input, dailyNotificationTime);
      set((state) => ({
        items: [...state.items, newItem].sort((a, b) => a.expiryDate.localeCompare(b.expiryDate)),
        isLoading: false,
      }));
      backgroundSync();
      return newItem;
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Failed to add item';
      set({ error: message, isLoading: false });
      throw err;
    }
  },

  updateItem: async (input: UpdateItemInput, dailyNotificationTime?: string) => {
    set({ isLoading: true, error: null });
    try {
      const updated = await itemRepository.updateItem(input, dailyNotificationTime);
      set((state) => ({
        items: state.items
          .map((item) => (item.id === updated.id ? updated : item))
          .sort((a, b) => a.expiryDate.localeCompare(b.expiryDate)),
        isLoading: false,
      }));
      backgroundSync();
      return updated;
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Failed to update item';
      set({ error: message, isLoading: false });
      throw err;
    }
  },

  markItemStatus: async (id: string, status: ItemLifecycleStatus, dailyNotificationTime?: string) => {
    try {
      const updated = await itemRepository.updateItemStatus(id, status, dailyNotificationTime);
      set((state) => ({
        items: state.items.filter((item) => item.id !== id),
        historyItems: [updated, ...state.historyItems],
      }));
      backgroundSync();
      return updated;
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Failed to update status';
      set({ error: message });
      throw err;
    }
  },

  deleteItem: async (id: string) => {
    try {
      await itemRepository.deleteItem(id);
      set((state) => ({
        items: state.items.filter((item) => item.id !== id),
        historyItems: state.historyItems.filter((item) => item.id !== id),
      }));
      syncService.deleteFromRemote(id).catch(() => {});
      backgroundSync();
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Failed to delete item';
      set({ error: message });
      throw err;
    }
  },

  restoreItem: async (id: string, dailyNotificationTime?: string) => {
    try {
      const restored = await itemRepository.updateItemStatus(id, 'active', dailyNotificationTime);
      set((state) => ({
        items: [...state.items, restored].sort((a, b) => a.expiryDate.localeCompare(b.expiryDate)),
        historyItems: state.historyItems.filter((item) => item.id !== id),
      }));
      backgroundSync();
      return restored;
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Failed to restore item';
      set({ error: message });
      throw err;
    }
  },

  syncToCloud: async () => {
    set({ isSyncing: true, syncError: null });
    try {
      const result = await syncService.pushToRemote();
      if (result.success) {
        set({ isSyncing: false, lastSyncAt: new Date().toISOString() });
      } else {
        set({ isSyncing: false, syncError: result.error || 'Sync failed' });
      }
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Sync failed';
      set({ isSyncing: false, syncError: message });
    }
  },

  syncFromCloud: async () => {
    set({ isSyncing: true, syncError: null });
    try {
      const result = await syncService.pullFromRemote();
      if (result.success) {
        // Reload local items after pull
        const activeItems = await itemRepository.getActiveItems();
        const historyItems = await itemRepository.getHistoryItems();
        set({
          items: activeItems,
          historyItems,
          isSyncing: false,
          lastSyncAt: new Date().toISOString(),
        });
      } else {
        set({ isSyncing: false, syncError: result.error || 'Sync failed' });
      }
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Sync failed';
      set({ isSyncing: false, syncError: message });
    }
  },
}));
