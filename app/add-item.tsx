import React, { useState, useMemo } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TextInput,
  TouchableOpacity,
  Alert,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { useRouter } from 'expo-router';
import { useTheme } from '../src/theme';
import { useItemsStore } from '../src/stores/useItemsStore';
import { PRESET_CATEGORIES, NewItemInput } from '../src/types/item';
import { evaluateItemStatus } from '../src/services/statusCalculator';
import { ChevronDown, ChevronUp, Check, Calendar, AlertTriangle } from 'lucide-react-native';

export default function AddItemScreen() {
  const { theme } = useTheme();
  const router = useRouter();
  const addItem = useItemsStore((s) => s.addItem);

  // Required Fields
  const [name, setName] = useState('');
  const [category, setCategory] = useState<string>('Groceries');
  const [customCategory, setCustomCategory] = useState('');
  const [expiryDate, setExpiryDate] = useState<string>(() => {
    // Default to 7 days from now
    const d = new Date();
    d.setDate(d.getDate() + 7);
    return d.toISOString().split('T')[0];
  });

  // Reminder offsets (days before)
  const [reminderOffsets, setReminderOffsets] = useState<number[]>([3]);

  // Optional "Add more details" collapsed section
  const [showMoreDetails, setShowMoreDetails] = useState(false);
  const [quantity, setQuantity] = useState('');
  const [unit, setUnit] = useState('');
  const [location, setLocation] = useState('');
  const [notes, setNotes] = useState('');

  const [isSubmitting, setIsSubmitting] = useState(false);

  // Evaluate if chosen date is already expired
  const evaluation = useMemo(() => {
    if (!expiryDate) return null;
    return evaluateItemStatus(expiryDate);
  }, [expiryDate]);

  // Quick Expiry Date helpers
  const setQuickDate = (daysFromNow: number) => {
    const target = new Date();
    target.setDate(target.getDate() + daysFromNow);
    const y = target.getFullYear();
    const m = String(target.getMonth() + 1).padStart(2, '0');
    const d = String(target.getDate()).padStart(2, '0');
    setExpiryDate(`${y}-${m}-${d}`);
  };

  const toggleReminderOffset = (offset: number) => {
    if (reminderOffsets.includes(offset)) {
      setReminderOffsets(reminderOffsets.filter((o) => o !== offset));
    } else {
      setReminderOffsets([...reminderOffsets, offset].sort((a, b) => b - a));
    }
  };

  const handleSave = async () => {
    if (!name.trim()) {
      Alert.alert('Required Field', 'Please enter an item name.');
      return;
    }

    if (!expiryDate || !/^\d{4}-\d{2}-\d{2}$/.test(expiryDate)) {
      Alert.alert('Invalid Date', 'Please enter a valid expiry date (YYYY-MM-DD).');
      return;
    }

    const finalCategory = category === 'Custom' ? (customCategory.trim() || 'Custom') : category;

    setIsSubmitting(true);
    try {
      const input: NewItemInput = {
        name: name.trim(),
        category: finalCategory,
        expiryDate,
        reminderOffsets,
        quantity: quantity ? parseFloat(quantity) : null,
        unit: unit.trim() || null,
        location: location.trim() || null,
        notes: notes.trim() || null,
      };

      await addItem(input);
      router.back();
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Could not save item';
      Alert.alert('Error', msg);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <KeyboardAvoidingView
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      style={[styles.container, { backgroundColor: theme.background }]}
    >
      <ScrollView contentContainerStyle={styles.scrollContent} keyboardShouldPersistTaps="handled">
        {/* Item Name */}
        <View style={styles.formGroup}>
          <Text style={[styles.label, { color: theme.text }]}>Item Name *</Text>
          <TextInput
            style={[styles.input, { backgroundColor: theme.surface, borderColor: theme.border, color: theme.text }]}
            placeholder="e.g. Organic Whole Milk"
            placeholderTextColor={theme.textMuted}
            value={name}
            onChangeText={setName}
            autoFocus
          />
        </View>

        {/* Category Picker */}
        <View style={styles.formGroup}>
          <Text style={[styles.label, { color: theme.text }]}>Category *</Text>
          <View style={styles.categoryGrid}>
            {PRESET_CATEGORIES.map((cat) => {
              const isSelected = category === cat.name;
              return (
                <TouchableOpacity
                  key={cat.id}
                  style={[
                    styles.categoryChip,
                    isSelected
                      ? { backgroundColor: theme.primary, borderColor: theme.primary }
                      : { backgroundColor: theme.surface, borderColor: theme.border },
                  ]}
                  onPress={() => setCategory(cat.name)}
                >
                  <Text
                    style={[
                      styles.categoryChipText,
                      isSelected ? { color: '#FFFFFF', fontWeight: '600' } : { color: theme.text },
                    ]}
                  >
                    {cat.name}
                  </Text>
                </TouchableOpacity>
              );
            })}
          </View>

          {category === 'Custom' && (
            <TextInput
              style={[
                styles.input,
                {
                  backgroundColor: theme.surface,
                  borderColor: theme.border,
                  color: theme.text,
                  marginTop: 8,
                },
              ]}
              placeholder="Enter custom category name"
              placeholderTextColor={theme.textMuted}
              value={customCategory}
              onChangeText={setCustomCategory}
            />
          )}
        </View>

        {/* Expiry Date */}
        <View style={styles.formGroup}>
          <Text style={[styles.label, { color: theme.text }]}>Expiry Date (YYYY-MM-DD) *</Text>

          {/* Quick Date Chips */}
          <View style={styles.quickChipsRow}>
            {[
              { label: 'Today', offset: 0 },
              { label: 'Tomorrow', offset: 1 },
              { label: '7 Days', offset: 7 },
              { label: '30 Days', offset: 30 },
            ].map((chip) => (
              <TouchableOpacity
                key={chip.label}
                style={[styles.quickChip, { backgroundColor: theme.surfaceSubtle, borderColor: theme.border }]}
                onPress={() => setQuickDate(chip.offset)}
              >
                <Text style={[styles.quickChipText, { color: theme.textSecondary }]}>{chip.label}</Text>
              </TouchableOpacity>
            ))}
          </View>

          <View style={[styles.dateInputRow, { backgroundColor: theme.surface, borderColor: theme.border }]}>
            <Calendar size={18} color={theme.textMuted} />
            <TextInput
              style={[styles.dateInput, { color: theme.text }]}
              value={expiryDate}
              onChangeText={setExpiryDate}
              placeholder="YYYY-MM-DD"
              placeholderTextColor={theme.textMuted}
              maxLength={10}
            />
          </View>

          {evaluation && evaluation.status === 'expired' && (
            <View style={[styles.expiredNotice, { backgroundColor: '#FEE2E2', borderColor: '#FCA5A5' }]}>
              <AlertTriangle size={16} color={theme.danger} />
              <Text style={[styles.expiredNoticeText, { color: theme.danger }]}>
                This date is in the past (already expired).
              </Text>
            </View>
          )}
        </View>

        {/* Reminder Selector */}
        <View style={styles.formGroup}>
          <Text style={[styles.label, { color: theme.text }]}>Reminder Schedule</Text>
          <Text style={[styles.subLabel, { color: theme.textMuted }]}>
            Choose when to get notified before expiry:
          </Text>
          <View style={styles.reminderChipsRow}>
            {[
              { label: '7 days before', value: 7 },
              { label: '3 days before', value: 3 },
              { label: '1 day before', value: 1 },
              { label: 'On expiry day', value: 0 },
            ].map((rem) => {
              const isSelected = reminderOffsets.includes(rem.value);
              return (
                <TouchableOpacity
                  key={rem.value}
                  style={[
                    styles.reminderChip,
                    isSelected
                      ? { backgroundColor: theme.primary, borderColor: theme.primary }
                      : { backgroundColor: theme.surface, borderColor: theme.border },
                  ]}
                  onPress={() => toggleReminderOffset(rem.value)}
                >
                  {isSelected && <Check size={14} color="#FFFFFF" style={{ marginRight: 4 }} />}
                  <Text
                    style={[
                      styles.reminderChipText,
                      isSelected ? { color: '#FFFFFF', fontWeight: '600' } : { color: theme.text },
                    ]}
                  >
                    {rem.label}
                  </Text>
                </TouchableOpacity>
              );
            })}
          </View>
        </View>

        {/* Optional Collapsible Details */}
        <TouchableOpacity
          style={[styles.collapseHeader, { borderColor: theme.border }]}
          onPress={() => setShowMoreDetails(!showMoreDetails)}
        >
          <Text style={[styles.collapseHeaderText, { color: theme.primary }]}>
            {showMoreDetails ? 'Hide additional details' : '+ Add more details (optional)'}
          </Text>
          {showMoreDetails ? (
            <ChevronUp size={18} color={theme.primary} />
          ) : (
            <ChevronDown size={18} color={theme.primary} />
          )}
        </TouchableOpacity>

        {showMoreDetails && (
          <View style={styles.moreDetailsContainer}>
            <View style={styles.rowForm}>
              <View style={[styles.formGroup, { flex: 1, marginRight: 8 }]}>
                <Text style={[styles.label, { color: theme.text }]}>Quantity</Text>
                <TextInput
                  style={[styles.input, { backgroundColor: theme.surface, borderColor: theme.border, color: theme.text }]}
                  placeholder="e.g. 2"
                  placeholderTextColor={theme.textMuted}
                  value={quantity}
                  onChangeText={setQuantity}
                  keyboardType="numeric"
                />
              </View>
              <View style={[styles.formGroup, { flex: 1 }]}>
                <Text style={[styles.label, { color: theme.text }]}>Unit</Text>
                <TextInput
                  style={[styles.input, { backgroundColor: theme.surface, borderColor: theme.border, color: theme.text }]}
                  placeholder="e.g. bottles, lbs"
                  placeholderTextColor={theme.textMuted}
                  value={unit}
                  onChangeText={setUnit}
                />
              </View>
            </View>

            <View style={styles.formGroup}>
              <Text style={[styles.label, { color: theme.text }]}>Storage Location</Text>
              <TextInput
                style={[styles.input, { backgroundColor: theme.surface, borderColor: theme.border, color: theme.text }]}
                placeholder="e.g. Fridge Top Shelf, Bathroom Cabinet"
                placeholderTextColor={theme.textMuted}
                value={location}
                onChangeText={setLocation}
              />
            </View>

            <View style={styles.formGroup}>
              <Text style={[styles.label, { color: theme.text }]}>Notes</Text>
              <TextInput
                style={[
                  styles.input,
                  styles.textArea,
                  { backgroundColor: theme.surface, borderColor: theme.border, color: theme.text },
                ]}
                placeholder="Batch number, unopened vs opened, instructions..."
                placeholderTextColor={theme.textMuted}
                value={notes}
                onChangeText={setNotes}
                multiline
                numberOfLines={3}
              />
            </View>
          </View>
        )}

        {/* Save Button */}
        <TouchableOpacity
          style={[styles.saveButton, { backgroundColor: theme.primary }]}
          onPress={handleSave}
          disabled={isSubmitting}
        >
          <Text style={styles.saveButtonText}>{isSubmitting ? 'Saving...' : 'Save Item'}</Text>
        </TouchableOpacity>
      </ScrollView>
    </KeyboardAvoidingView>
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
  formGroup: {
    marginBottom: 20,
  },
  label: {
    fontSize: 14,
    fontWeight: '600',
    marginBottom: 8,
  },
  subLabel: {
    fontSize: 12,
    marginBottom: 8,
  },
  input: {
    height: 46,
    borderRadius: 8,
    borderWidth: 1,
    paddingHorizontal: 12,
    fontSize: 15,
  },
  textArea: {
    height: 80,
    paddingTop: 10,
    textAlignVertical: 'top',
  },
  categoryGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  categoryChip: {
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 8,
    borderWidth: 1,
  },
  categoryChipText: {
    fontSize: 13,
  },
  quickChipsRow: {
    flexDirection: 'row',
    gap: 8,
    marginBottom: 8,
  },
  quickChip: {
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 8,
    borderWidth: 1,
  },
  quickChipText: {
    fontSize: 12,
  },
  dateInputRow: {
    flexDirection: 'row',
    alignItems: 'center',
    height: 46,
    borderRadius: 8,
    borderWidth: 1,
    paddingHorizontal: 12,
    gap: 10,
  },
  dateInput: {
    flex: 1,
    fontSize: 15,
    height: '100%',
  },
  expiredNotice: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    padding: 10,
    borderRadius: 8,
    borderWidth: 1,
    marginTop: 8,
  },
  expiredNoticeText: {
    fontSize: 12,
    fontWeight: '600',
  },
  reminderChipsRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  reminderChip: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 8,
    borderWidth: 1,
  },
  reminderChipText: {
    fontSize: 13,
  },
  collapseHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 14,
    borderTopWidth: 1,
    borderBottomWidth: 1,
    marginBottom: 16,
  },
  collapseHeaderText: {
    fontSize: 14,
    fontWeight: '600',
  },
  moreDetailsContainer: {
    marginBottom: 16,
  },
  rowForm: {
    flexDirection: 'row',
  },
  saveButton: {
    height: 48,
    borderRadius: 8,
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 12,
  },
  saveButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
  },
});
