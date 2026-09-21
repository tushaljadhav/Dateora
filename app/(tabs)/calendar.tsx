import React, { useState, useMemo } from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity } from 'react-native';
import { useRouter } from 'expo-router';
import { useTheme } from '../../src/theme';
import { useItemsStore } from '../../src/stores/useItemsStore';
import { useSettingsStore } from '../../src/stores/useSettingsStore';
import { evaluateItemStatus, formatDisplayDate } from '../../src/services/statusCalculator';
import { ChevronLeft, ChevronRight, Calendar as CalendarIcon, Package, Milk, Pill, Sparkle, Home, Coffee } from 'lucide-react-native';

export default function CalendarScreen() {
  const { theme } = useTheme();
  const router = useRouter();

  const items = useItemsStore((s) => s.items);
  const expiringSoonWindowDays = useSettingsStore((s) => s.expiringSoonWindowDays);

  const [currentDate, setCurrentDate] = useState(new Date());
  const [selectedDayStr, setSelectedDayStr] = useState<string | null>(() => {
    const today = new Date();
    const y = today.getFullYear();
    const m = String(today.getMonth() + 1).padStart(2, '0');
    const d = String(today.getDate()).padStart(2, '0');
    return `${y}-${m}-${d}`;
  });

  const year = currentDate.getFullYear();
  const month = currentDate.getMonth();

  const monthName = currentDate.toLocaleString('default', { month: 'long', year: 'numeric' });

  // Map items by date string "YYYY-MM-DD"
  const itemsByDate = useMemo(() => {
    const map: Record<string, typeof items> = {};
    for (const item of items) {
      if (!map[item.expiryDate]) {
        map[item.expiryDate] = [];
      }
      map[item.expiryDate].push(item);
    }
    return map;
  }, [items]);

  // Generate calendar days for current month
  const calendarDays = useMemo(() => {
    const firstDayIndex = new Date(year, month, 1).getDay();
    const daysInMonth = new Date(year, month + 1, 0).getDate();

    const days: Array<{ dayNumber: number | null; dateString: string | null }> = [];

    // Empty lead slots
    for (let i = 0; i < firstDayIndex; i++) {
      days.push({ dayNumber: null, dateString: null });
    }

    // Days in current month
    for (let d = 1; d <= daysInMonth; d++) {
      const monthPadded = String(month + 1).padStart(2, '0');
      const dayPadded = String(d).padStart(2, '0');
      const dateString = `${year}-${monthPadded}-${dayPadded}`;
      days.push({ dayNumber: d, dateString });
    }

    return days;
  }, [year, month]);

  const changeMonth = (offset: number) => {
    setCurrentDate(new Date(year, month + offset, 1));
  };

  const selectedDayItems = selectedDayStr ? itemsByDate[selectedDayStr] || [] : [];

  const getCategoryIcon = (category: string) => {
    switch (category.toLowerCase()) {
      case 'groceries':
      case 'food':
        return <Milk size={18} color={theme.primary} />;
      case 'medicine':
        return <Pill size={18} color="#06B6D4" />;
      case 'skincare':
      case 'cosmetics':
        return <Sparkle size={18} color="#EC4899" />;
      case 'household':
        return <Home size={18} color="#8B5CF6" />;
      case 'beverages':
        return <Coffee size={18} color="#F59E0B" />;
      default:
        return <Package size={18} color={theme.primary} />;
    }
  };

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
        {/* Month Header Navigation */}
        <View style={[styles.headerCard, { backgroundColor: theme.surface, borderColor: theme.border }]}>
          <TouchableOpacity onPress={() => changeMonth(-1)} style={styles.navArrow} activeOpacity={0.7}>
            <ChevronLeft size={20} color={theme.text} />
          </TouchableOpacity>
          <Text style={[styles.monthTitle, { color: theme.text }]}>{monthName}</Text>
          <TouchableOpacity onPress={() => changeMonth(1)} style={styles.navArrow} activeOpacity={0.7}>
            <ChevronRight size={20} color={theme.text} />
          </TouchableOpacity>
        </View>

        {/* Days of Week Header */}
        <View style={styles.weekDaysRow}>
          {['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((wd) => (
            <Text key={wd} style={[styles.weekDayLabel, { color: theme.textMuted }]}>
              {wd}
            </Text>
          ))}
        </View>

        {/* Month Grid */}
        <View style={[styles.gridCard, { backgroundColor: theme.surface, borderColor: theme.border }]}>
          <View style={styles.daysGrid}>
            {calendarDays.map((cell, index) => {
              if (cell.dayNumber === null || !cell.dateString) {
                return <View key={`empty-${index}`} style={styles.dayCell} />;
              }

              const isSelected = selectedDayStr === cell.dateString;
              const cellItems = itemsByDate[cell.dateString] || [];
              const hasItems = cellItems.length > 0;

              // Dot colors
              let dotColor = theme.primary;
              if (hasItems) {
                const evaluations = cellItems.map((i) => evaluateItemStatus(i.expiryDate, expiringSoonWindowDays));
                if (evaluations.some((e) => e.status === 'expired')) {
                  dotColor = '#EF4444';
                } else if (evaluations.some((e) => e.status === 'expiring_soon')) {
                  dotColor = '#F59E0B';
                }
              }

              return (
                <TouchableOpacity
                  key={cell.dateString}
                  style={[
                    styles.dayCell,
                    isSelected && { backgroundColor: theme.primary, borderRadius: 12 },
                  ]}
                  onPress={() => setSelectedDayStr(cell.dateString)}
                  activeOpacity={0.7}
                >
                  <Text
                    style={[
                      styles.dayNumberText,
                      { color: isSelected ? '#FFFFFF' : theme.text },
                      isSelected && { fontWeight: '700' },
                    ]}
                  >
                    {cell.dayNumber}
                  </Text>

                  {hasItems && (
                    <View style={styles.dotsRow}>
                      <View
                        style={[
                          styles.statusDot,
                          { backgroundColor: isSelected ? '#FFFFFF' : dotColor },
                        ]}
                      />
                    </View>
                  )}
                </TouchableOpacity>
              );
            })}
          </View>
        </View>

        {/* Selected Day Sheet */}
        <View style={styles.sheetSection}>
          <View style={styles.sheetHeaderRow}>
            <Text style={[styles.sheetTitle, { color: theme.text }]}>
              {selectedDayStr ? formatDisplayDate(selectedDayStr) : 'Select a date'}
            </Text>
            {selectedDayItems.length > 0 && (
              <View style={[styles.sheetCountBadge, { backgroundColor: 'rgba(22, 163, 74, 0.12)' }]}>
                <Text style={[styles.sheetCountText, { color: theme.primary }]}>
                  {selectedDayItems.length} expiring
                </Text>
              </View>
            )}
          </View>

          {selectedDayItems.length === 0 ? (
            <View style={[styles.emptySheetCard, { backgroundColor: theme.surface, borderColor: theme.border }]}>
              <Text style={[styles.emptySheetText, { color: theme.textSecondary }]}>
                No items expiring on this date.
              </Text>
            </View>
          ) : (
            <View style={styles.sheetItemsList}>
              {selectedDayItems.map((item) => {
                const evaluation = evaluateItemStatus(item.expiryDate, expiringSoonWindowDays);
                return (
                  <TouchableOpacity
                    key={item.id}
                    style={[styles.sheetItemCard, { backgroundColor: theme.surface, borderColor: theme.border }]}
                    onPress={() => router.push(`/item/${item.id}`)}
                    activeOpacity={0.7}
                  >
                    <View style={[styles.sheetItemIcon, { backgroundColor: theme.surfaceSubtle }]}>
                      {getCategoryIcon(item.category)}
                    </View>

                    <View style={styles.sheetItemTextCol}>
                      <Text style={[styles.sheetItemName, { color: theme.text }]} numberOfLines={1}>
                        {item.name}
                      </Text>
                      <Text style={[styles.sheetItemCategory, { color: theme.textSecondary }]}>
                        {item.category} {item.location ? `• ${item.location}` : ''}
                      </Text>
                    </View>

                    <View
                      style={[
                        styles.sheetStatusPill,
                        { backgroundColor: evaluation.badgeBg },
                      ]}
                    >
                      <Text style={[styles.sheetStatusPillText, { color: evaluation.textColor }]}>
                        {evaluation.relativeText}
                      </Text>
                    </View>
                  </TouchableOpacity>
                );
              })}
            </View>
          )}
        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  scrollContent: {
    padding: 20,
    paddingBottom: 40,
  },
  headerCard: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderRadius: 16,
    borderWidth: 1,
    marginBottom: 16,
  },
  navArrow: {
    width: 36,
    height: 36,
    alignItems: 'center',
    justifyContent: 'center',
  },
  monthTitle: {
    fontSize: 17,
    fontWeight: '700',
  },
  weekDaysRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingHorizontal: 12,
    marginBottom: 8,
  },
  weekDayLabel: {
    width: 40,
    textAlign: 'center',
    fontSize: 12,
    fontWeight: '600',
  },
  gridCard: {
    borderRadius: 18,
    borderWidth: 1,
    padding: 12,
    marginBottom: 20,
  },
  daysGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
  },
  dayCell: {
    width: '14.28%',
    height: 48,
    alignItems: 'center',
    justifyContent: 'center',
    position: 'relative',
  },
  dayNumberText: {
    fontSize: 14,
    fontWeight: '500',
  },
  dotsRow: {
    flexDirection: 'row',
    gap: 2,
    position: 'absolute',
    bottom: 6,
  },
  statusDot: {
    width: 5,
    height: 5,
    borderRadius: 2.5,
  },
  sheetSection: {
    gap: 12,
  },
  sheetHeaderRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 4,
  },
  sheetTitle: {
    fontSize: 17,
    fontWeight: '700',
  },
  sheetCountBadge: {
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 9999,
  },
  sheetCountText: {
    fontSize: 12,
    fontWeight: '700',
  },
  emptySheetCard: {
    borderRadius: 16,
    borderWidth: 1,
    padding: 24,
    alignItems: 'center',
    justifyContent: 'center',
  },
  emptySheetText: {
    fontSize: 14,
  },
  sheetItemsList: {
    gap: 10,
  },
  sheetItemCard: {
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: 16,
    borderWidth: 1,
    padding: 12,
  },
  sheetItemIcon: {
    width: 40,
    height: 40,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  sheetItemTextCol: {
    flex: 1,
  },
  sheetItemName: {
    fontSize: 15,
    fontWeight: '700',
    marginBottom: 2,
  },
  sheetItemCategory: {
    fontSize: 12,
  },
  sheetStatusPill: {
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 9999,
  },
  sheetStatusPillText: {
    fontSize: 12,
    fontWeight: '700',
  },
});
