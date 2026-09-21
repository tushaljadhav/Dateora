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
import {
  ArrowLeft,
  Barcode,
  Camera,
  ChevronRight,
  Milk,
  Pill,
  Sparkle,
  Home,
  Coffee,
  HelpCircle,
  Calendar,
  AlertCircle,
  Plus,
  Check,
} from 'lucide-react-native';
import { CATEGORY_VISUALS, DEFAULT_CATEGORY_VISUAL } from '../src/theme/categoryVisuals';

const CATEGORY_TILES = [
  CATEGORY_VISUALS.groceries,
  CATEGORY_VISUALS.dairy,
  CATEGORY_VISUALS.medicine,
  CATEGORY_VISUALS.skincare,
  CATEGORY_VISUALS.beverages,
  CATEGORY_VISUALS.household,
  CATEGORY_VISUALS.pantry,
  DEFAULT_CATEGORY_VISUAL,
];

export default function AddItemScreen() {
  const { theme, isDark } = useTheme();
  const router = useRouter();
  const addItem = useItemsStore((s) => s.addItem);

  // Form Fields
  const [name, setName] = useState('');
  const [category, setCategory] = useState<string>('groceries');
  const [expiryDate, setExpiryDate] = useState<string>(() => {
    const d = new Date();
    d.setDate(d.getDate() + 7);
    return d.toISOString().split('T')[0];
  });

  const [reminderOffsets, setReminderOffsets] = useState<number[]>([3, 1]);
  const [quantity, setQuantity] = useState('');
  const [unit, setUnit] = useState('');
  const [location, setLocation] = useState('');
  const [notes, setNotes] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Evaluate chosen date
  const evaluation = useMemo(() => {
    if (!expiryDate) return null;
    return evaluateItemStatus(expiryDate);
  }, [expiryDate]);

  // Quick Date presets
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
      if (reminderOffsets.length > 1) {
        setReminderOffsets(reminderOffsets.filter((o) => o !== offset));
      }
    } else {
      setReminderOffsets([...reminderOffsets, offset].sort((a, b) => b - a));
    }
  };

  const handleScannerPress = (type: 'barcode' | 'camera') => {
    const label = type === 'barcode' ? 'Barcode scanner' : 'Photo recognition';
    if (Platform.OS === 'web') {
      alert(`${label} is configured for the Android mobile release. You can enter the details manually below.`);
    } else {
      Alert.alert(label, 'Automated camera scanner is ready for device build. Enter details below for fast manual add.');
    }
  };

  const handleSave = async () => {
    if (!name.trim()) {
      Alert.alert('Required', 'Please enter an item name.');
      return;
    }

    if (!expiryDate || !/^\d{4}-\d{2}-\d{2}$/.test(expiryDate)) {
      Alert.alert('Invalid Date', 'Please enter a valid expiry date (YYYY-MM-DD).');
      return;
    }

    setIsSubmitting(true);
    try {
      const input: NewItemInput = {
        name: name.trim(),
        category,
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
      const message = err instanceof Error ? err.message : 'Could not save item.';
      Alert.alert('Error', message);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <KeyboardAvoidingView
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      style={[styles.container, { backgroundColor: theme.background }]}
    >
      {/* Top App Header */}
      <View style={[styles.headerBar, { backgroundColor: theme.surface, borderBottomColor: theme.border }]}>
        <TouchableOpacity style={styles.backBtn} onPress={() => router.back()} activeOpacity={0.7}>
          <ArrowLeft size={22} color={theme.text} />
        </TouchableOpacity>
        <Text style={[styles.headerTitle, { color: theme.text }]}>Add Item</Text>
        <View style={styles.headerRightPlaceholder} />
      </View>

      <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
        {/* Quick Action Cards: Barcode & Camera */}
        <View style={styles.quickActionsContainer}>
          <TouchableOpacity
            style={[styles.quickCard, { backgroundColor: theme.surface, borderColor: theme.border }]}
            onPress={() => handleScannerPress('barcode')}
            activeOpacity={0.7}
          >
            <View style={[styles.quickIconCircle, { backgroundColor: 'rgba(22, 163, 74, 0.12)' }]}>
              <Barcode size={22} color={theme.primary} />
            </View>
            <View style={styles.quickTextCol}>
              <Text style={[styles.quickTitle, { color: theme.text }]}>Scan Barcode</Text>
              <Text style={[styles.quickSubtitle, { color: theme.textSecondary }]}>Scan product barcode</Text>
            </View>
            <ChevronRight size={18} color={theme.textMuted} />
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.quickCard, { backgroundColor: theme.surface, borderColor: theme.border }]}
            onPress={() => handleScannerPress('camera')}
            activeOpacity={0.7}
          >
            <View style={[styles.quickIconCircle, { backgroundColor: 'rgba(16, 185, 129, 0.12)' }]}>
              <Camera size={22} color="#10B981" />
            </View>
            <View style={styles.quickTextCol}>
              <Text style={[styles.quickTitle, { color: theme.text }]}>Take Photo</Text>
              <Text style={[styles.quickSubtitle, { color: theme.textSecondary }]}>Use camera to identify</Text>
            </View>
            <ChevronRight size={18} color={theme.textMuted} />
          </TouchableOpacity>
        </View>

        {/* Divider OR */}
        <View style={styles.dividerRow}>
          <View style={[styles.dividerLine, { backgroundColor: theme.border }]} />
          <Text style={[styles.dividerText, { color: theme.textMuted }]}>OR ADD MANUALLY</Text>
          <View style={[styles.dividerLine, { backgroundColor: theme.border }]} />
        </View>

        {/* Category Grid Tiles */}
        <Text style={[styles.sectionHeading, { color: theme.text }]}>Select Category</Text>
        <View style={styles.categoryGrid}>
          {CATEGORY_TILES.map((cat) => {
            const isSelected = category.toLowerCase() === cat.id.toLowerCase();
            const bgColor = isSelected
              ? (isDark ? cat.bgColorDark : cat.bgColorLight)
              : theme.surface;
            const borderColor = isSelected
              ? theme.primary
              : (isDark ? cat.borderColorDark : theme.border);

            return (
              <TouchableOpacity
                key={cat.id}
                style={[
                  styles.categoryTile,
                  {
                    backgroundColor: bgColor,
                    borderColor: borderColor,
                  },
                ]}
                onPress={() => setCategory(cat.id)}
                activeOpacity={0.7}
              >
                <View
                  style={[
                    styles.categoryTileIcon,
                    {
                      backgroundColor: isDark ? cat.bgColorDark : cat.bgColorLight,
                      borderColor: isDark ? cat.borderColorDark : cat.borderColorLight,
                    },
                  ]}
                >
                  <Text style={styles.categoryTileEmoji}>{cat.emoji}</Text>
                </View>
                <Text
                  style={[
                    styles.categoryTileLabel,
                    { color: isSelected ? theme.primary : theme.text },
                    isSelected && { fontWeight: '700' },
                  ]}
                  numberOfLines={1}
                >
                  {cat.name}
                </Text>
              </TouchableOpacity>
            );
          })}
        </View>

        {/* Form Fields Card */}
        <View style={[styles.formCard, { backgroundColor: theme.surface, borderColor: theme.border }]}>
          {/* Item Name */}
          <View style={styles.fieldGroup}>
            <Text style={[styles.inputLabel, { color: theme.text }]}>Item Name *</Text>
            <TextInput
              style={[styles.textInput, { backgroundColor: theme.surfaceSubtle, borderColor: theme.border, color: theme.text }]}
              placeholder="e.g., Whole Milk, Paracetamol, Eye Cream"
              placeholderTextColor={theme.textMuted}
              value={name}
              onChangeText={setName}
            />
          </View>

          {/* Expiry Date */}
          <View style={styles.fieldGroup}>
            <View style={styles.labelRowBetween}>
              <Text style={[styles.inputLabel, { color: theme.text }]}>Expiry Date *</Text>
              {evaluation && (
                <View
                  style={[
                    styles.evaluationPillBox,
                    {
                      backgroundColor:
                        evaluation.status === 'expired'
                          ? '#FEE2E2'
                          : evaluation.status === 'expiring_soon'
                          ? '#FEF3C7'
                          : '#DCFCE7',
                    },
                  ]}
                >
                  <Text
                    style={[
                      styles.evaluationPill,
                      {
                        color:
                          evaluation.status === 'expired'
                            ? '#DC2626'
                            : evaluation.status === 'expiring_soon'
                            ? '#D97706'
                            : '#15803D',
                      },
                    ]}
                  >
                    {evaluation.status === 'expired'
                      ? 'Expired'
                      : evaluation.daysLeft === 0
                      ? 'Expires today'
                      : `Safe — ${evaluation.daysLeft} days remaining`}
                  </Text>
                </View>
              )}
            </View>

            <TextInput
              style={[
                styles.textInput,
                { backgroundColor: theme.surfaceSubtle, borderColor: theme.border, color: theme.text },
              ]}
              placeholder="YYYY-MM-DD"
              placeholderTextColor={theme.textMuted}
              value={expiryDate}
              onChangeText={setExpiryDate}
            />

            {/* Quick Presets matching reference board */}
            <View style={styles.quickChipsWrap}>
              {[
                { label: 'Today', days: 0, emoji: '⚡' },
                { label: '+3 days', days: 3, emoji: '📅' },
                { label: '+7 days', days: 7, emoji: '🗓️' },
                { label: '+30 days', days: 30, emoji: '📦' },
              ].map((preset) => {
                const target = new Date();
                target.setDate(target.getDate() + preset.days);
                const targetStr = `${target.getFullYear()}-${String(target.getMonth() + 1).padStart(2, '0')}-${String(target.getDate()).padStart(2, '0')}`;
                const isSelected = expiryDate === targetStr;

                return (
                  <TouchableOpacity
                    key={preset.label}
                    style={[
                      styles.quickChip,
                      isSelected
                        ? { backgroundColor: theme.primary, borderColor: theme.primary }
                        : { backgroundColor: theme.surfaceSubtle, borderColor: theme.border },
                    ]}
                    onPress={() => setQuickDate(preset.days)}
                    activeOpacity={0.7}
                  >
                    <Text style={styles.quickChipEmoji}>{preset.emoji}</Text>
                    <Text
                      style={[
                        styles.quickChipText,
                        { color: isSelected ? '#FFFFFF' : theme.textSecondary },
                        isSelected && { fontWeight: '700' },
                      ]}
                    >
                      {preset.label}
                    </Text>
                  </TouchableOpacity>
                );
              })}
            </View>
          </View>

          {/* Quantity & Unit */}
          <View style={styles.twoColRow}>
            <View style={[styles.fieldGroup, { flex: 1 }]}>
              <Text style={[styles.inputLabel, { color: theme.text }]}>Quantity</Text>
              <TextInput
                style={[
                  styles.textInput,
                  { backgroundColor: theme.surfaceSubtle, borderColor: theme.border, color: theme.text },
                ]}
                placeholder="e.g. 1"
                placeholderTextColor={theme.textMuted}
                keyboardType="numeric"
                value={quantity}
                onChangeText={setQuantity}
              />
            </View>

            <View style={[styles.fieldGroup, { flex: 1 }]}>
              <Text style={[styles.inputLabel, { color: theme.text }]}>Unit</Text>
              <TextInput
                style={[
                  styles.textInput,
                  { backgroundColor: theme.surfaceSubtle, borderColor: theme.border, color: theme.text },
                ]}
                placeholder="carton, L, pcs"
                placeholderTextColor={theme.textMuted}
                value={unit}
                onChangeText={setUnit}
              />
            </View>
          </View>

          {/* Storage Location */}
          <View style={styles.fieldGroup}>
            <Text style={[styles.inputLabel, { color: theme.text }]}>Storage Location</Text>
            <TextInput
              style={[
                styles.textInput,
                { backgroundColor: theme.surfaceSubtle, borderColor: theme.border, color: theme.text },
              ]}
              placeholder="e.g. Fridge, Top Pantry, Bathroom Cabinet"
              placeholderTextColor={theme.textMuted}
              value={location}
              onChangeText={setLocation}
            />

            {/* Quick Location Chips */}
            <View style={[styles.quickChipsWrap, { marginTop: 8 }]}>
              {[
                { label: 'Fridge', emoji: '❄️' },
                { label: 'Freezer', emoji: '🧊' },
                { label: 'Pantry', emoji: '🧺' },
                { label: 'Medicine Box', emoji: '💊' },
                { label: 'Bathroom', emoji: '🧴' },
              ].map((loc) => {
                const isSelected = location === loc.label;
                return (
                  <TouchableOpacity
                    key={loc.label}
                    style={[
                      styles.quickChip,
                      isSelected
                        ? { backgroundColor: theme.primary, borderColor: theme.primary }
                        : { backgroundColor: theme.surfaceSubtle, borderColor: theme.border },
                    ]}
                    onPress={() => setLocation(isSelected ? '' : loc.label)}
                    activeOpacity={0.7}
                  >
                    <Text style={styles.quickChipEmoji}>{loc.emoji}</Text>
                    <Text
                      style={[
                        styles.quickChipText,
                        { color: isSelected ? '#FFFFFF' : theme.textSecondary },
                        isSelected && { fontWeight: '700' },
                      ]}
                    >
                      {loc.label}
                    </Text>
                  </TouchableOpacity>
                );
              })}
            </View>
          </View>

          {/* Reminder Trigger Offsets */}
          <View style={styles.fieldGroup}>
            <Text style={[styles.inputLabel, { color: theme.text }]}>Remind Me</Text>
            <View style={styles.reminderOffsetsRow}>
              {[
                { offset: 0, label: 'Day of' },
                { offset: 1, label: '1d before' },
                { offset: 3, label: '3d before' },
                { offset: 7, label: '7d before' },
              ].map(({ offset, label }) => {
                const isSelected = reminderOffsets.includes(offset);
                return (
                  <TouchableOpacity
                    key={offset}
                    style={[
                      styles.offsetChip,
                      isSelected
                        ? { backgroundColor: theme.primary, borderColor: theme.primary }
                        : { backgroundColor: theme.surfaceSubtle, borderColor: theme.border },
                    ]}
                    onPress={() => toggleReminderOffset(offset)}
                    activeOpacity={0.7}
                  >
                    <Text
                      style={[
                        styles.offsetChipText,
                        { color: isSelected ? '#FFFFFF' : theme.textSecondary },
                        isSelected && { fontWeight: '700' },
                      ]}
                    >
                      {label}
                    </Text>
                  </TouchableOpacity>
                );
              })}
            </View>
          </View>

          {/* Notes */}
          <View style={styles.fieldGroup}>
            <Text style={[styles.inputLabel, { color: theme.text }]}>Notes (Optional)</Text>
            <TextInput
              style={[
                styles.notesInput,
                { backgroundColor: theme.surfaceSubtle, borderColor: theme.border, color: theme.text },
              ]}
              placeholder="Batch number, opened date, or notes..."
              placeholderTextColor={theme.textMuted}
              multiline
              numberOfLines={3}
              value={notes}
              onChangeText={setNotes}
            />
          </View>
        </View>

        {/* Save Button */}
        <TouchableOpacity
          style={[styles.saveButton, { backgroundColor: theme.primary }]}
          onPress={handleSave}
          disabled={isSubmitting}
          activeOpacity={0.85}
        >
          <Check size={20} color="#FFFFFF" strokeWidth={2.5} />
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
  headerBar: {
    height: 56,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    borderBottomWidth: 1,
  },
  backBtn: {
    width: 40,
    height: 40,
    alignItems: 'center',
    justifyContent: 'center',
  },
  headerTitle: {
    fontSize: 17,
    fontWeight: '700',
  },
  headerRightPlaceholder: {
    width: 40,
  },
  scrollContent: {
    padding: 16,
    paddingBottom: 48,
  },
  quickActionsContainer: {
    gap: 10,
    marginBottom: 16,
  },
  quickCard: {
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: 16,
    borderWidth: 1,
    padding: 14,
  },
  quickIconCircle: {
    width: 42,
    height: 42,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 14,
  },
  quickTextCol: {
    flex: 1,
  },
  quickTitle: {
    fontSize: 15,
    fontWeight: '700',
    marginBottom: 2,
  },
  quickSubtitle: {
    fontSize: 12,
  },
  dividerRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    marginVertical: 12,
  },
  dividerLine: {
    flex: 1,
    height: StyleSheet.hairlineWidth,
  },
  dividerText: {
    fontSize: 11,
    fontWeight: '700',
    letterSpacing: 0.6,
  },
  sectionHeading: {
    fontSize: 16,
    fontWeight: '700',
    marginBottom: 12,
    marginTop: 4,
  },
  categoryGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
    marginBottom: 16,
  },
  categoryTile: {
    width: '23%',
    borderRadius: 14,
    borderWidth: 1,
    paddingVertical: 12,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
  },
  categoryTileIcon: {
    width: 38,
    height: 38,
    borderRadius: 12,
    borderWidth: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  categoryTileEmoji: {
    fontSize: 18,
  },
  categoryTileLabel: {
    fontSize: 11,
    fontWeight: '600',
    textAlign: 'center',
  },
  quickChipEmoji: {
    fontSize: 12,
  },
  formCard: {
    borderRadius: 16,
    borderWidth: 1,
    padding: 16,
    gap: 16,
    marginBottom: 20,
  },
  fieldGroup: {
    gap: 6,
  },
  twoColRow: {
    flexDirection: 'row',
    gap: 12,
  },
  labelRowBetween: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  inputLabel: {
    fontSize: 14,
    fontWeight: '600',
  },
  evaluationPillBox: {
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 9999,
  },
  evaluationPill: {
    fontSize: 11,
    fontWeight: '700',
  },
  textInput: {
    height: 48,
    borderRadius: 12,
    borderWidth: 1,
    paddingHorizontal: 14,
    fontSize: 15,
  },
  notesInput: {
    minHeight: 80,
    borderRadius: 12,
    borderWidth: 1,
    padding: 12,
    fontSize: 14,
    textAlignVertical: 'top',
  },
  quickChipsWrap: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 6,
    marginTop: 6,
  },
  quickChip: {
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 8,
    borderWidth: 1,
  },
  quickChipText: {
    fontSize: 12,
    fontWeight: '500',
  },
  reminderOffsetsRow: {
    flexDirection: 'row',
    gap: 8,
  },
  offsetChip: {
    flex: 1,
    paddingVertical: 9,
    borderRadius: 10,
    borderWidth: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  offsetChipText: {
    fontSize: 12,
  },
  saveButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    height: 52,
    borderRadius: 14,
    gap: 8,
    shadowColor: '#16A34A',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.25,
    shadowRadius: 10,
    elevation: 3,
  },
  saveButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '700',
  },
});
