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
  Milk,
  Pill,
  Sparkle,
  Home,
  Coffee,
  HelpCircle,
  Package,
} from 'lucide-react-native';

const CATEGORIES = [
  { id: 'all', label: 'All' },
  { id: 'food', label: 'Food' },
  { id: 'medicine', label: 'Medicine' },
  { id: 'cosmetics', label: 'Cosmetics' },
  { id: 'household', label: 'Household' },
  { id: 'beverages', label: 'Beverages' },
  { id: 'others', label: 'Others' },
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

  const getCategoryIcon = (category: string) => {
    switch (category.toLowerCase()) {
      case 'groceries':
      case 'food':
        return <Milk size={20} color={theme.primary} />;
      case 'medicine':
        return <Pill size={20} color="#06B6D4" />;
      case 'skincare':
      case 'cosmetics':
        return <Sparkle size={20} color="#EC4899" />;
      case 'household':
        return <Home size={20} color="#8B5CF6" />;
      case 'beverages':
        return <Coffee size={20} color="#F59E0B" />;
      default:
        return <Package size={20} color={theme.primary} />;
    }
  };

  const renderItem = ({ item }: { item: Item }) => {
    const evaluation = evaluateItemStatus(item.expiryDate, expiringSoonWindowDays);
    const isExpired = evaluation.status === 'expired';
    const isToday = evaluation.daysLeft === 0;

    let pillBg = 'rgba(245, 158, 11, 0.15)';
    let pillText = '#D97706';
    let pillLabel = `${evaluation.daysLeft} days`;

    if (isExpired) {
      pillBg = 'rgba(239, 68, 68, 0.15)';
      pillText = '#DC2626';
      pillLabel = 'Expired';
    } else if (isToday) {
      pillBg = 'rgba(239, 68, 68, 0.15)';
      pillText = '#DC2626';
      pillLabel = 'Today';
    } else if (evaluation.daysLeft === 1) {
      pillBg = 'rgba(245, 158, 11, 0.15)';
      pillText = '#D97706';
      pillLabel = '1 day';
    } else if (evaluation.daysLeft > 5) {
      pillBg = 'rgba(22, 163, 74, 0.15)';
      pillText = '#15803D';
    }

    return (
      <TouchableOpacity
        style={[styles.itemCard, { backgroundColor: theme.surface, borderColor: theme.border }]}
        onPress={() => router.push(`/item/${item.id}`)}
        activeOpacity={0.7}
      >
        <View style={[styles.itemIconCircle, { backgroundColor: theme.surfaceSubtle }]}>
          {getCategoryIcon(item.category)}
        </View>

        <View style={styles.itemInfo}>
          <Text style={[styles.itemName, { color: theme.text }]} numberOfLines={1}>
            {item.name}
          </Text>
          <Text style={[styles.itemSubtitle, { color: theme.textSecondary }]}>
            {formatDisplayDate(item.expiryDate)} {item.location ? `• ${item.location}` : ''}
          </Text>
        </View>

        <View style={[styles.statusPill, { backgroundColor: pillBg }]}>
          <Text style={[styles.statusPillText, { color: pillText }]}>{pillLabel}</Text>
        </View>
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
          <View style={styles.emptyContainer}>
            <View style={[styles.emptyIconCircle, { backgroundColor: theme.surfaceSubtle }]}>
              <Package size={36} color={theme.textMuted} />
            </View>
            <Text style={[styles.emptyTitle, { color: theme.text }]}>No items found</Text>
            <Text style={[styles.emptySubtitle, { color: theme.textSecondary }]}>
              {searchQuery ? 'Try searching with another keyword' : 'Add your first item to start tracking'}
            </Text>
          </View>
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
    paddingHorizontal: 20,
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
    paddingHorizontal: 20,
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
    paddingHorizontal: 20,
    gap: 8,
  },
  categoryPill: {
    paddingHorizontal: 14,
    paddingVertical: 7,
    borderRadius: 9999,
    borderWidth: 1,
  },
  categoryPillText: {
    fontSize: 13,
    fontWeight: '600',
  },
  listContent: {
    paddingHorizontal: 20,
    paddingBottom: 40,
    gap: 10,
  },
  itemCard: {
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: 16,
    borderWidth: 1,
    padding: 14,
  },
  itemIconCircle: {
    width: 44,
    height: 44,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 14,
  },
  itemInfo: {
    flex: 1,
  },
  itemName: {
    fontSize: 16,
    fontWeight: '700',
    marginBottom: 3,
  },
  itemSubtitle: {
    fontSize: 13,
    fontWeight: '500',
  },
  statusPill: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 9999,
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
