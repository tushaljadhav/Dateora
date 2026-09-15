import React, { useEffect, useMemo } from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, RefreshControl } from 'react-native';
import { useRouter } from 'expo-router';
import { useTheme } from '../../src/theme';
import { useItemsStore } from '../../src/stores/useItemsStore';
import { useSettingsStore } from '../../src/stores/useSettingsStore';
import { useFiltersStore } from '../../src/stores/useFiltersStore';
import { evaluateItemStatus, formatDisplayDate } from '../../src/services/statusCalculator';
import { Plus, AlertCircle, Clock, PackageCheck, ChevronRight, Sparkles } from 'lucide-react-native';

export default function HomeScreen() {
  const { theme } = useTheme();
  const router = useRouter();

  const items = useItemsStore((s) => s.items);
  const isLoading = useItemsStore((s) => s.isLoading);
  const loadItems = useItemsStore((s) => s.loadItems);

  const expiringSoonWindowDays = useSettingsStore((s) => s.expiringSoonWindowDays);
  const setStatusFilter = useFiltersStore((s) => s.setStatusFilter);

  useEffect(() => {
    loadItems();
  }, [loadItems]);

  const greeting = useMemo(() => {
    const hour = new Date().getHours();
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }, []);

  const { evaluatedItems, totalCount, expiringCount, expiredCount } = useMemo(() => {
    let expCount = 0;
    let soonCount = 0;

    const list = items.map((item) => {
      const evaluation = evaluateItemStatus(item.expiryDate, expiringSoonWindowDays);
      if (evaluation.status === 'expired') expCount++;
      if (evaluation.status === 'expiring_soon') soonCount++;
      return { item, evaluation };
    });

    return {
      evaluatedItems: list,
      totalCount: items.length,
      expiringCount: soonCount,
      expiredCount: expCount,
    };
  }, [items, expiringSoonWindowDays]);

  const expiringSoonList = useMemo(() => {
    return evaluatedItems
      .filter((i) => i.evaluation.status === 'expiring_soon' || i.evaluation.status === 'expired')
      .sort((a, b) => a.evaluation.daysLeft - b.evaluation.daysLeft);
  }, [evaluatedItems]);

  const handleStatPress = (filter: 'all' | 'expiring_soon' | 'expired') => {
    setStatusFilter(filter);
    router.push('/(tabs)/items');
  };

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        refreshControl={<RefreshControl refreshing={isLoading} onRefresh={loadItems} tintColor={theme.primary} />}
      >
        {/* Header Greeting */}
        <View style={styles.header}>
          <Text style={[styles.greetingSubtitle, { color: theme.textMuted }]}>{greeting} 👋</Text>
          <Text style={[styles.greetingTitle, { color: theme.text }]}>Expiry Overview</Text>
        </View>

        {/* 3 Tappable Stat Chips */}
        <View style={styles.statsRow}>
          <TouchableOpacity
            style={[styles.statChip, { backgroundColor: theme.surface, borderColor: theme.border }]}
            onPress={() => handleStatPress('all')}
            activeOpacity={0.7}
          >
            <View style={[styles.statIconBadge, { backgroundColor: theme.surfaceSubtle }]}>
              <PackageCheck size={18} color={theme.primary} />
            </View>
            <Text style={[styles.statNumber, { color: theme.text }]}>{totalCount}</Text>
            <Text style={[styles.statLabel, { color: theme.textMuted }]}>Total Items</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.statChip, { backgroundColor: theme.surface, borderColor: theme.border }]}
            onPress={() => handleStatPress('expiring_soon')}
            activeOpacity={0.7}
          >
            <View style={[styles.statIconBadge, { backgroundColor: '#FEF3C7' }]}>
              <Clock size={18} color={theme.warningDark} />
            </View>
            <Text style={[styles.statNumber, { color: theme.warningDark }]}>{expiringCount}</Text>
            <Text style={[styles.statLabel, { color: theme.textMuted }]}>Expiring Soon</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.statChip, { backgroundColor: theme.surface, borderColor: theme.border }]}
            onPress={() => handleStatPress('expired')}
            activeOpacity={0.7}
          >
            <View style={[styles.statIconBadge, { backgroundColor: '#FEE2E2' }]}>
              <AlertCircle size={18} color={theme.danger} />
            </View>
            <Text style={[styles.statNumber, { color: theme.danger }]}>{expiredCount}</Text>
            <Text style={[styles.statLabel, { color: theme.textMuted }]}>Expired</Text>
          </TouchableOpacity>
        </View>

        {/* Expiring Soon Section */}
        <View style={styles.sectionHeader}>
          <Text style={[styles.sectionTitle, { color: theme.text }]}>Attention Needed</Text>
          {expiringSoonList.length > 0 && (
            <TouchableOpacity onPress={() => handleStatPress('expiring_soon')}>
              <Text style={[styles.sectionAction, { color: theme.primary }]}>View all</Text>
            </TouchableOpacity>
          )}
        </View>

        {totalCount === 0 ? (
          /* Empty state when user has zero items app-wide */
          <View style={[styles.emptyCard, { backgroundColor: theme.surface, borderColor: theme.border }]}>
            <View style={[styles.emptyIconCircle, { backgroundColor: theme.surfaceSubtle }]}>
              <Sparkles size={32} color={theme.primary} />
            </View>
            <Text style={[styles.emptyTitle, { color: theme.text }]}>Track your first item</Text>
            <Text style={[styles.emptySubtitle, { color: theme.textMuted }]}>
              Never let groceries or medicines expire silently. Add your first item in under 30 seconds.
            </Text>
            <TouchableOpacity
              style={[styles.ctaButton, { backgroundColor: theme.primary }]}
              onPress={() => router.push('/add-item')}
            >
              <Plus size={18} color="#FFFFFF" style={{ marginRight: 6 }} />
              <Text style={styles.ctaButtonText}>Add your first item</Text>
            </TouchableOpacity>
          </View>
        ) : expiringSoonList.length === 0 ? (
          <View style={[styles.safeCard, { backgroundColor: theme.surface, borderColor: theme.border }]}>
            <Text style={[styles.safeTitle, { color: theme.text }]}>Everything looks good! 🎉</Text>
            <Text style={[styles.safeSubtitle, { color: theme.textMuted }]}>
              No items are expiring within your {expiringSoonWindowDays}-day alert window.
            </Text>
          </View>
        ) : (
          <View style={styles.itemsList}>
            {expiringSoonList.map(({ item, evaluation }) => (
              <TouchableOpacity
                key={item.id}
                style={[styles.itemCard, { backgroundColor: theme.surface, borderColor: theme.border }]}
                onPress={() => router.push(`/item/${item.id}`)}
                activeOpacity={0.7}
              >
                <View style={styles.itemInfo}>
                  <Text style={[styles.itemName, { color: theme.text }]} numberOfLines={1}>
                    {item.name}
                  </Text>
                  <Text style={[styles.itemDate, { color: theme.textMuted }]}>
                    {formatDisplayDate(item.expiryDate)} • {item.category}
                  </Text>
                </View>
                <View
                  style={[
                    styles.statusPill,
                    { backgroundColor: evaluation.badgeBg, borderColor: evaluation.borderColor },
                  ]}
                >
                  <Text style={[styles.statusPillText, { color: evaluation.textColor }]}>{evaluation.label}</Text>
                </View>
                <ChevronRight size={16} color={theme.textMuted} style={styles.chevron} />
              </TouchableOpacity>
            ))}
          </View>
        )}
      </ScrollView>

      {/* Floating Action Button (+ Add Item) */}
      <TouchableOpacity
        style={[styles.fab, { backgroundColor: theme.primary }]}
        onPress={() => router.push('/add-item')}
        activeOpacity={0.85}
      >
        <Plus size={24} color="#FFFFFF" />
        <Text style={styles.fabText}>Add Item</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  scrollContent: {
    padding: 16,
    paddingBottom: 96,
  },
  header: {
    marginBottom: 20,
    marginTop: 8,
  },
  greetingSubtitle: {
    fontSize: 14,
    fontWeight: '500',
    marginBottom: 4,
  },
  greetingTitle: {
    fontSize: 26,
    fontWeight: '700',
  },
  statsRow: {
    flexDirection: 'row',
    gap: 8,
    marginBottom: 24,
  },
  statChip: {
    flex: 1,
    padding: 12,
    borderRadius: 12,
    borderWidth: 1,
    alignItems: 'center',
  },
  statIconBadge: {
    width: 32,
    height: 32,
    borderRadius: 8,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 8,
  },
  statNumber: {
    fontSize: 20,
    fontWeight: '700',
    marginBottom: 2,
  },
  statLabel: {
    fontSize: 11,
    fontWeight: '500',
    textAlign: 'center',
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '700',
  },
  sectionAction: {
    fontSize: 14,
    fontWeight: '600',
  },
  emptyCard: {
    borderRadius: 12,
    borderWidth: 1,
    padding: 24,
    alignItems: 'center',
    marginTop: 12,
  },
  emptyIconCircle: {
    width: 64,
    height: 64,
    borderRadius: 32,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 16,
  },
  emptyTitle: {
    fontSize: 18,
    fontWeight: '700',
    marginBottom: 8,
  },
  emptySubtitle: {
    fontSize: 14,
    textAlign: 'center',
    lineHeight: 20,
    marginBottom: 20,
    paddingHorizontal: 8,
  },
  ctaButton: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 12,
    paddingHorizontal: 20,
    borderRadius: 8,
  },
  ctaButtonText: {
    color: '#FFFFFF',
    fontSize: 15,
    fontWeight: '600',
  },
  safeCard: {
    borderRadius: 12,
    borderWidth: 1,
    padding: 20,
    alignItems: 'center',
    marginTop: 8,
  },
  safeTitle: {
    fontSize: 16,
    fontWeight: '600',
    marginBottom: 6,
  },
  safeSubtitle: {
    fontSize: 13,
    textAlign: 'center',
  },
  itemsList: {
    gap: 8,
  },
  itemCard: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 14,
    borderRadius: 12,
    borderWidth: 1,
  },
  itemInfo: {
    flex: 1,
    marginRight: 8,
  },
  itemName: {
    fontSize: 15,
    fontWeight: '600',
    marginBottom: 3,
  },
  itemDate: {
    fontSize: 12,
  },
  statusPill: {
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 9999,
    borderWidth: 1,
    marginRight: 6,
  },
  statusPillText: {
    fontSize: 11,
    fontWeight: '600',
  },
  chevron: {
    marginLeft: 2,
  },
  fab: {
    position: 'absolute',
    bottom: 24,
    right: 20,
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 12,
    paddingHorizontal: 20,
    borderRadius: 9999,
    elevation: 4,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.25,
    shadowRadius: 4,
    gap: 8,
  },
  fabText: {
    color: '#FFFFFF',
    fontSize: 15,
    fontWeight: '600',
  },
});
