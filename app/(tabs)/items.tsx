import React, { useEffect, useMemo } from 'react';
import { View, Text, StyleSheet, FlatList, TextInput, TouchableOpacity, RefreshControl } from 'react-native';
import { useRouter } from 'expo-router';
import { useTheme } from '../../src/theme';
import { useItemsStore } from '../../src/stores/useItemsStore';
import { useFiltersStore } from '../../src/stores/useFiltersStore';
import { useSettingsStore } from '../../src/stores/useSettingsStore';
import { evaluateItemStatus, formatDisplayDate } from '../../src/services/statusCalculator';
import { Item, ItemSortOption, ItemStatusFilter, PRESET_CATEGORIES } from '../../src/types/item';
import { Search, X, ChevronRight, Plus, ArrowUpDown, Filter } from 'lucide-react-native';

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
      result = result.filter((item) => selectedCategories.includes(item.category.toLowerCase()));
    }

    // Search query (case-insensitive substring)
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

  // Specific empty state text per active filter
  const getEmptyStateMessage = () => {
    if (searchQuery) return `No items matching "${searchQuery}"`;
    if (statusFilter === 'expired') return 'No expired items — nice! 🎉';
    if (statusFilter === 'expiring_soon') return 'No items expiring soon. You are all set!';
    if (statusFilter === 'safe') return 'No safe items currently recorded.';
    if (selectedCategories.length > 0) return 'No items in selected category filters.';
    return 'No items yet. Tap + to add your first item.';
  };

  const renderItem = ({ item }: { item: Item }) => {
    const evaluation = evaluateItemStatus(item.expiryDate, expiringSoonWindowDays);

    return (
      <TouchableOpacity
        style={[styles.itemRow, { backgroundColor: theme.surface, borderColor: theme.border }]}
        onPress={() => router.push(`/item/${item.id}`)}
        activeOpacity={0.7}
      >
        <View style={styles.itemMain}>
          <Text style={[styles.itemName, { color: theme.text }]} numberOfLines={1}>
            {item.name}
          </Text>
          <Text style={[styles.itemSubtext, { color: theme.textMuted }]}>
            {formatDisplayDate(item.expiryDate)} • {item.category}
            {item.location ? ` • ${item.location}` : ''}
          </Text>
        </View>

        <View
          style={[
            styles.statusBadge,
            { backgroundColor: evaluation.badgeBg, borderColor: evaluation.borderColor },
          ]}
        >
          <Text style={[styles.statusBadgeText, { color: evaluation.textColor }]}>{evaluation.label}</Text>
        </View>

        <ChevronRight size={16} color={theme.textMuted} />
      </TouchableOpacity>
    );
  };

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      {/* Search Bar & Sort Toggle */}
      <View style={styles.searchRow}>
        <View style={[styles.searchBox, { backgroundColor: theme.surface, borderColor: theme.border }]}>
          <Search size={18} color={theme.textMuted} />
          <TextInput
            style={[styles.searchInput, { color: theme.text }]}
            placeholder="Search items, categories..."
            placeholderTextColor={theme.textMuted}
            value={searchQuery}
            onChangeText={setSearchQuery}
            clearButtonMode="while-editing"
          />
          {searchQuery.length > 0 && (
            <TouchableOpacity onPress={() => setSearchQuery('')}>
              <X size={16} color={theme.textMuted} />
            </TouchableOpacity>
          )}
        </View>

        <TouchableOpacity
          style={[styles.sortButton, { backgroundColor: theme.surface, borderColor: theme.border }]}
          onPress={cycleSort}
        >
          <ArrowUpDown size={14} color={theme.primary} />
          <Text style={[styles.sortButtonText, { color: theme.text }]}>{getSortLabel()}</Text>
        </TouchableOpacity>
      </View>

      {/* Filter Chips: All / Expiring Soon / Expired / Safe */}
      <View style={styles.chipsScrollContainer}>
        <FlatList
          horizontal
          showsHorizontalScrollIndicator={false}
          data={[
            { id: 'all', label: 'All' },
            { id: 'expiring_soon', label: 'Expiring Soon' },
            { id: 'expired', label: 'Expired' },
            { id: 'safe', label: 'Safe' },
          ] as const}
          keyExtractor={(item) => item.id}
          contentContainerStyle={styles.chipsRow}
          renderItem={({ item }) => {
            const isSelected = statusFilter === item.id;
            return (
              <TouchableOpacity
                style={[
                  styles.filterChip,
                  isSelected
                    ? { backgroundColor: theme.primary, borderColor: theme.primary }
                    : { backgroundColor: theme.surface, borderColor: theme.border },
                ]}
                onPress={() => setStatusFilter(item.id)}
              >
                <Text
                  style={[
                    styles.filterChipText,
                    isSelected ? { color: '#FFFFFF', fontWeight: '600' } : { color: theme.textSecondary },
                  ]}
                >
                  {item.label}
                </Text>
              </TouchableOpacity>
            );
          }}
        />
      </View>

      {/* Items List */}
      <FlatList
        data={filteredItems}
        keyExtractor={(item) => item.id}
        renderItem={renderItem}
        contentContainerStyle={styles.listContent}
        refreshControl={<RefreshControl refreshing={isLoading} onRefresh={loadItems} tintColor={theme.primary} />}
        ListEmptyComponent={
          <View style={[styles.emptyContainer, { backgroundColor: theme.surface, borderColor: theme.border }]}>
            <Text style={[styles.emptyText, { color: theme.textSecondary }]}>{getEmptyStateMessage()}</Text>
            {items.length === 0 && (
              <TouchableOpacity
                style={[styles.addFirstBtn, { backgroundColor: theme.primary }]}
                onPress={() => router.push('/add-item')}
              >
                <Plus size={16} color="#FFFFFF" />
                <Text style={styles.addFirstText}>Add Item</Text>
              </TouchableOpacity>
            )}
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
  searchRow: {
    flexDirection: 'row',
    paddingHorizontal: 16,
    paddingTop: 12,
    paddingBottom: 8,
    gap: 8,
  },
  searchBox: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    height: 42,
    borderRadius: 8,
    borderWidth: 1,
    gap: 8,
  },
  searchInput: {
    flex: 1,
    fontSize: 14,
    height: '100%',
  },
  sortButton: {
    flexDirection: 'row',
    alignItems: 'center',
    height: 42,
    paddingHorizontal: 12,
    borderRadius: 8,
    borderWidth: 1,
    gap: 6,
  },
  sortButtonText: {
    fontSize: 12,
    fontWeight: '600',
  },
  chipsScrollContainer: {
    marginBottom: 8,
  },
  chipsRow: {
    paddingHorizontal: 16,
    gap: 8,
  },
  filterChip: {
    paddingHorizontal: 14,
    paddingVertical: 6,
    borderRadius: 8,
    borderWidth: 1,
  },
  filterChipText: {
    fontSize: 13,
  },
  listContent: {
    paddingHorizontal: 16,
    paddingBottom: 40,
    gap: 8,
  },
  itemRow: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 14,
    borderRadius: 12,
    borderWidth: 1,
  },
  itemMain: {
    flex: 1,
    marginRight: 8,
  },
  itemName: {
    fontSize: 15,
    fontWeight: '600',
    marginBottom: 4,
  },
  itemSubtext: {
    fontSize: 12,
  },
  statusBadge: {
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 9999,
    borderWidth: 1,
    marginRight: 6,
  },
  statusBadgeText: {
    fontSize: 11,
    fontWeight: '600',
  },
  emptyContainer: {
    padding: 32,
    borderRadius: 12,
    borderWidth: 1,
    alignItems: 'center',
    marginTop: 20,
    marginHorizontal: 16,
  },
  emptyText: {
    fontSize: 14,
    textAlign: 'center',
    lineHeight: 20,
  },
  addFirstBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginTop: 16,
    paddingVertical: 10,
    paddingHorizontal: 16,
    borderRadius: 8,
  },
  addFirstText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '600',
  },
});
