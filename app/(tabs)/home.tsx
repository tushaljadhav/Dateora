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
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useTheme } from '../../src/theme';
import { useItemsStore } from '../../src/stores/useItemsStore';
import { useSettingsStore } from '../../src/stores/useSettingsStore';
import { useFiltersStore } from '../../src/stores/useFiltersStore';
import { evaluateItemStatus } from '../../src/services/statusCalculator';
import { notificationService } from '../../src/services/notificationService';
import {
  Plus,
  MagnifyingGlass,
  Bell,
  Clock,
  Package,
  WarningCircle,
  CaretRight,
  ShieldCheck,
  MapPin,
  CalendarBlank,
} from 'phosphor-react-native';
import { DateoraLogo } from '../../src/components/DateoraLogo';
import { StatusPill } from '../../src/components/StatusPill';
import { CategoryBadge } from '../../src/components/CategoryBadge';
import { POPULAR_CATEGORIES } from '../../src/theme/categoryVisuals';

export default function HomeScreen() {
  const { theme, shadows } = useTheme();
  const insets = useSafeAreaInsets();
  const router = useRouter();

  const items = useItemsStore((s) => s.items);
  const isLoading = useItemsStore((s) => s.isLoading);
  const loadItems = useItemsStore((s) => s.loadItems);

  const expiringSoonWindowDays = useSettingsStore((s) => s.expiringSoonWindowDays);
  const notificationsEnabled = useSettingsStore((s) => s.notificationsEnabled);
  const setStatusFilter = useFiltersStore((s) => s.setStatusFilter);
  const setSearchQuery = useFiltersStore((s) => s.setSearchQuery);
  const toggleCategory = useFiltersStore((s) => s.toggleCategory);
  const clearCategories = useFiltersStore((s) => s.clearCategories);

  const [localSearch, setLocalSearch] = useState('');

  useEffect(() => {
    loadItems();
  }, [loadItems]);

  const { greeting, formattedToday } = useMemo(() => {
    const now = new Date();
    const hour = now.getHours();
    let g = 'Good morning';
    if (hour >= 12 && hour < 17) g = 'Good afternoon';
    else if (hour >= 17) g = 'Good evening';

    const options: Intl.DateTimeFormatOptions = {
      weekday: 'short',
      month: 'short',
      day: 'numeric',
    };
    const dateStr = now.toLocaleDateString(undefined, options);
    return { greeting: g, formattedToday: dateStr };
  }, []);

  const { evaluatedItems, activeCount, expiringSoonCount, expiredCount } = useMemo(() => {
    let soon = 0;
    let expired = 0;

    const list = items.map((item) => {
      const evaluation = evaluateItemStatus(item.expiryDate, expiringSoonWindowDays);
      if (evaluation.status === 'expired') expired++;
      else if (evaluation.status === 'expiring_soon' || evaluation.daysLeft <= expiringSoonWindowDays) soon++;
      return { item, evaluation };
    });

    return {
      evaluatedItems: list,
      activeCount: items.length,
      expiringSoonCount: soon,
      expiredCount: expired,
    };
  }, [items, expiringSoonWindowDays]);

  // Priority sorted items for the dashboard (expiring soonest first)
  const priorityList = useMemo(() => {
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
        contentContainerStyle={[
          styles.scrollContent,
          { paddingTop: Math.max(insets.top, 16) + 8, paddingBottom: insets.bottom + 90 },
        ]}
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
        {/* Top Header Bar */}
        <View style={styles.topHeader}>
          <View style={styles.headerLeft}>
            <View style={styles.brandingRow}>
              <DateoraLogo size={24} />
              <Text style={[styles.brandNameMini, { color: theme.primary }]}>Dateora</Text>
            </View>
            <Text style={[styles.greetingText, { color: theme.text }]}>{greeting}</Text>
            <View style={styles.dateRow}>
              <CalendarBlank size={14} color={theme.textSecondary} />
              <Text style={[styles.dateText, { color: theme.textSecondary }]}>{formattedToday}</Text>
            </View>
          </View>

          <TouchableOpacity
            style={[
              styles.bellButton,
              { backgroundColor: theme.surface, borderColor: theme.border },
              shadows.xs,
            ]}
            onPress={() => router.push('/(tabs)/history')}
            activeOpacity={0.8}
            accessibilityLabel="Notifications"
          >
            <Bell size={20} color={theme.text} />
            {expiringSoonCount + expiredCount > 0 && (
              <View style={[styles.bellBadge, { backgroundColor: theme.status.expired.dot }]} />
            )}
          </TouchableOpacity>
        </View>

        {/* Notification Permission Warning Banner */}
        {!notificationsEnabled && (
          <TouchableOpacity
            style={[
              styles.permissionBanner,
              { backgroundColor: theme.status.expiring.bg, borderColor: theme.status.expiring.border },
              shadows.xs,
            ]}
            onPress={() => router.push('/(tabs)/settings')}
            activeOpacity={0.8}
          >
            <View style={styles.permissionBannerLeft}>
              <WarningCircle size={18} color={theme.status.expiring.color} weight="duotone" />
              <Text style={[styles.permissionBannerText, { color: theme.status.expiring.color }]}>
                Reminders are disabled. Tap to enable alerts in Settings.
              </Text>
            </View>
            <CaretRight size={14} color={theme.status.expiring.color} weight="bold" />
          </TouchableOpacity>
        )}

        {/* Search Bar */}
        <View
          style={[
            styles.searchContainer,
            { backgroundColor: theme.surface, borderColor: theme.border },
            shadows.xs,
          ]}
        >
          <MagnifyingGlass size={18} color={theme.textMuted} style={styles.searchIcon} />
          <TextInput
            style={[styles.searchInput, { color: theme.text }]}
            placeholder="Search items, medicines, groceries..."
            placeholderTextColor={theme.textMuted}
            value={localSearch}
            onChangeText={setLocalSearch}
            onSubmitEditing={handleSearchSubmit}
            returnKeyType="search"
          />
        </View>

        {/* 3 Stats Overview Cards with Phosphor Duotone Icons */}
        <View style={styles.statsRow}>
          {/* Total Active */}
          <TouchableOpacity
            style={[
              styles.statCard,
              { backgroundColor: theme.surface, borderColor: theme.border },
              shadows.xs,
            ]}
            onPress={() => handleStatPress('all')}
            activeOpacity={0.8}
          >
            <View style={[styles.statIconBox, { backgroundColor: theme.primarySubtle }]}>
              <Package size={20} color={theme.primary} weight="duotone" />
            </View>
            <Text style={[styles.statNumber, { color: theme.text }]}>{activeCount}</Text>
            <Text style={[styles.statLabel, { color: theme.textSecondary }]}>Active</Text>
          </TouchableOpacity>

          {/* Expiring Soon */}
          <TouchableOpacity
            style={[
              styles.statCard,
              { backgroundColor: theme.surface, borderColor: theme.border },
              shadows.xs,
            ]}
            onPress={() => handleStatPress('expiring_soon')}
            activeOpacity={0.8}
          >
            <View style={[styles.statIconBox, { backgroundColor: theme.status.expiring.bg }]}>
              <Clock size={20} color={theme.status.expiring.color} weight="duotone" />
            </View>
            <Text style={[styles.statNumber, { color: theme.status.expiring.color }]}>
              {expiringSoonCount}
            </Text>
            <Text style={[styles.statLabel, { color: theme.textSecondary }]}>Expiring</Text>
          </TouchableOpacity>

          {/* Expired */}
          <TouchableOpacity
            style={[
              styles.statCard,
              { backgroundColor: theme.surface, borderColor: theme.border },
              shadows.xs,
            ]}
            onPress={() => handleStatPress('expired')}
            activeOpacity={0.8}
          >
            <View style={[styles.statIconBox, { backgroundColor: theme.status.expired.bg }]}>
              <WarningCircle size={20} color={theme.status.expired.color} weight="duotone" />
            </View>
            <Text style={[styles.statNumber, { color: theme.status.expired.color }]}>
              {expiredCount}
            </Text>
            <Text style={[styles.statLabel, { color: theme.textSecondary }]}>Expired</Text>
          </TouchableOpacity>
        </View>

        {/* Categories Pills with Phosphor Duotone Icons inside 10% Tinted Chips */}
        <View style={styles.categoriesSection}>
          <ScrollView
            horizontal
            showsHorizontalScrollIndicator={false}
            contentContainerStyle={styles.categoriesScroll}
          >
            {POPULAR_CATEGORIES.map((cat) => {
              const IconComp = cat.icon;
              return (
                <TouchableOpacity
                  key={cat.id}
                  style={[
                    styles.categoryChip,
                    {
                      backgroundColor: theme.surface,
                      borderColor: theme.border,
                    },
                    shadows.xs,
                  ]}
                  onPress={() => handleCategoryPress(cat.id)}
                  activeOpacity={0.8}
                >
                  <View style={[styles.chipIconBubble, { backgroundColor: cat.bgColor }]}>
                    <IconComp size={16} color={cat.color} weight="duotone" />
                  </View>
                  <Text style={[styles.categoryChipText, { color: theme.text }]}>{cat.name}</Text>
                </TouchableOpacity>
              );
            })}
          </ScrollView>
        </View>

        {/* Urgent / Expiring Soon List — Hero Focus */}
        <View style={styles.sectionHeaderRow}>
          <View>
            <Text style={[styles.sectionTitle, { color: theme.text }]}>Attention Needed</Text>
            <Text style={[styles.sectionSubtitle, { color: theme.textSecondary }]}>
              Items that require your immediate action
            </Text>
          </View>
          <TouchableOpacity
            onPress={() => handleStatPress('expiring_soon')}
            style={styles.viewAllBtn}
            hitSlop={{ top: 12, bottom: 12, left: 12, right: 12 }}
          >
            <Text style={[styles.viewAllText, { color: theme.primary }]}>View all</Text>
            <CaretRight size={14} color={theme.primary} weight="bold" />
          </TouchableOpacity>
        </View>

        {activeCount === 0 ? (
          <View
            style={[
              styles.emptyBasketCard,
              { backgroundColor: theme.surface, borderColor: theme.border },
              shadows.sm,
            ]}
          >
            <Image
              source={require('../../assets/illustrations/empty_basket.png')}
              style={styles.emptyBasketImage}
              resizeMode="contain"
            />
            <Text style={[styles.emptyBasketTitle, { color: theme.text }]}>No items tracked yet</Text>
            <Text style={[styles.emptyBasketSubtitle, { color: theme.textSecondary }]}>
              Add groceries, medicines, or cosmetics to get notified before they expire.
            </Text>
            <TouchableOpacity
              style={[styles.emptyAddBtn, { backgroundColor: theme.primary }]}
              onPress={() => router.push('/add-item')}
              activeOpacity={0.88}
            >
              <Plus size={16} color="#FFFFFF" weight="bold" />
              <Text style={styles.emptyAddBtnText}>Add your first item</Text>
            </TouchableOpacity>
          </View>
        ) : priorityList.length === 0 ? (
          <View
            style={[
              styles.peaceOfMindCard,
              { backgroundColor: theme.surface, borderColor: theme.border },
              shadows.sm,
            ]}
          >
            <View style={[styles.peaceIconCircle, { backgroundColor: theme.status.safe.bg }]}>
              <ShieldCheck size={32} color={theme.status.safe.color} weight="duotone" />
            </View>
            <Text style={[styles.peaceTitle, { color: theme.text }]}>All items are fresh & safe!</Text>
            <Text style={[styles.peaceSubtitle, { color: theme.textSecondary }]}>
              No items expiring in the next {expiringSoonWindowDays} days. Dateora will alert you before anything expires.
            </Text>
          </View>
        ) : (
          <View style={styles.itemsList}>
            {priorityList.slice(0, 6).map(({ item, evaluation }) => {
              return (
                <TouchableOpacity
                  key={item.id}
                  style={[
                    styles.itemCard,
                    { backgroundColor: theme.surface, borderColor: theme.border },
                    shadows.xs,
                  ]}
                  onPress={() => router.push(`/item/${item.id}`)}
                  activeOpacity={0.75}
                >
                  {item.photoUri ? (
                    <Image source={{ uri: item.photoUri }} style={styles.itemPhotoThumb} resizeMode="cover" />
                  ) : (
                    <CategoryBadge category={item.category} size="md" />
                  )}

                  <View style={styles.itemInfo}>
                    <Text style={[styles.itemName, { color: theme.text }]} numberOfLines={1}>
                      {item.name}
                    </Text>
                    <View style={styles.itemMetaRow}>
                      <Text style={[styles.itemCategoryTag, { color: theme.textSecondary }]}>
                        {item.category}
                      </Text>
                      {item.location ? (
                        <>
                          <Text style={[styles.metaDot, { color: theme.textMuted }]}>•</Text>
                          <View style={styles.locationChip}>
                            <MapPin size={12} color={theme.textMuted} weight="bold" />
                            <Text style={[styles.locationChipText, { color: theme.textSecondary }]}>
                              {item.location}
                            </Text>
                          </View>
                        </>
                      ) : null}
                    </View>
                  </View>

                  <StatusPill daysLeft={evaluation.daysLeft} status={evaluation.status} />
                </TouchableOpacity>
              );
            })}
          </View>
        )}
      </ScrollView>

      {/* Floating Add Item Button with Brand Gradient / Primary Blue */}
      <TouchableOpacity
        style={[styles.fab, { backgroundColor: theme.primary }, shadows.glow]}
        onPress={() => router.push('/add-item')}
        activeOpacity={0.88}
        accessibilityLabel="Add New Item"
      >
        <Plus size={20} color="#FFFFFF" weight="bold" />
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
    paddingHorizontal: 16,
  },
  topHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  headerLeft: {
    flex: 1,
  },
  brandingRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginBottom: 4,
  },
  brandNameMini: {
    fontSize: 14,
    fontWeight: '700',
    letterSpacing: -0.3,
  },
  greetingText: {
    fontSize: 28,
    lineHeight: 36,
    fontWeight: '700',
    letterSpacing: -0.5,
  },
  dateRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    marginTop: 2,
  },
  dateText: {
    fontSize: 12,
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
    fontSize: 14,
    height: '100%',
  },
  statsRow: {
    flexDirection: 'row',
    gap: 10,
    marginBottom: 16,
  },
  statCard: {
    flex: 1,
    borderRadius: 20,
    borderWidth: 1,
    paddingVertical: 14,
    paddingHorizontal: 10,
    alignItems: 'center',
    justifyContent: 'center',
  },
  statIconBox: {
    width: 36,
    height: 36,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 8,
  },
  statNumber: {
    fontSize: 20,
    lineHeight: 28,
    fontWeight: '700',
    letterSpacing: -0.3,
  },
  statLabel: {
    fontSize: 12,
    fontWeight: '500',
    marginTop: 2,
  },
  categoriesSection: {
    marginBottom: 20,
  },
  categoriesScroll: {
    gap: 8,
    paddingRight: 8,
  },
  categoryChip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 999,
    borderWidth: 1,
  },
  chipIconBubble: {
    width: 28,
    height: 28,
    borderRadius: 14,
    alignItems: 'center',
    justifyContent: 'center',
  },
  categoryChipText: {
    fontSize: 13,
    fontWeight: '600',
    paddingRight: 4,
  },
  sectionHeaderRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-end',
    marginBottom: 12,
    paddingHorizontal: 2,
  },
  sectionTitle: {
    fontSize: 20,
    lineHeight: 28,
    fontWeight: '600',
    letterSpacing: -0.3,
  },
  sectionSubtitle: {
    fontSize: 12,
    marginTop: 2,
  },
  viewAllBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 2,
  },
  viewAllText: {
    fontSize: 13,
    fontWeight: '600',
  },
  peaceOfMindCard: {
    borderRadius: 20,
    borderWidth: 1,
    paddingVertical: 32,
    paddingHorizontal: 20,
    alignItems: 'center',
    justifyContent: 'center',
  },
  peaceIconCircle: {
    width: 60,
    height: 60,
    borderRadius: 30,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 14,
  },
  peaceTitle: {
    fontSize: 17,
    fontWeight: '600',
    marginBottom: 6,
  },
  peaceSubtitle: {
    fontSize: 13,
    lineHeight: 18,
    textAlign: 'center',
    maxWidth: 280,
  },
  itemsList: {
    gap: 10,
  },
  itemCard: {
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: 20,
    borderWidth: 1,
    padding: 12,
    gap: 12,
  },
  itemPhotoThumb: {
    width: 44,
    height: 44,
    borderRadius: 12,
  },
  itemInfo: {
    flex: 1,
    paddingRight: 4,
  },
  itemName: {
    fontSize: 15,
    fontWeight: '600',
    marginBottom: 2,
    letterSpacing: -0.2,
  },
  itemMetaRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
  },
  itemCategoryTag: {
    fontSize: 12,
    fontWeight: '500',
    textTransform: 'capitalize',
  },
  metaDot: {
    fontSize: 12,
  },
  locationChip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 3,
  },
  locationChipText: {
    fontSize: 11,
    fontWeight: '500',
  },
  fab: {
    position: 'absolute',
    bottom: 24,
    right: 20,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 22,
    paddingVertical: 14,
    borderRadius: 14,
    minHeight: 52,
  },
  fabText: {
    color: '#FFFFFF',
    fontSize: 15,
    fontWeight: '600',
    letterSpacing: -0.2,
  },
  permissionBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 10,
    paddingHorizontal: 14,
    borderRadius: 12,
    borderWidth: 1,
    marginBottom: 14,
  },
  permissionBannerLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    flex: 1,
    paddingRight: 8,
  },
  permissionBannerText: {
    fontSize: 12,
    fontWeight: '600',
    flex: 1,
  },
  emptyBasketCard: {
    borderRadius: 20,
    borderWidth: 1,
    padding: 28,
    alignItems: 'center',
    justifyContent: 'center',
    marginVertical: 12,
  },
  emptyBasketImage: {
    width: 140,
    height: 120,
    marginBottom: 16,
  },
  emptyBasketTitle: {
    fontSize: 18,
    fontWeight: '700',
    marginBottom: 6,
    textAlign: 'center',
  },
  emptyBasketSubtitle: {
    fontSize: 13,
    lineHeight: 18,
    textAlign: 'center',
    marginBottom: 20,
    paddingHorizontal: 16,
  },
  emptyAddBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 20,
    paddingVertical: 12,
    borderRadius: 12,
  },
  emptyAddBtnText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '700',
  },
});
