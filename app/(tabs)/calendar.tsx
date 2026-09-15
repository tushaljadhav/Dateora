import React, { useState, useMemo } from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity } from 'react-native';
import { useRouter } from 'expo-router';
import { useTheme } from '../../src/theme';
import { useItemsStore } from '../../src/stores/useItemsStore';
import { useSettingsStore } from '../../src/stores/useSettingsStore';
import { evaluateItemStatus, formatDisplayDate } from '../../src/services/statusCalculator';
import { ChevronLeft, ChevronRight, Calendar as CalendarIcon, Package } from 'lucide-react-native';

export default function CalendarScreen() {
  const { theme } = useTheme();
  const router = useRouter();

  const items = useItemsStore((s) => s.items);
  const expiringSoonWindowDays = useSettingsStore((s) => s.expiringSoonWindowDays);

  const [currentDate, setCurrentDate] = useState(new Date());
  const [selectedDayStr, setSelectedDayStr] = useState<string | null>(null);

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
    setSelectedDayStr(null);
  };

  const selectedDayItems = selectedDayStr ? itemsByDate[selectedDayStr] || [] : [];

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      <ScrollView contentContainerStyle={styles.scrollContent}>
        {/* Month Header Navigation */}
        <View style={[styles.headerCard, { backgroundColor: theme.surface, borderColor: theme.border }]}>
          <TouchableOpacity onPress={() => changeMonth(-1)} style={styles.navArrow}>
            <ChevronLeft size={20} color={theme.text} />
          </TouchableOpacity>
          <Text style={[styles.monthTitle, { color: theme.text }]}>{monthName}</Text>
          <TouchableOpacity onPress={() => changeMonth(1)} style={styles.navArrow}>
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
          <View style={styles.grid}>
            {calendarDays.map((cell, index) => {
              if (cell.dayNumber === null || !cell.dateString) {
                return <View key={`empty-${index}`} style={styles.dayCell} />;
              }

              const dayItems = itemsByDate[cell.dateString] || [];
              const isSelected = selectedDayStr === cell.dateString;

              // Determine dot color
              let dotColor: string | null = null;
              if (dayItems.length > 0) {
                const evaluations = dayItems.map((i) => evaluateItemStatus(i.expiryDate, expiringSoonWindowDays));
                if (evaluations.some((e) => e.status === 'expired')) {
                  dotColor = theme.danger;
                } else if (evaluations.some((e) => e.status === 'expiring_soon')) {
                  dotColor = theme.warning;
                } else {
                  dotColor = theme.success;
                }
              }

              return (
                <TouchableOpacity
                  key={cell.dateString}
                  style={[
                    styles.dayCell,
                    isSelected && { backgroundColor: theme.surfaceSubtle, borderRadius: 8, borderColor: theme.primary, borderWidth: 1 },
                  ]}
                  onPress={() => setSelectedDayStr(cell.dateString)}
                >
                  <Text
                    style={[
                      styles.dayNumberText,
                      { color: isSelected ? theme.primary : theme.text },
                      isSelected && { fontWeight: '700' },
                    ]}
                  >
                    {cell.dayNumber}
                  </Text>
                  {dotColor && <View style={[styles.dot, { backgroundColor: dotColor }]} />}
                </TouchableOpacity>
              );
            })}
          </View>
        </View>

        {/* Selected Day Items Sheet / Section */}
        {selectedDayStr ? (
          <View style={styles.selectedDaySection}>
            <View style={styles.selectedHeaderRow}>
              <CalendarIcon size={18} color={theme.primary} />
              <Text style={[styles.selectedDayTitle, { color: theme.text }]}>
                {formatDisplayDate(selectedDayStr)}
              </Text>
              <Text style={[styles.selectedDayCount, { color: theme.textMuted }]}>
                ({selectedDayItems.length} {selectedDayItems.length === 1 ? 'item' : 'items'})
              </Text>
            </View>

            {selectedDayItems.length === 0 ? (
              <View style={[styles.noItemsCard, { backgroundColor: theme.surface, borderColor: theme.border }]}>
                <Text style={[styles.noItemsText, { color: theme.textMuted }]}>No items expiring on this date.</Text>
              </View>
            ) : (
              <View style={styles.dayItemsList}>
                {selectedDayItems.map((item) => {
                  const evaluation = evaluateItemStatus(item.expiryDate, expiringSoonWindowDays);
                  return (
                    <TouchableOpacity
                      key={item.id}
                      style={[styles.itemCard, { backgroundColor: theme.surface, borderColor: theme.border }]}
                      onPress={() => router.push(`/item/${item.id}`)}
                    >
                      <View style={styles.itemCardLeft}>
                        <Text style={[styles.itemCardName, { color: theme.text }]}>{item.name}</Text>
                        <Text style={[styles.itemCardCategory, { color: theme.textMuted }]}>{item.category}</Text>
                      </View>
                      <View
                        style={[
                          styles.statusBadge,
                          { backgroundColor: evaluation.badgeBg, borderColor: evaluation.borderColor },
                        ]}
                      >
                        <Text style={[styles.statusBadgeText, { color: evaluation.textColor }]}>
                          {evaluation.label}
                        </Text>
                      </View>
                    </TouchableOpacity>
                  );
                })}
              </View>
            )}
          </View>
        ) : (
          <View style={[styles.tapHintCard, { backgroundColor: theme.surface, borderColor: theme.border }]}>
            <Text style={[styles.tapHintText, { color: theme.textMuted }]}>
              Tap any date with a colored dot to view expiring items.
            </Text>
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
  headerCard: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: 12,
    borderRadius: 12,
    borderWidth: 1,
    marginBottom: 16,
  },
  navArrow: {
    padding: 6,
  },
  monthTitle: {
    fontSize: 16,
    fontWeight: '700',
  },
  weekDaysRow: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    marginBottom: 8,
  },
  weekDayLabel: {
    fontSize: 12,
    fontWeight: '600',
    width: 40,
    textAlign: 'center',
  },
  gridCard: {
    borderRadius: 12,
    borderWidth: 1,
    padding: 8,
    marginBottom: 20,
  },
  grid: {
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
  },
  dot: {
    width: 6,
    height: 6,
    borderRadius: 3,
    position: 'absolute',
    bottom: 6,
  },
  selectedDaySection: {
    marginTop: 4,
  },
  selectedHeaderRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginBottom: 12,
  },
  selectedDayTitle: {
    fontSize: 16,
    fontWeight: '700',
  },
  selectedDayCount: {
    fontSize: 14,
  },
  noItemsCard: {
    padding: 20,
    borderRadius: 12,
    borderWidth: 1,
    alignItems: 'center',
  },
  noItemsText: {
    fontSize: 14,
  },
  dayItemsList: {
    gap: 8,
  },
  itemCard: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: 14,
    borderRadius: 12,
    borderWidth: 1,
  },
  itemCardLeft: {
    flex: 1,
    marginRight: 8,
  },
  itemCardName: {
    fontSize: 15,
    fontWeight: '600',
    marginBottom: 2,
  },
  itemCardCategory: {
    fontSize: 12,
  },
  statusBadge: {
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 9999,
    borderWidth: 1,
  },
  statusBadgeText: {
    fontSize: 11,
    fontWeight: '600',
  },
  tapHintCard: {
    padding: 16,
    borderRadius: 12,
    borderWidth: 1,
    alignItems: 'center',
  },
  tapHintText: {
    fontSize: 13,
    textAlign: 'center',
  },
});
