import React, { useEffect, useState, useMemo } from 'react';
import { View, Text, StyleSheet, FlatList, TouchableOpacity, RefreshControl, Alert } from 'react-native';
import { useTheme } from '../../src/theme';
import { useItemsStore } from '../../src/stores/useItemsStore';
import { Item, ItemLifecycleStatus } from '../../src/types/item';
import { formatDisplayDate } from '../../src/services/statusCalculator';
import { RotateCcw, CheckCircle2, Trash2, Archive } from 'lucide-react-native';

type HistoryFilterTab = 'all' | 'used' | 'finished' | 'disposed';

export default function HistoryScreen() {
  const { theme } = useTheme();
  const historyItems = useItemsStore((s) => s.historyItems);
  const loadHistory = useItemsStore((s) => s.loadHistory);
  const restoreItem = useItemsStore((s) => s.restoreItem);
  const deleteItem = useItemsStore((s) => s.deleteItem);

  const [activeTab, setActiveTab] = useState<HistoryFilterTab>('all');
  const [refreshing, setRefreshing] = useState(false);

  useEffect(() => {
    loadHistory();
  }, [loadHistory]);

  const handleRefresh = async () => {
    setRefreshing(true);
    await loadHistory();
    setRefreshing(false);
  };

  const filteredHistory = useMemo(() => {
    if (activeTab === 'all') return historyItems;
    return historyItems.filter((i) => i.status === activeTab);
  }, [historyItems, activeTab]);

  const handleRestore = (item: Item) => {
    Alert.alert(
      'Restore Item',
      `Restore "${item.name}" back to active tracking?`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Restore',
          onPress: async () => {
            await restoreItem(item.id);
          },
        },
      ]
    );
  };

  const handleDeletePermanent = (item: Item) => {
    Alert.alert(
      'Delete Permanently',
      `Remove "${item.name}" from history permanently? This cannot be undone.`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: async () => {
            await deleteItem(item.id);
          },
        },
      ]
    );
  };

  const getStatusBadge = (status: ItemLifecycleStatus) => {
    switch (status) {
      case 'used':
        return { label: 'Used', bg: '#DCFCE7', text: theme.successDark };
      case 'finished':
        return { label: 'Finished', bg: '#E0F2FE', text: theme.accent };
      case 'disposed':
        return { label: 'Disposed', bg: '#FEE2E2', text: theme.danger };
      default:
        return { label: status, bg: theme.surfaceSubtle, text: theme.textSecondary };
    }
  };

  const renderItem = ({ item }: { item: Item }) => {
    const badge = getStatusBadge(item.status);

    return (
      <View style={[styles.historyCard, { backgroundColor: theme.surface, borderColor: theme.border }]}>
        <View style={styles.cardMain}>
          <View style={styles.titleRow}>
            <Text style={[styles.itemName, { color: theme.text }]} numberOfLines={1}>
              {item.name}
            </Text>
            <View style={[styles.statusPill, { backgroundColor: badge.bg }]}>
              <Text style={[styles.statusText, { color: badge.text }]}>{badge.label}</Text>
            </View>
          </View>

          <Text style={[styles.subText, { color: theme.textMuted }]}>
            Expiry: {formatDisplayDate(item.expiryDate)} • {item.category}
          </Text>

          {item.statusChangedAt && (
            <Text style={[styles.metaText, { color: theme.textMuted }]}>
              Logged {new Date(item.statusChangedAt).toLocaleDateString()}
            </Text>
          )}
        </View>

        <View style={styles.actionsRow}>
          <TouchableOpacity
            style={[styles.actionBtn, { borderColor: theme.border }]}
            onPress={() => handleRestore(item)}
          >
            <RotateCcw size={14} color={theme.primary} />
            <Text style={[styles.actionBtnText, { color: theme.primary }]}>Restore</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.deleteIconBtn, { borderColor: theme.border }]}
            onPress={() => handleDeletePermanent(item)}
          >
            <Trash2 size={15} color={theme.danger} />
          </TouchableOpacity>
        </View>
      </View>
    );
  };

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      {/* Filter Tabs */}
      <View style={styles.tabsRow}>
        {(['all', 'used', 'finished', 'disposed'] as const).map((tab) => {
          const isSelected = activeTab === tab;
          const label = tab === 'all' ? 'All' : tab.charAt(0).toUpperCase() + tab.slice(1);
          return (
            <TouchableOpacity
              key={tab}
              style={[
                styles.tabChip,
                isSelected
                  ? { backgroundColor: theme.primary, borderColor: theme.primary }
                  : { backgroundColor: theme.surface, borderColor: theme.border },
              ]}
              onPress={() => setActiveTab(tab)}
            >
              <Text
                style={[
                  styles.tabChipText,
                  isSelected ? { color: '#FFFFFF', fontWeight: '600' } : { color: theme.textSecondary },
                ]}
              >
                {label}
              </Text>
            </TouchableOpacity>
          );
        })}
      </View>

      <FlatList
        data={filteredHistory}
        keyExtractor={(item) => item.id}
        renderItem={renderItem}
        contentContainerStyle={styles.listContent}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={handleRefresh} tintColor={theme.primary} />}
        ListEmptyComponent={
          <View style={[styles.emptyCard, { backgroundColor: theme.surface, borderColor: theme.border }]}>
            <Archive size={32} color={theme.textMuted} style={{ marginBottom: 8 }} />
            <Text style={[styles.emptyTitle, { color: theme.text }]}>No history records</Text>
            <Text style={[styles.emptyText, { color: theme.textMuted }]}>
              Items you mark as Used, Finished, or Disposed will appear here.
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
  tabsRow: {
    flexDirection: 'row',
    paddingHorizontal: 16,
    paddingVertical: 12,
    gap: 8,
  },
  tabChip: {
    paddingHorizontal: 14,
    paddingVertical: 6,
    borderRadius: 8,
    borderWidth: 1,
  },
  tabChipText: {
    fontSize: 13,
  },
  listContent: {
    paddingHorizontal: 16,
    paddingBottom: 32,
    gap: 10,
  },
  historyCard: {
    padding: 14,
    borderRadius: 12,
    borderWidth: 1,
  },
  cardMain: {
    marginBottom: 12,
  },
  titleRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 4,
  },
  itemName: {
    fontSize: 15,
    fontWeight: '600',
    flex: 1,
    marginRight: 8,
  },
  statusPill: {
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 9999,
  },
  statusText: {
    fontSize: 11,
    fontWeight: '600',
  },
  subText: {
    fontSize: 13,
    marginBottom: 2,
  },
  metaText: {
    fontSize: 11,
  },
  actionsRow: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    gap: 8,
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopColor: '#E2E8F0',
    paddingTop: 10,
  },
  actionBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 8,
    borderWidth: 1,
  },
  actionBtnText: {
    fontSize: 12,
    fontWeight: '600',
  },
  deleteIconBtn: {
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 8,
    borderWidth: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  emptyCard: {
    padding: 32,
    borderRadius: 12,
    borderWidth: 1,
    alignItems: 'center',
    marginTop: 20,
  },
  emptyTitle: {
    fontSize: 16,
    fontWeight: '700',
    marginBottom: 4,
  },
  emptyText: {
    fontSize: 13,
    textAlign: 'center',
  },
});
