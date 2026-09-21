import React, { useEffect, useMemo } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  ScrollView,
  TextInput,
  TouchableOpacity,
  RefreshControl,
} from 'react-native';
import { useRouter } from 'expo-router';
import { useTheme } from '../../src/theme';
import { useItemsStore } from '../../src/stores/useItemsStore';
import { useFiltersStore } from '../../src/stores/useFiltersStore';
import { useSettingsStore } from '../../src/stores/useSettingsStore';
import { evaluateItemStatus, formatDisplayDate } from '../../src/services/statusCalculator';
import { Item, ItemSortOption, ItemStatusFilter } from '../../src/types/item';
import {
  Search,
  X,
  ChevronRight,
  Plus,
  ArrowUpDown,
  MapPin,
} from 'lucide-react-native';
import { StatusPill } from '../../src/components/StatusPill';
import { EmptyState } from '../../src/components/EmptyState';
import { CategoryBadge } from '../../src/components/CategoryBadge';

const CATEGORIES = [
  { id: 'all', label: 'All', emoji: '✨' },
  { id: 'groceries', label: 'Groceries', emoji: '🥦' },
  { id: 'dairy', label: 'Dairy', emoji: '🥛' },
  { id: 'medicine', label: 'Medicine', emoji: '💊' },
  { id: 'skincare', label: 'Skincare', emoji: '✨' },
  { id: 'beverages', label: 'Drinks', emoji: '☕' },
  { id: 'household', label: 'Household', emoji: '🏠' },
  { id: 'pantry', label: 'Pantry', emoji: '📦' },
];

export default function ItemsScreen() {
  const { theme } = useTheme();
  const router = useRouter();

  const items = useItemsStore((s) => s.items);
  const isLoading = useItemsStore((s) => s.isLoading);
  const loadItems = useItemsStore((s) => s.loadItems);

  const expiringSoonWindowDays = useSettingsStore((s) => s.expiringSoonWindowDays);

  const {
    searchQuery,
    setSearchQuery,
    statusFilter,
    setStatusFilter,
    selectedCategories,
    toggleCategory,
    sortOption,
    setSortOption,
  } = useFiltersStore();

  useEffect(() => {
    loadItems();
  }, [loadItems]);

  // Filtering & Sorting
  const filteredItems = useMemo(() => {
    let result = [...items];

    // Status filter
    if (statusFilter !== 'all') {
      result = result.filter((item) => {
        const evaluation = evaluateItemStatus(item.expiryDate, expiringSoonWindowDays);
        return evaluation.status === statusFilter;
      });
    }

    // Category filter
    if (selectedCategories.length > 0) {
      result = result.filter((item) => {
        const cat = item.category.toLowerCase();
        return selectedCategories.some((sc) => cat.includes(sc.toLowerCase()) || sc.toLowerCase().includes(cat));
      });
    }

    // Search query
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase().trim();
      result = result.filter(
        (item) =>
          item.name.toLowerCase().includes(q) ||
          item.category.toLowerCase().includes(q) ||
          (item.location && item.location.toLowerCase().includes(q))
      );
    }

    // Sorting
    result.sort((a, b) => {
      if (sortOption === 'soonest') {
        return a.expiryDate.localeCompare(b.expiryDate);
      }
      if (sortOption === 'recently_added') {
        return b.createdAt.localeCompare(a.createdAt);
      }
      if (sortOption === 'name_asc') {
        return a.name.localeCompare(b.name);
      }
      return 0;
    });

    return result;
  }, [items, statusFilter, selectedCategories, searchQuery, sortOption, expiringSoonWindowDays]);

  const cycleSort = () => {
    const sequence: ItemSortOption[] = ['soonest', 'recently_added', 'name_asc'];
    const nextIndex = (sequence.indexOf(sortOption) + 1) % sequence.length;
    setSortOption(sequence[nextIndex]);
  };

  const getSortLabel = () => {
    switch (sortOption) {
      case 'soonest':
        return 'Soonest';
      case 'recently_added':
        return 'Recent';
      case 'name_asc':
        return 'A–Z';
    }
  };

  const renderItem = ({ item }: { item: Item }) => {
    const evaluation = evaluateItemStatus(item.expiryDate, expiringSoonWindowDays);

    return (
      <TouchableOpacity
        style={[styles.itemCard, { backgroundColor: theme.surface, borderColor: theme.border }]}
        onPress={() => router.push(`/item/${item.id}`)}
        activeOpacity={0.7}
      >
        <CategoryBadge category={item.category} size="md" />

        <View style={styles.itemInfo}>
          <Text style={[styles.itemName, { color: theme.text }]} numberOfLines={1}>
            {item.name}
          </Text>
          <View style={styles.itemMetaRow}>
            <Text style={[styles.itemCategoryTag, { color: theme.primary }]}>
              {item.category}
            </Text>
            {item.location && (
              <View style={styles.locationChip}>
                <MapPin size={10} color={theme.textMuted} />
                <Text style={[styles.locationChipText, { color: theme.textMuted }]}>
                  {item.location}
                </Text>
              </View>
            )}
          </View>
          <Text style={[styles.itemSubtitle, { color: theme.textSecondary }]}>
            {formatDisplayDate(item.expiryDate)} • {evaluation.relativeText}
          </Text>
        </View>

        <StatusPill
          daysLeft={evaluation.daysLeft}
          status={evaluation.status}
        />
      </TouchableOpacity>
    );
  };

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      {/* Top Header */}
      <View style={styles.topHeader}>
        <View style={styles.titleRow}>
          <Text style={[styles.screenTitle, { color: theme.text }]}>All Items</Text>
          <View style={[styles.countBadge, { backgroundColor: 'rgba(22, 163, 74, 0.12)' }]}>
            <Text style={[styles.countBadgeText, { color: theme.primary }]}>{filteredItems.length}</Text>
          </View>
        </View>

        <TouchableOpacity
          style={[styles.headerAddBtn, { backgroundColor: theme.primary }]}
          onPress={() => router.push('/add-item')}
          activeOpacity={0.8}
        >
          <Plus size={18} color="#FFFFFF" strokeWidth={2.5} />
          <Text style={styles.headerAddBtnText}>Add</Text>
        </TouchableOpacity>
      </View>

      {/* Search Input Bar */}
      <View style={styles.searchRow}>
        <View style={[styles.searchContainer, { backgroundColor: theme.surface, borderColor: theme.border }]}>
          <Search size={18} color={theme.textMuted} style={styles.searchIcon} />
          <TextInput
            style={[styles.searchInput, { color: theme.text }]}
            placeholder="Search items, categories, locations..."
            placeholderTextColor={theme.textMuted}
            value={searchQuery}
            onChangeText={setSearchQuery}
          />
          {searchQuery.length > 0 && (
            <TouchableOpacity onPress={() => setSearchQuery('')}>
              <X size={16} color={theme.textMuted} />
            </TouchableOpacity>
          )}
        </View>

        <TouchableOpacity
          style={[styles.sortChip, { backgroundColor: theme.surface, borderColor: theme.border }]}
          onPress={cycleSort}
          activeOpacity={0.7}
        >
          <ArrowUpDown size={15} color={theme.primary} />
          <Text style={[styles.sortChipText, { color: theme.text }]}>{getSortLabel()}</Text>
        </TouchableOpacity>
      </View>

      {/* Category Pills Horizontal Scroll */}
      <View style={styles.categoriesContainer}>
        <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.categoryScroll}>
          {CATEGORIES.map((cat) => {
            const isAll = cat.id === 'all';
            const isSelected = isAll ? selectedCategories.length === 0 : selectedCategories.includes(cat.id);

            return (
              <TouchableOpacity
                key={cat.id}
                style={[
                  styles.categoryPill,
                  isSelected
                    ? { backgroundColor: theme.primary, borderColor: theme.primary }
                    : { backgroundColor: theme.surface, borderColor: theme.border },
                ]}
                onPress={() => {
                  if (isAll) {
                    CATEGORIES.forEach((c) => {
                      if (c.id !== 'all' && selectedCategories.includes(c.id)) {
                        toggleCategory(c.id);
                      }
                    });
                  } else {
                    toggleCategory(cat.id);
                  }
                }}
                activeOpacity={0.7}
              >
                <Text style={styles.categoryPillEmoji}>{cat.emoji}</Text>
                <Text
                  style={[
                    styles.categoryPillText,
                    { color: isSelected ? '#FFFFFF' : theme.textSecondary },
                    isSelected && { fontWeight: '700' },
                  ]}
                >
                  {cat.label}
                </Text>
              </TouchableOpacity>
            );
          })}
        </ScrollView>
      </View>

      {/* Items FlatList */}
      <FlatList
        data={filteredItems}
        keyExtractor={(item) => item.id}
        renderItem={renderItem}
        contentContainerStyle={styles.listContent}
        refreshControl={
          <RefreshControl
            refreshing={isLoading}
            onRefresh={loadItems}
            tintColor={theme.primary}
            colors={[theme.primary]}
          />
        }
        ListEmptyComponent={
          <EmptyState
            title={searchQuery ? 'No matching items' : 'No items yet'}
            subtitle={
              searchQuery
                ? 'Try searching with another keyword or clearing the filter'
                : 'Start tracking your items to stay ahead of expiry dates.'
            }
            actionLabel={searchQuery ? undefined : '+ Add Item'}
            onAction={() => router.push('/add-item')}
          />
        }
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  topHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingTop: 16,
    paddingBottom: 12,
  },
  titleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  screenTitle: {
    fontSize: 24,
    fontWeight: '800',
    letterSpacing: -0.4,
  },
  countBadge: {
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 9999,
  },
  countBadgeText: {
    fontSize: 12,
    fontWeight: '700',
  },
  headerAddBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: 12,
    gap: 4,
  },
  headerAddBtnText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '700',
  },
  searchRow: {
    flexDirection: 'row',
    paddingHorizontal: 16,
    gap: 10,
    marginBottom: 12,
  },
  searchContainer: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: 14,
    borderWidth: 1,
    paddingHorizontal: 14,
    height: 44,
  },
  searchIcon: {
    marginRight: 8,
  },
  searchInput: {
    flex: 1,
    fontSize: 14,
    height: '100%',
  },
  sortChip: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    borderRadius: 14,
    borderWidth: 1,
    gap: 6,
    height: 44,
  },
  sortChipText: {
    fontSize: 13,
    fontWeight: '600',
  },
  categoriesContainer: {
    marginBottom: 12,
  },
  categoryScroll: {
    paddingHorizontal: 16,
    gap: 8,
  },
  categoryPill: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 12,
    paddingVertical: 7,
    borderRadius: 9999,
    borderWidth: 1,
  },
  categoryPillEmoji: {
    fontSize: 13,
  },
  categoryPillText: {
    fontSize: 13,
    fontWeight: '600',
  },
  listContent: {
    paddingHorizontal: 16,
    paddingBottom: 40,
    gap: 10,
  },
  itemCard: {
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: 16,
    borderWidth: 1,
    padding: 12,
    gap: 12,
  },
  itemInfo: {
    flex: 1,
    paddingRight: 4,
  },
  itemName: {
    fontSize: 15,
    fontWeight: '700',
    marginBottom: 2,
  },
  itemMetaRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginBottom: 3,
  },
  itemCategoryTag: {
    fontSize: 12,
    fontWeight: '600',
    textTransform: 'capitalize',
  },
  locationChip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 2,
  },
  locationChipText: {
    fontSize: 11,
    fontWeight: '500',
  },
  itemSubtitle: {
    fontSize: 13,
    fontWeight: '500',
  },
  statusPill: {
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 9999,
    flexShrink: 0,
  },
  statusPillText: {
    fontSize: 12,
    fontWeight: '700',
  },
  emptyContainer: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 60,
  },
  emptyIconCircle: {
    width: 64,
    height: 64,
    borderRadius: 32,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 14,
  },
  emptyTitle: {
    fontSize: 17,
    fontWeight: '700',
    marginBottom: 6,
  },
  emptySubtitle: {
    fontSize: 13,
    textAlign: 'center',
  },
});
