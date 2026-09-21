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
  Modal,
  ActivityIndicator,
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
  Calendar,
  AlertCircle,
  Plus,
  Check,
  X,
  Sparkles,
  Search,
} from 'lucide-react-native';
import { CATEGORY_VISUALS, DEFAULT_CATEGORY_VISUAL } from '../src/theme/categoryVisuals';
import { lookupBarcode, SAMPLE_BARCODES } from '../src/services/barcodeService';

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

  const [isBarcodeModalVisible, setIsBarcodeModalVisible] = useState(false);
  const [barcodeInput, setBarcodeInput] = useState('');
  const [isLookingUpBarcode, setIsLookingUpBarcode] = useState(false);

  const [isPhotoModalVisible, setIsPhotoModalVisible] = useState(false);
  const [isOcrProcessing, setIsOcrProcessing] = useState(false);

  const handleScannerPress = (type: 'barcode' | 'camera') => {
    if (type === 'barcode') {
      setIsBarcodeModalVisible(true);
    } else {
      setIsPhotoModalVisible(true);
    }
  };

  const handlePerformBarcodeLookup = async (code: string) => {
    const trimmed = code.trim();
    if (!trimmed) {
      if (Platform.OS === 'web') alert('Please enter a barcode number.');
      else Alert.alert('Required', 'Please enter a barcode number.');
      return;
    }

    setIsLookingUpBarcode(true);
    try {
      const product = await lookupBarcode(trimmed);
      if (product) {
        setName(product.name);
        setCategory(product.category);
        setQuickDate(product.estimatedExpiryDays);
        setIsBarcodeModalVisible(false);
        setBarcodeInput('');
        if (Platform.OS === 'web') {
          alert(`Found "${product.name}"! Auto-filled category & expiry date.`);
        } else {
          Alert.alert('Product Found', `Auto-filled "${product.name}" with estimated expiry in ${product.estimatedExpiryDays} days.`);
        }
      } else {
        if (Platform.OS === 'web') {
          alert('Barcode not found in database. You can type the details manually.');
        } else {
          Alert.alert('Not Found', 'Barcode was not found in the global database. Please enter details manually.');
        }
      }
    } catch {
      if (Platform.OS === 'web') alert('Could not reach barcode database.');
      else Alert.alert('Lookup Error', 'Could not reach the barcode database.');
    } finally {
      setIsLookingUpBarcode(false);
    }
  };

  const handleSimulatePhotoOcr = (sampleName: string, sampleCategory: string, days: number) => {
    setIsOcrProcessing(true);
    setTimeout(() => {
      setName(sampleName);
      setCategory(sampleCategory);
      setQuickDate(days);
      setIsOcrProcessing(false);
      setIsPhotoModalVisible(false);
      if (Platform.OS === 'web') {
        alert(`OCR detected "${sampleName}"! Expiry date set to +${days} days.`);
      } else {
        Alert.alert('OCR Detected', `Photo scan detected "${sampleName}". Expiry date auto-filled!`);
      }
    }, 500);
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

      {/* Barcode Scanner & Lookup Modal */}
      <Modal
        visible={isBarcodeModalVisible}
        transparent
        animationType="fade"
        onRequestClose={() => setIsBarcodeModalVisible(false)}
      >
        <View style={styles.modalOverlay}>
          <View style={[styles.modalCard, { backgroundColor: theme.surface, borderColor: theme.border }]}>
            <View style={styles.modalHeader}>
              <View style={styles.modalTitleRow}>
                <View style={[styles.modalIconBox, { backgroundColor: 'rgba(22, 163, 74, 0.12)' }]}>
                  <Barcode size={22} color={theme.primary} />
                </View>
                <View>
                  <Text style={[styles.modalTitle, { color: theme.text }]}>Scan or Enter Barcode</Text>
                  <Text style={[styles.modalSubtitle, { color: theme.textSecondary }]}>
                    Auto-detects product name & category
                  </Text>
                </View>
              </View>
              <TouchableOpacity onPress={() => setIsBarcodeModalVisible(false)} style={styles.modalCloseBtn}>
                <X size={20} color={theme.textMuted} />
              </TouchableOpacity>
            </View>

            {/* Input & Search */}
            <View style={[styles.modalInputRow, { backgroundColor: theme.surfaceSubtle, borderColor: theme.border }]}>
              <TextInput
                style={[styles.modalTextInput, { color: theme.text }]}
                placeholder="Enter barcode (e.g. 3017620422003)"
                placeholderTextColor={theme.textMuted}
                keyboardType="numeric"
                value={barcodeInput}
                onChangeText={setBarcodeInput}
                onSubmitEditing={() => handlePerformBarcodeLookup(barcodeInput)}
              />
              <TouchableOpacity
                style={[styles.modalSearchBtn, { backgroundColor: theme.primary }]}
                onPress={() => handlePerformBarcodeLookup(barcodeInput)}
                disabled={isLookingUpBarcode}
              >
                {isLookingUpBarcode ? (
                  <ActivityIndicator size="small" color="#FFFFFF" />
                ) : (
                  <Search size={18} color="#FFFFFF" />
                )}
              </TouchableOpacity>
            </View>

            {/* Quick Test Samples */}
            <Text style={[styles.modalSectionLabel, { color: theme.textSecondary }]}>
              Test with Sample Products:
            </Text>
            <View style={styles.sampleGrid}>
              {SAMPLE_BARCODES.map((item) => (
                <TouchableOpacity
                  key={item.code}
                  style={[styles.sampleChip, { backgroundColor: theme.surfaceSubtle, borderColor: theme.border }]}
                  onPress={() => {
                    setBarcodeInput(item.code);
                    handlePerformBarcodeLookup(item.code);
                  }}
                  activeOpacity={0.7}
                >
                  <Text style={styles.sampleChipEmoji}>{item.emoji}</Text>
                  <Text style={[styles.sampleChipLabel, { color: theme.text }]}>{item.label}</Text>
                </TouchableOpacity>
              ))}
            </View>
          </View>
        </View>
      </Modal>

      {/* Photo Recognition & OCR Modal */}
      <Modal
        visible={isPhotoModalVisible}
        transparent
        animationType="fade"
        onRequestClose={() => setIsPhotoModalVisible(false)}
      >
        <View style={styles.modalOverlay}>
          <View style={[styles.modalCard, { backgroundColor: theme.surface, borderColor: theme.border }]}>
            <View style={styles.modalHeader}>
              <View style={styles.modalTitleRow}>
                <View style={[styles.modalIconBox, { backgroundColor: 'rgba(16, 185, 129, 0.12)' }]}>
                  <Camera size={22} color="#10B981" />
                </View>
                <View>
                  <Text style={[styles.modalTitle, { color: theme.text }]}>Photo & Expiry OCR</Text>
                  <Text style={[styles.modalSubtitle, { color: theme.textSecondary }]}>
                    Scan packet printed expiry date
                  </Text>
                </View>
              </View>
              <TouchableOpacity onPress={() => setIsPhotoModalVisible(false)} style={styles.modalCloseBtn}>
                <X size={20} color={theme.textMuted} />
              </TouchableOpacity>
            </View>

            {/* Simulation Preview Card */}
            <View style={[styles.ocrDemoBox, { backgroundColor: theme.surfaceSubtle, borderColor: theme.border }]}>
              <Sparkles size={24} color={theme.primary} />
              <Text style={[styles.ocrDemoTitle, { color: theme.text }]}>
                Optical Character Recognition
              </Text>
              <Text style={[styles.ocrDemoText, { color: theme.textSecondary }]}>
                Reads stamped "EXP / USE BY / BEST BEFORE" dates on food & medicine packaging.
              </Text>
            </View>

            {/* Quick Demo OCR Samples */}
            <Text style={[styles.modalSectionLabel, { color: theme.textSecondary }]}>
              Try Instant OCR Detection:
            </Text>
            <View style={styles.ocrSamplesCol}>
              {[
                { name: 'Fresh Milk 500ml', cat: 'dairy', days: 3, emoji: '🥛', text: 'EXP: 24/09/2026' },
                { name: 'Brown Bread', cat: 'groceries', days: 5, emoji: '🍞', text: 'USE BY: 26/09/2026' },
                { name: 'Paracetamol 500mg', cat: 'medicine', days: 365, emoji: '💊', text: 'EXP: 09/2027' },
                { name: 'Sunscreen SPF 50', cat: 'skincare', days: 180, emoji: '🧴', text: 'BEST BEFORE: 03/2027' },
              ].map((sample) => (
                <TouchableOpacity
                  key={sample.name}
                  style={[styles.ocrSampleCard, { backgroundColor: theme.surfaceSubtle, borderColor: theme.border }]}
                  onPress={() => handleSimulatePhotoOcr(sample.name, sample.cat, sample.days)}
                  activeOpacity={0.7}
                  disabled={isOcrProcessing}
                >
                  <Text style={styles.sampleChipEmoji}>{sample.emoji}</Text>
                  <View style={styles.ocrSampleInfo}>
                    <Text style={[styles.ocrSampleName, { color: theme.text }]}>{sample.name}</Text>
                    <Text style={[styles.ocrSampleText, { color: theme.primary }]}>{sample.text}</Text>
                  </View>
                  <ChevronRight size={16} color={theme.textMuted} />
                </TouchableOpacity>
              ))}
            </View>
          </View>
        </View>
      </Modal>
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
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.55)',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 20,
  },
  modalCard: {
    width: '100%',
    maxWidth: 420,
    borderRadius: 24,
    borderWidth: 1,
    padding: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.15,
    shadowRadius: 20,
    elevation: 5,
  },
  modalHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 16,
  },
  modalTitleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  modalIconBox: {
    width: 42,
    height: 42,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  modalTitle: {
    fontSize: 17,
    fontWeight: '800',
  },
  modalSubtitle: {
    fontSize: 12,
    marginTop: 1,
  },
  modalCloseBtn: {
    padding: 6,
  },
  modalInputRow: {
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: 14,
    borderWidth: 1,
    paddingHorizontal: 12,
    height: 48,
    marginBottom: 16,
  },
  modalTextInput: {
    flex: 1,
    fontSize: 15,
    height: '100%',
  },
  modalSearchBtn: {
    width: 36,
    height: 36,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
  },
  modalSectionLabel: {
    fontSize: 12,
    fontWeight: '700',
    textTransform: 'uppercase',
    letterSpacing: 0.5,
    marginBottom: 10,
  },
  sampleGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  sampleChip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 12,
    borderWidth: 1,
  },
  sampleChipEmoji: {
    fontSize: 16,
  },
  sampleChipLabel: {
    fontSize: 13,
    fontWeight: '600',
  },
  ocrDemoBox: {
    alignItems: 'center',
    justifyContent: 'center',
    padding: 16,
    borderRadius: 16,
    borderWidth: 1,
    marginBottom: 16,
    textAlign: 'center',
  },
  ocrDemoTitle: {
    fontSize: 15,
    fontWeight: '700',
    marginTop: 8,
    marginBottom: 4,
  },
  ocrDemoText: {
    fontSize: 12,
    textAlign: 'center',
    lineHeight: 16,
  },
  ocrSamplesCol: {
    gap: 8,
  },
  ocrSampleCard: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 12,
    borderRadius: 14,
    borderWidth: 1,
    gap: 12,
  },
  ocrSampleInfo: {
    flex: 1,
  },
  ocrSampleName: {
    fontSize: 14,
    fontWeight: '700',
    marginBottom: 2,
  },
  ocrSampleText: {
    fontSize: 12,
    fontWeight: '600',
  },
});
