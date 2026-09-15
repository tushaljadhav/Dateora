import { create } from 'zustand';
import { Item, NewItemInput, UpdateItemInput, ItemLifecycleStatus } from '../types/item';
import { itemRepository } from '../services/itemRepository';

interface ItemsState {
  items: Item[];
  historyItems: Item[];
  isLoading: boolean;
  error: string | null;

  loadItems: () => Promise<void>;
  loadHistory: () => Promise<void>;
  addItem: (input: NewItemInput, dailyNotificationTime?: string) => Promise<Item>;
  updateItem: (input: UpdateItemInput, dailyNotificationTime?: string) => Promise<Item>;
  markItemStatus: (id: string, status: ItemLifecycleStatus, dailyNotificationTime?: string) => Promise<Item>;
  deleteItem: (id: string) => Promise<void>;
  restoreItem: (id: string, dailyNotificationTime?: string) => Promise<Item>;
}

export const useItemsStore = create<ItemsState>((set, get) => ({
  items: [],
  historyItems: [],
  isLoading: false,
  error: null,

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
      return restored;
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Failed to restore item';
      set({ error: message });
      throw err;
    }
  },
}));
