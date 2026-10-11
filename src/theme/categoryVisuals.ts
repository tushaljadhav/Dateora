import React from 'react';
import {
  ForkKnife,
  Pill,
  Sparkle,
  House,
  FileText,
  Tag,
  IconProps,
} from 'phosphor-react-native';
import { brandPalette } from './colors';

export interface CategoryVisual {
  id: string;
  name: string;
  emoji: string;
  icon: React.ComponentType<IconProps>;
  color: string;
  bgColor: string;
  borderColor: string;
  bgColorLight: string;
  bgColorDark: string;
  borderColorLight: string;
  borderColorDark: string;
}

// 10% Blue and Purple tinted fills per locked specification
const TINT_BLUE_BG = brandPalette.blue10;
const TINT_PURPLE_BG = brandPalette.purple10;
const ICON_BLUE = brandPalette.primaryBlue;
const ICON_PURPLE = brandPalette.primaryPurple;
const BORDER_BLUE = 'rgba(59, 107, 255, 0.18)';
const BORDER_PURPLE = 'rgba(124, 92, 255, 0.18)';

export const CATEGORY_VISUALS: Record<string, CategoryVisual> = {
  groceries: {
    id: 'groceries',
    name: 'Food & Groceries',
    emoji: '🥦',
    icon: ForkKnife,
    color: ICON_BLUE,
    bgColor: TINT_BLUE_BG,
    borderColor: BORDER_BLUE,
    bgColorLight: TINT_BLUE_BG,
    bgColorDark: TINT_BLUE_BG,
    borderColorLight: BORDER_BLUE,
    borderColorDark: BORDER_BLUE,
  },
  food: {
    id: 'food',
    name: 'Food & Groceries',
    emoji: '🍎',
    icon: ForkKnife,
    color: ICON_BLUE,
    bgColor: TINT_BLUE_BG,
    borderColor: BORDER_BLUE,
    bgColorLight: TINT_BLUE_BG,
    bgColorDark: TINT_BLUE_BG,
    borderColorLight: BORDER_BLUE,
    borderColorDark: BORDER_BLUE,
  },
  dairy: {
    id: 'dairy',
    name: 'Food & Groceries',
    emoji: '🥛',
    icon: ForkKnife,
    color: ICON_BLUE,
    bgColor: TINT_BLUE_BG,
    borderColor: BORDER_BLUE,
    bgColorLight: TINT_BLUE_BG,
    bgColorDark: TINT_BLUE_BG,
    borderColorLight: BORDER_BLUE,
    borderColorDark: BORDER_BLUE,
  },
  medicine: {
    id: 'medicine',
    name: 'Medicines',
    emoji: '💊',
    icon: Pill,
    color: ICON_PURPLE,
    bgColor: TINT_PURPLE_BG,
    borderColor: BORDER_PURPLE,
    bgColorLight: TINT_PURPLE_BG,
    bgColorDark: TINT_PURPLE_BG,
    borderColorLight: BORDER_PURPLE,
    borderColorDark: BORDER_PURPLE,
  },
  skincare: {
    id: 'skincare',
    name: 'Cosmetics & Skincare',
    emoji: '✨',
    icon: Sparkle,
    color: ICON_PURPLE,
    bgColor: TINT_PURPLE_BG,
    borderColor: BORDER_PURPLE,
    bgColorLight: TINT_PURPLE_BG,
    bgColorDark: TINT_PURPLE_BG,
    borderColorLight: BORDER_PURPLE,
    borderColorDark: BORDER_PURPLE,
  },
  cosmetics: {
    id: 'cosmetics',
    name: 'Cosmetics & Skincare',
    emoji: '💄',
    icon: Sparkle,
    color: ICON_PURPLE,
    bgColor: TINT_PURPLE_BG,
    borderColor: BORDER_PURPLE,
    bgColorLight: TINT_PURPLE_BG,
    bgColorDark: TINT_PURPLE_BG,
    borderColorLight: BORDER_PURPLE,
    borderColorDark: BORDER_PURPLE,
  },
  household: {
    id: 'household',
    name: 'Household',
    emoji: '🏠',
    icon: House,
    color: ICON_BLUE,
    bgColor: TINT_BLUE_BG,
    borderColor: BORDER_BLUE,
    bgColorLight: TINT_BLUE_BG,
    bgColorDark: TINT_BLUE_BG,
    borderColorLight: BORDER_BLUE,
    borderColorDark: BORDER_BLUE,
  },
  beverages: {
    id: 'beverages',
    name: 'Food & Groceries',
    emoji: '☕',
    icon: ForkKnife,
    color: ICON_BLUE,
    bgColor: TINT_BLUE_BG,
    borderColor: BORDER_BLUE,
    bgColorLight: TINT_BLUE_BG,
    bgColorDark: TINT_BLUE_BG,
    borderColorLight: BORDER_BLUE,
    borderColorDark: BORDER_BLUE,
  },
  documents: {
    id: 'documents',
    name: 'Documents',
    emoji: '📄',
    icon: FileText,
    color: ICON_BLUE,
    bgColor: TINT_BLUE_BG,
    borderColor: BORDER_BLUE,
    bgColorLight: TINT_BLUE_BG,
    bgColorDark: TINT_BLUE_BG,
    borderColorLight: BORDER_BLUE,
    borderColorDark: BORDER_BLUE,
  },
  pantry: {
    id: 'pantry',
    name: 'Food & Groceries',
    emoji: '📦',
    icon: ForkKnife,
    color: ICON_BLUE,
    bgColor: TINT_BLUE_BG,
    borderColor: BORDER_BLUE,
    bgColorLight: TINT_BLUE_BG,
    bgColorDark: TINT_BLUE_BG,
    borderColorLight: BORDER_BLUE,
    borderColorDark: BORDER_BLUE,
  },
  custom: {
    id: 'custom',
    name: 'Custom',
    emoji: '🏷️',
    icon: Tag,
    color: ICON_PURPLE,
    bgColor: TINT_PURPLE_BG,
    borderColor: BORDER_PURPLE,
    bgColorLight: TINT_PURPLE_BG,
    bgColorDark: TINT_PURPLE_BG,
    borderColorLight: BORDER_PURPLE,
    borderColorDark: BORDER_PURPLE,
  },
};

export const DEFAULT_CATEGORY_VISUAL: CategoryVisual = CATEGORY_VISUALS.custom;

export function getCategoryVisual(category: string): CategoryVisual {
  if (!category) return DEFAULT_CATEGORY_VISUAL;
  const key = category.toLowerCase().trim();
  return CATEGORY_VISUALS[key] || DEFAULT_CATEGORY_VISUAL;
}

export const POPULAR_CATEGORIES = [
  CATEGORY_VISUALS.groceries,
  CATEGORY_VISUALS.medicine,
  CATEGORY_VISUALS.skincare,
  CATEGORY_VISUALS.household,
  CATEGORY_VISUALS.documents,
  CATEGORY_VISUALS.custom,
];
