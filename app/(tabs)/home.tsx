import React, { useEffect, useMemo, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  RefreshControl,
  TextInput,
  Image,
} from 'react-native';
import { useRouter } from 'expo-router';
import { useTheme } from '../../src/theme';
import { useItemsStore } from '../../src/stores/useItemsStore';
import { useSettingsStore } from '../../src/stores/useSettingsStore';
import { useFiltersStore } from '../../src/stores/useFiltersStore';
import { evaluateItemStatus, formatDisplayDate } from '../../src/services/statusCalculator';
import {
  Plus,
  Search,
  Bell,
  Clock,
  Package,
  ChevronRight,
  Sparkles,
  AlertTriangle,
  Camera,
  MapPin,
} from 'lucide-react-native';
import { DateoraLogo } from '../../src/components/DateoraLogo';
import { StatusPill } from '../../src/components/StatusPill';
import { CategoryBadge } from '../../src/components/CategoryBadge';
import { POPULAR_CATEGORIES } from '../../src/theme/categoryVisuals';

export default function HomeScreen() {
  const { theme, isDark } = useTheme();
  const router = useRouter();

  const items = useItemsStore((s) => s.items);
  const isLoading = useItemsStore((s) => s.isLoading);
  const loadItems = useItemsStore((s) => s.loadItems);

  const expiringSoonWindowDays = useSettingsStore((s) => s.expiringSoonWindowDays);
  const setStatusFilter = useFiltersStore((s) => s.setStatusFilter);
  const setSearchQuery = useFiltersStore((s) => s.setSearchQuery);
  const toggleCategory = useFiltersStore((s) => s.toggleCategory);
  const clearCategories = useFiltersStore((s) => s.clearCategories);

  const [localSearch, setLocalSearch] = useState('');

  useEffect(() => {
    loadItems();
  }, [loadItems]);

  const greeting = useMemo(() => {
    const hour = new Date().getHours();
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }, []);

  const { evaluatedItems, activeCount, expiringTodayCount, expiringSoonCount } = useMemo(() => {
    let todayCount = 0;
    let soonCount = 0;

    const list = items.map((item) => {
      const evaluation = evaluateItemStatus(item.expiryDate, expiringSoonWindowDays);
      if (evaluation.daysLeft === 0) todayCount++;
      else if (evaluation.status === 'expiring_soon') soonCount++;
      return { item, evaluation };
    });

    return {
      evaluatedItems: list,
      activeCount: items.length,
      expiringTodayCount: todayCount,
      expiringSoonCount: soonCount,
    };
  }, [items, expiringSoonWindowDays]);

  // Priority sorted items for the dashboard
  const expiringSoonList = useMemo(() => {
    return evaluatedItems
      .filter((i) => i.evaluation.status === 'expiring_soon' || i.evaluation.status === 'expired')
      .sort((a, b) => a.evaluation.daysLeft - b.evaluation.daysLeft);
  }, [evaluatedItems]);

  const handleSearchSubmit = () => {
    setSearchQuery(localSearch);
    router.push('/(tabs)/items');
  };

  const handleStatPress = (filter: 'all' | 'expiring_soon' | 'expired') => {
    setStatusFilter(filter);
    router.push('/(tabs)/items');
  };

  const handleCategoryPress = (catId: string) => {
    clearCategories();
    toggleCategory(catId);
    router.push('/(tabs)/items');
  };

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        refreshControl={
          <RefreshControl
            refreshing={isLoading}
            onRefresh={loadItems}
            tintColor={theme.primary}
            colors={[theme.primary]}
          />
        }
        showsVerticalScrollIndicator={false}
      >
        {/* Top Header Bar with Dateora Emblem */}
        <View style={styles.topHeader}>
          <View style={styles.headerLeft}>
            <View style={styles.brandingRow}>
              <DateoraLogo size={24} />
              <Text style={[styles.brandNameMini, { color: theme.primary }]}>Dateora</Text>
            </View>
            <View style={styles.greetingRow}>
              <Text style={[styles.greetingText, { color: theme.text }]}>{greeting}, Tushal</Text>
              <Text style={styles.waveEmoji}>👋</Text>
            </View>
            <Text style={[styles.subGreeting, { color: theme.textSecondary }]}>Keep your items fresh</Text>
          </View>

          <TouchableOpacity
            style={[styles.bellButton, { backgroundColor: theme.surface, borderColor: theme.border }]}
            onPress={() => router.push('/(tabs)/history')}
            activeOpacity={0.7}
          >
            <Bell size={20} color={theme.text} />
            {expiringTodayCount + expiringSoonCount > 0 && (
              <View style={[styles.bellBadge, { backgroundColor: theme.danger }]} />
            )}
          </TouchableOpacity>
        </View>

        {/* Search Bar */}
        <View style={[styles.searchContainer, { backgroundColor: theme.surface, borderColor: theme.border }]}>
          <Search size={18} color={theme.textMuted} style={styles.searchIcon} />
          <TextInput
            style={[styles.searchInput, { color: theme.text }]}
            placeholder="Search items, medicines, dairy..."
            placeholderTextColor={theme.textMuted}
            value={localSearch}
            onChangeText={setLocalSearch}
            onSubmitEditing={handleSearchSubmit}
            returnKeyType="search"
          />
        </View>

        {/* Visual Hero Banner Card */}
        <View
          style={[
            styles.heroBanner,
            {
              backgroundColor: isDark ? 'rgba(22, 163, 74, 0.12)' : '#F0FDF4',
              borderColor: isDark ? 'rgba(34, 197, 94, 0.25)' : '#DCFCE7',
            },
          ]}
        >
          <View style={styles.heroBannerTextCol}>
            <View
              style={[
                styles.heroBannerBadge,
                { backgroundColor: isDark ? 'rgba(34, 197, 94, 0.2)' : '#DCFCE7' },
              ]}
            >
              <Sparkles size={12} color={theme.primary} />
              <Text style={[styles.heroBannerBadgeText, { color: theme.primary }]}>
                Stay Fresh
              </Text>
            </View>
            <Text style={[styles.heroBannerTitle, { color: theme.text }]}>
              Zero Food Waste
            </Text>
            <Text style={[styles.heroBannerSubtitle, { color: theme.textSecondary }]}>
              Keep items fresh & get timely smart alarms.
            </Text>
          </View>
          <Image
            source={require('../../assets/illustrations/groceries_hero.png')}
            style={styles.heroBannerImage}
            resizeMode="contain"
          />
        </View>

        {/* Quick Categories Bar */}
        <View style={styles.categoriesSection}>
          <ScrollView
            horizontal
            showsHorizontalScrollIndicator={false}
            contentContainerStyle={styles.categoriesScroll}
          >
            {POPULAR_CATEGORIES.map((cat) => (
              <TouchableOpacity
                key={cat.id}
                style={[
                  styles.categoryChip,
                  {
                    backgroundColor: isDark ? cat.bgColorDark : cat.bgColorLight,
                    borderColor: isDark ? cat.borderColorDark : cat.borderColorLight,
                  },
                ]}
                onPress={() => handleCategoryPress(cat.id)}
                activeOpacity={0.7}
              >
                <Text style={styles.categoryChipEmoji}>{cat.emoji}</Text>
                <Text style={[styles.categoryChipText, { color: isDark ? '#FFFFFF' : cat.color }]}>
                  {cat.name}
                </Text>
              </TouchableOpacity>
            ))}
          </ScrollView>
        </View>

        {/* Metric Cards Grid (2 Column Clean Cards matching Reference Board) */}
        <View style={styles.metricsRow}>
          {/* Expiring Today */}
          <TouchableOpacity
            style={[styles.metricCard, { backgroundColor: theme.surface, borderColor: theme.border }]}
            onPress={() => handleStatPress('expiring_soon')}
            activeOpacity={0.7}
          >
            <View style={styles.metricHeaderRow}>
              <View style={[styles.metricIconCircle, { backgroundColor: isDark ? 'rgba(239, 68, 68, 0.18)' : '#FEE2E2' }]}>
                <Clock size={18} color="#EF4444" />
              </View>
              <Text style={[styles.metricNumber, { color: '#EF4444' }]}>{expiringTodayCount}</Text>
            </View>
            <Text style={[styles.metricLabel, { color: theme.textSecondary }]}>Expiring Today</Text>
          </TouchableOpacity>

          {/* Active Items */}
          <TouchableOpacity
            style={[styles.metricCard, { backgroundColor: theme.surface, borderColor: theme.border }]}
            onPress={() => handleStatPress('all')}
            activeOpacity={0.7}
          >
            <View style={styles.metricHeaderRow}>
              <View style={[styles.metricIconCircle, { backgroundColor: isDark ? 'rgba(34, 197, 94, 0.18)' : '#DCFCE7' }]}>
                <Package size={18} color={theme.primary} />
              </View>
              <Text style={[styles.metricNumber, { color: theme.primary }]}>{activeCount}</Text>
            </View>
            <Text style={[styles.metricLabel, { color: theme.textSecondary }]}>Active Items</Text>
          </TouchableOpacity>
        </View>

        {/* Quick Actions Row: Add & Scan */}
        <View style={styles.quickActionsRow}>
          <TouchableOpacity
            style={[styles.primaryActionBtn, { backgroundColor: theme.primary }]}
            onPress={() => router.push('/add-item')}
            activeOpacity={0.85}
          >
            <Plus size={18} color="#FFFFFF" strokeWidth={2.5} />
            <Text style={styles.primaryActionBtnText}>Add Item</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[
              styles.secondaryActionBtn,
              {
                backgroundColor: isDark ? 'rgba(34, 197, 94, 0.12)' : '#DCFCE7',
                borderColor: isDark ? 'rgba(34, 197, 94, 0.25)' : '#BBF7D0',
              },
            ]}
            onPress={() => router.push('/add-item')}
            activeOpacity={0.85}
          >
            <Camera size={18} color={theme.primary} />
            <Text style={[styles.secondaryActionBtnText, { color: theme.primary }]}>Scan Barcode</Text>
          </TouchableOpacity>
        </View>

        {/* Expiring Soon Section */}
        <View style={styles.sectionHeaderRow}>
          <Text style={[styles.sectionTitle, { color: theme.text }]}>Expiring Soon</Text>
          <TouchableOpacity onPress={() => handleStatPress('expiring_soon')}>
            <Text style={[styles.viewAllText, { color: theme.primary }]}>View All</Text>
          </TouchableOpacity>
        </View>

        {/* Items List or Fresh Empty State */}
        {expiringSoonList.length === 0 ? (
          <View style={[styles.emptyCard, { backgroundColor: theme.surface, borderColor: theme.border }]}>
            <Image
              source={require('../../assets/illustrations/shield_hero.png')}
              style={styles.emptyIllustration}
              resizeMode="contain"
            />
            <Text style={[styles.emptyTitle, { color: theme.text }]}>All items are fresh!</Text>
            <Text style={[styles.emptySubtitle, { color: theme.textSecondary }]}>
              Nothing is expiring soon. Track new groceries or household items to stay notified.
            </Text>
          </View>
        ) : (
          <View style={styles.itemsList}>
            {expiringSoonList.slice(0, 5).map(({ item, evaluation }) => {
              const isExpired = evaluation.status === 'expired';
              const isToday = evaluation.daysLeft === 0;

              return (
                <TouchableOpacity
                  key={item.id}
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
                      {isExpired ? 'Expired' : isToday ? 'Expires today' : evaluation.relativeText}
                    </Text>
                  </View>

                  <StatusPill
                    daysLeft={evaluation.daysLeft}
                    status={evaluation.status}
                  />
                </TouchableOpacity>
              );
            })}
          </View>
        )}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  scrollContent: {
    padding: 16,
    paddingBottom: 40,
  },
  topHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 18,
    marginTop: 4,
  },
  headerLeft: {
    flex: 1,
  },
  brandingRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginBottom: 4,
  },
  brandNameMini: {
    fontSize: 14,
    fontWeight: '800',
    letterSpacing: -0.3,
  },
  greetingRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  greetingText: {
    fontSize: 22,
    fontWeight: '800',
    letterSpacing: -0.4,
  },
  waveEmoji: {
    fontSize: 20,
  },
  subGreeting: {
    fontSize: 14,
    marginTop: 2,
    fontWeight: '500',
  },
  bellButton: {
    width: 44,
    height: 44,
    borderRadius: 22,
    borderWidth: 1,
    alignItems: 'center',
    justifyContent: 'center',
    position: 'relative',
  },
  bellBadge: {
    position: 'absolute',
    top: 10,
    right: 10,
    width: 8,
    height: 8,
    borderRadius: 4,
  },
  searchContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: 14,
    borderWidth: 1,
    paddingHorizontal: 14,
    height: 48,
    marginBottom: 16,
  },
  searchIcon: {
    marginRight: 10,
  },
  searchInput: {
    flex: 1,
    fontSize: 15,
    height: '100%',
  },
  heroBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    borderRadius: 20,
    borderWidth: 1,
    padding: 16,
    marginBottom: 16,
    overflow: 'hidden',
  },
  heroBannerTextCol: {
    flex: 1,
    paddingRight: 10,
  },
  heroBannerBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    alignSelf: 'flex-start',
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 9999,
    marginBottom: 6,
  },
  heroBannerBadgeText: {
    fontSize: 11,
    fontWeight: '700',
  },
  heroBannerTitle: {
    fontSize: 18,
    fontWeight: '800',
    letterSpacing: -0.3,
    marginBottom: 4,
  },
  heroBannerSubtitle: {
    fontSize: 12,
    lineHeight: 16,
    fontWeight: '500',
  },
  heroBannerImage: {
    width: 86,
    height: 86,
    flexShrink: 0,
  },
  categoriesSection: {
    marginBottom: 16,
  },
  categoriesScroll: {
    gap: 8,
    paddingRight: 8,
  },
  categoryChip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 14,
    borderWidth: 1,
  },
  categoryChipEmoji: {
    fontSize: 15,
  },
  categoryChipText: {
    fontSize: 13,
    fontWeight: '700',
  },
  metricsRow: {
    flexDirection: 'row',
    gap: 12,
    marginBottom: 16,
  },
  metricCard: {
    flex: 1,
    borderRadius: 16,
    borderWidth: 1,
    padding: 14,
    minWidth: 0,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.04,
    shadowRadius: 8,
    elevation: 1,
  },
  metricHeaderRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  metricIconCircle: {
    width: 36,
    height: 36,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
  },
  metricNumber: {
    fontSize: 24,
    fontWeight: '800',
  },
  metricLabel: {
    fontSize: 13,
    fontWeight: '600',
  },
  quickActionsRow: {
    flexDirection: 'row',
    gap: 10,
    marginBottom: 24,
  },
  primaryActionBtn: {
    flex: 1.2,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    height: 50,
    borderRadius: 14,
    gap: 6,
    shadowColor: '#16A34A',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.2,
    shadowRadius: 8,
    elevation: 3,
  },
  primaryActionBtnText: {
    color: '#FFFFFF',
    fontSize: 15,
    fontWeight: '700',
  },
  secondaryActionBtn: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    height: 50,
    borderRadius: 14,
    borderWidth: 1,
    gap: 6,
  },
  secondaryActionBtnText: {
    fontSize: 14,
    fontWeight: '700',
  },
  sectionHeaderRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 14,
    paddingHorizontal: 2,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '700',
    letterSpacing: -0.3,
  },
  viewAllText: {
    fontSize: 14,
    fontWeight: '600',
  },
  itemsList: {
    gap: 10,
  },
  itemCard: {
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: 16,
    borderWidth: 1,
    padding: 12,
    gap: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.03,
    shadowRadius: 6,
    elevation: 1,
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
  emptyCard: {
    borderRadius: 16,
    borderWidth: 1,
    padding: 24,
    alignItems: 'center',
    justifyContent: 'center',
    textAlign: 'center',
  },
  emptyIllustration: {
    width: 96,
    height: 96,
    marginBottom: 12,
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
    lineHeight: 18,
    paddingHorizontal: 12,
  },
});
