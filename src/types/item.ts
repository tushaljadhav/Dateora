export type ItemLifecycleStatus = 'active' | 'used' | 'finished' | 'disposed';

export type ComputedItemStatus = 'expired' | 'expiring_soon' | 'safe';

export interface Item {
  id: string;
  name: string;
  category: string;
  expiryDate: string; // ISO date string (YYYY-MM-DD)
  photoUri?: string | null;
  quantity?: number | null;
  unit?: string | null;
  location?: string | null;
  notes?: string | null;
  reminderOffsets: number[]; // e.g. [7, 3, 1, 0]
  status: ItemLifecycleStatus;
  statusChangedAt?: string | null;
  createdAt: string;
  updatedAt: string;
}

export type NewItemInput = Omit<Item, 'id' | 'createdAt' | 'updatedAt' | 'status' | 'statusChangedAt'> & {
  status?: ItemLifecycleStatus;
};

export type UpdateItemInput = Partial<Omit<Item, 'id' | 'createdAt'>> & {
  id: string;
};

export interface NotificationRecord {
  id: string; // Deterministic: `${itemId}:${offsetDays}`
  itemId: string;
  firesAt: string; // ISO datetime
  notifeeTriggerId?: string | null;
}

export type ItemSortOption = 'soonest' | 'recently_added' | 'name_asc';
export type ItemStatusFilter = 'all' | 'expiring_soon' | 'expired' | 'safe';

export const PRESET_CATEGORIES = [
  { id: 'groceries', name: 'Groceries', icon: 'Apple' },
  { id: 'medicine', name: 'Medicine', icon: 'Pill' },
  { id: 'skincare', name: 'Skincare', icon: 'Sparkles' },
  { id: 'dairy', name: 'Dairy & Eggs', icon: 'Milk' },
  { id: 'household', name: 'Household', icon: 'Home' },
  { id: 'documents', name: 'Documents', icon: 'FileText' },
  { id: 'beverages', name: 'Beverages', icon: 'Coffee' },
  { id: 'pantry', name: 'Pantry', icon: 'Package' },
  { id: 'custom', name: 'Custom', icon: 'Tag' },
] as const;

export type PresetCategoryId = (typeof PRESET_CATEGORIES)[number]['id'];
