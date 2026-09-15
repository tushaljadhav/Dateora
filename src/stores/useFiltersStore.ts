import { create } from 'zustand';
import { ItemSortOption, ItemStatusFilter } from '../types/item';

interface FiltersState {
  searchQuery: string;
  statusFilter: ItemStatusFilter;
  selectedCategories: string[];
  sortOption: ItemSortOption;

  setSearchQuery: (query: string) => void;
  setStatusFilter: (filter: ItemStatusFilter) => void;
  toggleCategory: (category: string) => void;
  clearCategories: () => void;
  setSortOption: (sort: ItemSortOption) => void;
  resetFilters: () => void;
}

export const useFiltersStore = create<FiltersState>((set) => ({
  searchQuery: '',
  statusFilter: 'all',
  selectedCategories: [],
  sortOption: 'soonest',

  setSearchQuery: (query) => set({ searchQuery: query }),
  setStatusFilter: (filter) => set({ statusFilter: filter }),
  toggleCategory: (category) =>
    set((state) => {
      const exists = state.selectedCategories.includes(category);
      return {
        selectedCategories: exists
          ? state.selectedCategories.filter((c) => c !== category)
          : [...state.selectedCategories, category],
      };
    }),
  clearCategories: () => set({ selectedCategories: [] }),
  setSortOption: (sort) => set({ sortOption: sort }),
  resetFilters: () =>
    set({
      searchQuery: '',
      statusFilter: 'all',
      selectedCategories: [],
      sortOption: 'soonest',
    }),
}));
