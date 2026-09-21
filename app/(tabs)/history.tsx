import React, { useEffect, useState, useMemo } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  RefreshControl,
  Alert,
  Platform,
} from 'react-native';
import { useTheme } from '../../src/theme';
import { useItemsStore } from '../../src/stores/useItemsStore';
import { Item, ItemLifecycleStatus } from '../../src/types/item';
import { formatDisplayDate } from '../../src/services/statusCalculator';
import { RotateCcw, CheckCircle2, Trash2, Archive, XCircle } from 'lucide-react-native';
import { EmptyState } from '../../src/components/EmptyState';

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
    if (Platform.OS === 'web') {
      const confirmed = window.confirm(`Restore "${item.name}" back to active tracking?`);
      if (confirmed) {
        restoreItem(item.id);
      }
      return;
    }

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
    if (Platform.OS === 'web') {
      const confirmed = window.confirm(`Remove "${item.name}" from history permanently? This cannot be undone.`);
      if (confirmed) {
        deleteItem(item.id);
      }
      return;
    }

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
        return { label: 'Used', bg: 'rgba(22, 163, 74, 0.12)', text: '#16A34A' };
      case 'finished':
        return { label: 'Finished', bg: 'rgba(6, 182, 212, 0.12)', text: '#0891B2' };
      case 'disposed':
        return { label: 'Disposed', bg: 'rgba(239, 68, 68, 0.12)', text: '#DC2626' };
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

          <Text style={[styles.subText, { color: theme.textSecondary }]}>
            Expiry: {formatDisplayDate(item.expiryDate)} • {item.category}
          </Text>

          {item.statusChangedAt && (
            <Text style={[styles.metaText, { color: theme.textMuted }]}>
              Marked on {new Date(item.statusChangedAt).toLocaleDateString()}
            </Text>
          )}
        </View>

        <View style={[styles.actionsRow, { borderTopColor: theme.border }]}>
          <TouchableOpacity
            style={[styles.actionBtn, { backgroundColor: 'rgba(22, 163, 74, 0.12)' }]}
            onPress={() => handleRestore(item)}
            activeOpacity={0.7}
          >
            <RotateCcw size={15} color={theme.primary} />
            <Text style={[styles.actionBtnText, { color: theme.primary }]}>Restore</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.actionBtn, { backgroundColor: 'rgba(239, 68, 68, 0.12)' }]}
            onPress={() => handleDeletePermanent(item)}
            activeOpacity={0.7}
          >
            <Trash2 size={15} color={theme.danger} />
            <Text style={[styles.actionBtnText, { color: theme.danger }]}>Delete</Text>
          </TouchableOpacity>
        </View>
      </View>
    );
  };

  const tabs: Array<{ id: HistoryFilterTab; label: string }> = [
    { id: 'all', label: 'All' },
    { id: 'used', label: 'Used' },
    { id: 'finished', label: 'Finished' },
    { id: 'disposed', label: 'Disposed' },
  ];

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      {/* Filter Tabs */}
      <View style={[styles.tabBarContainer, { backgroundColor: theme.surface, borderBottomColor: theme.border }]}>
        {tabs.map((tab) => {
          const isSelected = activeTab === tab.id;
          return (
            <TouchableOpacity
              key={tab.id}
              style={[
                styles.tabItem,
                isSelected && { borderBottomColor: theme.primary, borderBottomWidth: 2 },
              ]}
              onPress={() => setActiveTab(tab.id)}
              activeOpacity={0.7}
            >
              <Text
                style={[
                  styles.tabLabel,
                  { color: isSelected ? theme.primary : theme.textSecondary },
                  isSelected && { fontWeight: '700' },
                ]}
              >
                {tab.label}
              </Text>
            </TouchableOpacity>
          );
        })}
      </View>

      {/* History Items FlatList */}
      <FlatList
        data={filteredHistory}
        keyExtractor={(item) => item.id}
        renderItem={renderItem}
        contentContainerStyle={styles.listContent}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={handleRefresh}
            tintColor={theme.primary}
            colors={[theme.primary]}
          />
        }
        ListEmptyComponent={
          <EmptyState
            title="No history items"
            subtitle={
              activeTab === 'all'
                ? 'Items marked as used, finished, or disposed will appear here.'
                : `No items marked as ${activeTab} yet.`
            }
            icon={<Archive size={32} color={theme.primary} />}
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
  tabBarContainer: {
    flexDirection: 'row',
    borderBottomWidth: 1,
  },
  tabItem: {
    flex: 1,
    paddingVertical: 14,
    alignItems: 'center',
    justifyContent: 'center',
  },
  tabLabel: {
    fontSize: 14,
    fontWeight: '600',
  },
  listContent: {
    padding: 16,
    paddingBottom: 40,
    gap: 12,
  },
  historyCard: {
    borderRadius: 16,
    borderWidth: 1,
    overflow: 'hidden',
  },
  cardMain: {
    padding: 16,
  },
  titleRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 6,
  },
  itemName: {
    fontSize: 16,
    fontWeight: '700',
    flex: 1,
    marginRight: 10,
  },
  statusPill: {
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 9999,
  },
  statusText: {
    fontSize: 11,
    fontWeight: '700',
  },
  subText: {
    fontSize: 13,
    marginBottom: 4,
  },
  metaText: {
    fontSize: 12,
  },
  actionsRow: {
    flexDirection: 'row',
    borderTopWidth: StyleSheet.hairlineWidth,
    padding: 10,
    gap: 10,
  },
  actionBtn: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 9,
    borderRadius: 10,
    gap: 6,
  },
  actionBtnText: {
    fontSize: 13,
    fontWeight: '700',
  },
  emptyContainer: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 80,
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
    paddingHorizontal: 24,
    lineHeight: 18,
  },
});
