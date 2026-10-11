import React, { useState, useMemo } from 'react';
import {
  Modal,
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Pressable,
} from 'react-native';
import { useTheme } from '../theme';
import { ChevronLeft, ChevronRight, Calendar as CalendarIcon, Check, X } from 'lucide-react-native';

interface DatePickerModalProps {
  visible: boolean;
  selectedDate: string; // YYYY-MM-DD
  onClose: () => void;
  onSelectDate: (dateStr: string) => void;
}

export const DatePickerModal: React.FC<DatePickerModalProps> = ({
  visible,
  selectedDate,
  onClose,
  onSelectDate,
}) => {
  const { theme } = useTheme();

  // Parse initial date
  const initialDateObj = useMemo(() => {
    if (selectedDate && /^\d{4}-\d{2}-\d{2}$/.test(selectedDate)) {
      const [y, m, d] = selectedDate.split('-').map(Number);
      return new Date(y, m - 1, d);
    }
    return new Date();
  }, [selectedDate]);

  const [currentMonthDate, setCurrentMonthDate] = useState<Date>(initialDateObj);
  const [tempDateStr, setTempDateStr] = useState<string>(selectedDate || '');

  React.useEffect(() => {
    if (visible) {
      if (selectedDate && /^\d{4}-\d{2}-\d{2}$/.test(selectedDate)) {
        const [y, m, d] = selectedDate.split('-').map(Number);
        setCurrentMonthDate(new Date(y, m - 1, d));
        setTempDateStr(selectedDate);
      } else {
        const now = new Date();
        setCurrentMonthDate(now);
        const y = now.getFullYear();
        const m = String(now.getMonth() + 1).padStart(2, '0');
        const d = String(now.getDate()).padStart(2, '0');
        setTempDateStr(`${y}-${m}-${d}`);
      }
    }
  }, [visible, selectedDate]);

  const year = currentMonthDate.getFullYear();
  const month = currentMonthDate.getMonth();

  const monthName = currentMonthDate.toLocaleString('default', { month: 'long', year: 'numeric' });

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
    setCurrentMonthDate(new Date(year, month + offset, 1));
  };

  const jumpMonths = (monthsToAdd: number) => {
    const target = new Date();
    target.setMonth(target.getMonth() + monthsToAdd);
    setCurrentMonthDate(target);
    const y = target.getFullYear();
    const m = String(target.getMonth() + 1).padStart(2, '0');
    const d = String(target.getDate()).padStart(2, '0');
    setTempDateStr(`${y}-${m}-${d}`);
  };

  const handleConfirm = () => {
    if (tempDateStr) {
      onSelectDate(tempDateStr);
    }
    onClose();
  };

  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onClose}>
      <Pressable style={styles.backdrop} onPress={onClose}>
        <Pressable
          style={[styles.modalCard, { backgroundColor: theme.surface, borderColor: theme.border }]}
          onPress={(e) => e.stopPropagation()}
        >
          {/* Header */}
          <View style={styles.modalHeader}>
            <View style={styles.modalTitleRow}>
              <CalendarIcon size={20} color={theme.primary} style={{ marginRight: 8 }} />
              <Text style={[styles.modalTitle, { color: theme.text }]}>Choose Expiry Date</Text>
            </View>
            <TouchableOpacity onPress={onClose} style={styles.closeBtn} activeOpacity={0.7}>
              <X size={20} color={theme.textMuted} />
            </TouchableOpacity>
          </View>

          {/* Quick Jump Shortcuts */}
          <View style={styles.shortcutsRow}>
            {[
              { label: '+1 Month', months: 1 },
              { label: '+3 Months', months: 3 },
              { label: '+6 Months', months: 6 },
              { label: '+1 Year', months: 12 },
            ].map((shortcut) => (
              <TouchableOpacity
                key={shortcut.label}
                style={[styles.shortcutChip, { backgroundColor: theme.surfaceSubtle, borderColor: theme.border }]}
                onPress={() => jumpMonths(shortcut.months)}
                activeOpacity={0.7}
              >
                <Text style={[styles.shortcutChipText, { color: theme.primary }]}>
                  {shortcut.label}
                </Text>
              </TouchableOpacity>
            ))}
          </View>

          {/* Month Navigation */}
          <View style={[styles.monthNavRow, { backgroundColor: theme.surfaceSubtle, borderColor: theme.border }]}>
            <TouchableOpacity onPress={() => changeMonth(-1)} style={styles.monthNavBtn} activeOpacity={0.7}>
              <ChevronLeft size={20} color={theme.text} />
            </TouchableOpacity>
            <Text style={[styles.monthNavText, { color: theme.text }]}>{monthName}</Text>
            <TouchableOpacity onPress={() => changeMonth(1)} style={styles.monthNavBtn} activeOpacity={0.7}>
              <ChevronRight size={20} color={theme.text} />
            </TouchableOpacity>
          </View>

          {/* Weekdays */}
          <View style={styles.weekDaysRow}>
            {['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'].map((w) => (
              <Text key={w} style={[styles.weekDayLabel, { color: theme.textMuted }]}>
                {w}
              </Text>
            ))}
          </View>

          {/* Days Grid */}
          <View style={styles.daysGrid}>
            {calendarDays.map((cell, idx) => {
              if (cell.dayNumber === null || !cell.dateString) {
                return <View key={`blank-${idx}`} style={styles.dayCell} />;
              }

              const isSelected = tempDateStr === cell.dateString;

              return (
                <TouchableOpacity
                  key={cell.dateString}
                  style={[
                    styles.dayCell,
                    isSelected && { backgroundColor: theme.primary, borderRadius: 10 },
                  ]}
                  onPress={() => setTempDateStr(cell.dateString!)}
                  activeOpacity={0.7}
                >
                  <Text
                    style={[
                      styles.dayText,
                      { color: isSelected ? '#FFFFFF' : theme.text },
                      isSelected && { fontWeight: '700' },
                    ]}
                  >
                    {cell.dayNumber}
                  </Text>
                </TouchableOpacity>
              );
            })}
          </View>

          {/* Selected Date Preview & Action */}
          <View style={[styles.footerRow, { borderTopColor: theme.border }]}>
            <View>
              <Text style={[styles.footerLabel, { color: theme.textSecondary }]}>Selected Date</Text>
              <Text style={[styles.footerValue, { color: theme.primary }]}>
                {tempDateStr || 'None selected'}
              </Text>
            </View>

            <TouchableOpacity
              style={[styles.confirmBtn, { backgroundColor: theme.primary }]}
              onPress={handleConfirm}
              activeOpacity={0.85}
            >
              <Check size={16} color="#FFFFFF" strokeWidth={2.5} style={{ marginRight: 6 }} />
              <Text style={styles.confirmBtnText}>Set Date</Text>
            </TouchableOpacity>
          </View>
        </Pressable>
      </Pressable>
    </Modal>
  );
};

const styles = StyleSheet.create({
  backdrop: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.55)',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 16,
  },
  modalCard: {
    width: '100%',
    maxWidth: 360,
    borderRadius: 20,
    borderWidth: 1,
    padding: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.15,
    shadowRadius: 12,
    elevation: 8,
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 14,
  },
  modalTitleRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  modalTitle: {
    fontSize: 16,
    fontWeight: '700',
  },
  closeBtn: {
    width: 32,
    height: 32,
    alignItems: 'center',
    justifyContent: 'center',
  },
  shortcutsRow: {
    flexDirection: 'row',
    gap: 6,
    marginBottom: 14,
    flexWrap: 'wrap',
  },
  shortcutChip: {
    paddingHorizontal: 9,
    paddingVertical: 5,
    borderRadius: 8,
    borderWidth: 1,
  },
  shortcutChipText: {
    fontSize: 11,
    fontWeight: '600',
  },
  monthNavRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 8,
    paddingVertical: 8,
    borderRadius: 12,
    borderWidth: 1,
    marginBottom: 10,
  },
  monthNavBtn: {
    width: 32,
    height: 32,
    alignItems: 'center',
    justifyContent: 'center',
  },
  monthNavText: {
    fontSize: 14,
    fontWeight: '700',
  },
  weekDaysRow: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    marginBottom: 8,
  },
  weekDayLabel: {
    width: 36,
    textAlign: 'center',
    fontSize: 12,
    fontWeight: '600',
  },
  daysGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-around',
    rowGap: 4,
    marginBottom: 16,
  },
  dayCell: {
    width: 36,
    height: 36,
    alignItems: 'center',
    justifyContent: 'center',
  },
  dayText: {
    fontSize: 13,
    fontWeight: '500',
  },
  footerRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingTop: 14,
    borderTopWidth: 1,
  },
  footerLabel: {
    fontSize: 11,
    marginBottom: 2,
  },
  footerValue: {
    fontSize: 14,
    fontWeight: '700',
  },
  confirmBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: 10,
  },
  confirmBtnText: {
    color: '#FFFFFF',
    fontSize: 13,
    fontWeight: '700',
  },
});
