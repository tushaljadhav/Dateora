import {
  Apple,
  Milk,
  Pill,
  Sparkles,
  Home,
  Coffee,
  Package,
  FileText,
  Tag,
  LucideIcon,
} from 'lucide-react-native';

export interface CategoryVisual {
  id: string;
  name: string;
  emoji: string;
  icon: LucideIcon;
  color: string;
  bgColorLight: string;
  bgColorDark: string;
  borderColorLight: string;
  borderColorDark: string;
}

export const CATEGORY_VISUALS: Record<string, CategoryVisual> = {
  groceries: {
    id: 'groceries',
    name: 'Groceries',
    emoji: '🥦',
    icon: Apple,
    color: '#16A34A',
    bgColorLight: '#DCFCE7',
    bgColorDark: 'rgba(34, 197, 94, 0.18)',
    borderColorLight: '#BBF7D0',
    borderColorDark: 'rgba(34, 197, 94, 0.35)',
  },
  food: {
    id: 'food',
    name: 'Groceries',
    emoji: '🍎',
    icon: Apple,
    color: '#16A34A',
    bgColorLight: '#DCFCE7',
    bgColorDark: 'rgba(34, 197, 94, 0.18)',
    borderColorLight: '#BBF7D0',
    borderColorDark: 'rgba(34, 197, 94, 0.35)',
  },
  dairy: {
    id: 'dairy',
    name: 'Dairy & Eggs',
    emoji: '🥛',
    icon: Milk,
    color: '#0284C7',
    bgColorLight: '#E0F2FE',
    bgColorDark: 'rgba(2, 132, 199, 0.18)',
    borderColorLight: '#BAE6FD',
    borderColorDark: 'rgba(2, 132, 199, 0.35)',
  },
  medicine: {
    id: 'medicine',
    name: 'Medicine',
    emoji: '💊',
    icon: Pill,
    color: '#EF4444',
    bgColorLight: '#FEE2E2',
    bgColorDark: 'rgba(239, 68, 68, 0.18)',
    borderColorLight: '#FECACA',
    borderColorDark: 'rgba(239, 68, 68, 0.35)',
  },
  skincare: {
    id: 'skincare',
    name: 'Skincare',
    emoji: '✨',
    icon: Sparkles,
    color: '#EC4899',
    bgColorLight: '#FCE7F3',
    bgColorDark: 'rgba(236, 72, 153, 0.18)',
    borderColorLight: '#FBCFE8',
    borderColorDark: 'rgba(236, 72, 153, 0.35)',
  },
  cosmetics: {
    id: 'cosmetics',
    name: 'Cosmetics',
    emoji: '💄',
    icon: Sparkles,
    color: '#EC4899',
    bgColorLight: '#FCE7F3',
    bgColorDark: 'rgba(236, 72, 153, 0.18)',
    borderColorLight: '#FBCFE8',
    borderColorDark: 'rgba(236, 72, 153, 0.35)',
  },
  beverages: {
    id: 'beverages',
    name: 'Beverages',
    emoji: '☕',
    icon: Coffee,
    color: '#D97706',
    bgColorLight: '#FEF3C7',
    bgColorDark: 'rgba(217, 119, 6, 0.18)',
    borderColorLight: '#FDE68A',
    borderColorDark: 'rgba(217, 119, 6, 0.35)',
  },
  household: {
    id: 'household',
    name: 'Household',
    emoji: '🏠',
    icon: Home,
    color: '#8B5CF6',
    bgColorLight: '#EDE9FE',
    bgColorDark: 'rgba(139, 92, 246, 0.18)',
    borderColorLight: '#DDD6FE',
    borderColorDark: 'rgba(139, 92, 246, 0.35)',
  },
  documents: {
    id: 'documents',
    name: 'Documents',
    emoji: '📄',
    icon: FileText,
    color: '#3B82F6',
    bgColorLight: '#DBEAFE',
    bgColorDark: 'rgba(59, 130, 246, 0.18)',
    borderColorLight: '#BFDBFE',
    borderColorDark: 'rgba(59, 130, 246, 0.35)',
  },
  pantry: {
    id: 'pantry',
    name: 'Pantry',
    emoji: '📦',
    icon: Package,
    color: '#64748B',
    bgColorLight: '#F1F5F9',
    bgColorDark: 'rgba(100, 116, 139, 0.18)',
    borderColorLight: '#E2E8F0',
    borderColorDark: 'rgba(100, 116, 139, 0.35)',
  },
};

export const DEFAULT_CATEGORY_VISUAL: CategoryVisual = {
  id: 'custom',
  name: 'Other',
  emoji: '🏷️',
  icon: Tag,
  color: '#16A34A',
  bgColorLight: '#DCFCE7',
  bgColorDark: 'rgba(34, 197, 94, 0.18)',
  borderColorLight: '#BBF7D0',
  borderColorDark: 'rgba(34, 197, 94, 0.35)',
};

export function getCategoryVisual(category: string): CategoryVisual {
  if (!category) return DEFAULT_CATEGORY_VISUAL;
  const key = category.toLowerCase().trim();
  return CATEGORY_VISUALS[key] || DEFAULT_CATEGORY_VISUAL;
}

export const POPULAR_CATEGORIES = [
  CATEGORY_VISUALS.groceries,
  CATEGORY_VISUALS.dairy,
  CATEGORY_VISUALS.medicine,
  CATEGORY_VISUALS.skincare,
  CATEGORY_VISUALS.beverages,
  CATEGORY_VISUALS.household,
  CATEGORY_VISUALS.pantry,
];
