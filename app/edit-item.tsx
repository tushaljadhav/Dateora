import React, { useState, useMemo, useEffect } from 'react';
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
  Image,
  ActivityIndicator,
} from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { useTheme } from '../src/theme';
import { useItemsStore } from '../src/stores/useItemsStore';
import { useSettingsStore } from '../src/stores/useSettingsStore';
import { evaluateItemStatus } from '../src/services/statusCalculator';
import {
  ArrowLeft,
  Calendar,
  AlertCircle,
  Check,
  Tag,
  MapPin,
  Package,
  FileText,
  Bell,
  Camera,
  Image as ImageIcon,
  Trash2,
  Sparkles,
} from 'lucide-react-native';
import { CATEGORY_VISUALS, DEFAULT_CATEGORY_VISUAL } from '../src/theme/categoryVisuals';
import { DatePickerModal } from '../src/components/DatePickerModal';
import { pickImageFromCamera, pickImageFromGallery } from '../src/services/imagePickerService';
import { analyzeProductImageWithGemini } from '../src/services/aiVisionService';

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

export default function EditItemScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { theme, isDark } = useTheme();
  const router = useRouter();

  const items = useItemsStore((s) => s.items);
  const historyItems = useItemsStore((s) => s.historyItems);
  const updateItem = useItemsStore((s) => s.updateItem);
  const dailyNotificationTime = useSettingsStore((s) => s.dailyNotificationTime);

  const existingItem = useMemo(() => {
    return items.find((i) => i.id === id) || historyItems.find((i) => i.id === id);
  }, [items, historyItems, id]);

  const [name, setName] = useState('');
  const [category, setCategory] = useState<string>('groceries');
  const [expiryDate, setExpiryDate] = useState<string>('');
  const [reminderOffsets, setReminderOffsets] = useState<number[]>([3, 1]);
  const [quantity, setQuantity] = useState('');
  const [unit, setUnit] = useState('');
  const [location, setLocation] = useState('');
  const [notes, setNotes] = useState('');
  const [photoUri, setPhotoUri] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isCalendarModalVisible, setIsCalendarModalVisible] = useState(false);

  useEffect(() => {
    if (existingItem) {
      setName(existingItem.name);
      setCategory(existingItem.category);
      setExpiryDate(existingItem.expiryDate);
      setPhotoUri(existingItem.photoUri || null);
      setReminderOffsets(existingItem.reminderOffsets || [3, 1]);
      setQuantity(existingItem.quantity !== null && existingItem.quantity !== undefined ? String(existingItem.quantity) : '');
      setUnit(existingItem.unit || '');
      setLocation(existingItem.location || '');
      setNotes(existingItem.notes || '');
    }
  }, [existingItem]);

  const geminiApiKey = useSettingsStore((s) => s.geminiApiKey);
  const [isAiScanning, setIsAiScanning] = useState(false);

  const handleScanWithAi = async (uriToScan?: string) => {
    const targetUri = uriToScan || photoUri;
    if (!targetUri) {
      Alert.alert('No Photo', 'Please take or choose a photo first.');
      return;
    }

    if (!geminiApiKey || !geminiApiKey.trim()) {
      if (Platform.OS === 'web') {
        const go = window.confirm(
          'Gemini API Key Required: Would you like to go to Settings to add your free Google Gemini API key?'
        );
        if (go) router.push('/(tabs)/settings');
      } else {
        Alert.alert(
          'Gemini API Key Required',
          'Please configure your 100% free Gemini API key in Settings to use the AI Vision Scanner.',
          [
            { text: 'Cancel', style: 'cancel' },
            {
              text: 'Open Settings',
              onPress: () => router.push('/(tabs)/settings'),
            },
          ]
        );
      }
      return;
    }

    setIsAiScanning(true);
    try {
      const result = await analyzeProductImageWithGemini(targetUri, geminiApiKey);
      setName(result.name);
      setCategory(result.category);
      setExpiryDate(result.expiryDate);
      if (result.quantity) setQuantity(String(result.quantity));
      if (result.unit) setUnit(result.unit);
      if (result.location) setLocation(result.location);
      if (result.notes) {
        setNotes((prev) => (prev ? `${prev} • ${result.notes}` : result.notes || ''));
      }

      if (Platform.OS === 'web') {
        alert(`✨ AI Detected!\nItem: ${result.name}\nExpiry Date: ${result.expiryDate}`);
      } else {
        Alert.alert(
          '✨ AI Auto-Filled!',
          `Product: ${result.name}\nCategory: ${result.category}\nExpiry: ${result.expiryDate}${result.notes ? `\n\nNotes: ${result.notes}` : ''}`
        );
      }
    } catch (err: any) {
      const msg = err?.message || 'Could not analyze image with AI';
      Alert.alert('AI Scan Failed', msg);
    } finally {
      setIsAiScanning(false);
    }
  };

  const handleCaptureCamera = async () => {
    try {
      const uri = await pickImageFromCamera();
      if (uri) {
        setPhotoUri(uri);
        if (geminiApiKey && geminiApiKey.trim()) {
          handleScanWithAi(uri);
        }
      }
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Could not access camera';
      Alert.alert('Camera Error', msg);
    }
  };

  const handlePickGallery = async () => {
    try {
      const uri = await pickImageFromGallery();
      if (uri) {
        setPhotoUri(uri);
        if (geminiApiKey && geminiApiKey.trim()) {
          handleScanWithAi(uri);
        }
      }
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Could not access photo library';
      Alert.alert('Gallery Error', msg);
    }
  };

  const evaluation = useMemo(() => {
    if (!expiryDate || !/^\d{4}-\d{2}-\d{2}$/.test(expiryDate)) return null;
    return evaluateItemStatus(expiryDate);
  }, [expiryDate]);

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

  if (!existingItem) {
    return (
      <View style={[styles.centerContainer, { backgroundColor: theme.background }]}>
        <Text style={[styles.notFoundText, { color: theme.textSecondary }]}>
          Item not found.
        </Text>
        <TouchableOpacity
          style={[styles.backButton, { backgroundColor: theme.primary }]}
          onPress={() => router.back()}
        >
          <Text style={styles.backButtonText}>Return</Text>
        </TouchableOpacity>
      </View>
    );
  }

  const handleSave = async () => {
    if (!name.trim()) {
      if (Platform.OS === 'web') alert('Please enter an item name.');
      else Alert.alert('Required', 'Please enter an item name.');
      return;
    }

    if (!expiryDate || !/^\d{4}-\d{2}-\d{2}$/.test(expiryDate)) {
      if (Platform.OS === 'web') alert('Please enter a valid expiry date (YYYY-MM-DD).');
      else Alert.alert('Invalid Date', 'Please enter a valid expiry date (YYYY-MM-DD).');
      return;
    }

    setIsSubmitting(true);
    try {
      await updateItem(
        {
          id: existingItem.id,
          name: name.trim(),
          category,
          expiryDate,
          photoUri: photoUri || null,
          reminderOffsets,
          quantity: quantity ? parseFloat(quantity) : null,
          unit: unit.trim() || null,
          location: location.trim() || null,
          notes: notes.trim() || null,
        },
        dailyNotificationTime
      );

      if (Platform.OS === 'web') {
        router.back();
      } else {
        router.back();
      }
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Could not update item.';
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
      {/* Header Bar */}
      <View style={[styles.headerBar, { backgroundColor: theme.surface, borderBottomColor: theme.border }]}>
        <TouchableOpacity style={styles.backBtn} onPress={() => router.back()} activeOpacity={0.7}>
          <ArrowLeft size={22} color={theme.text} />
        </TouchableOpacity>
        <Text style={[styles.headerTitle, { color: theme.text }]}>Edit Item</Text>
        <TouchableOpacity
          style={[styles.saveHeaderBtn, { backgroundColor: theme.primary }]}
          onPress={handleSave}
          disabled={isSubmitting}
          activeOpacity={0.8}
        >
          <Text style={styles.saveHeaderBtnText}>{isSubmitting ? 'Saving...' : 'Save'}</Text>
        </TouchableOpacity>
      </View>

      <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
        {/* Category Grid */}
        <Text style={[styles.sectionHeading, { color: theme.text }]}>Category</Text>
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
          {/* Photo Section */}
          {photoUri ? (
            <View style={[styles.photoPreviewCard, { backgroundColor: theme.surfaceSubtle, borderColor: theme.border }]}>
              <Image source={{ uri: photoUri }} style={styles.photoPreviewImg} />
              <View style={styles.photoPreviewInfo}>
                <Text style={[styles.photoPreviewTitle, { color: theme.text }]}>Item Photo</Text>
                <TouchableOpacity
                  style={[styles.aiAutoFillBadgeBtn, { backgroundColor: theme.primary }]}
                  onPress={() => handleScanWithAi(photoUri)}
                  disabled={isAiScanning}
                  activeOpacity={0.8}
                >
                  {isAiScanning ? (
                    <ActivityIndicator size="small" color="#FFFFFF" />
                  ) : (
                    <>
                      <Sparkles size={11} color="#FFFFFF" />
                      <Text style={styles.aiAutoFillBadgeText}>AI Re-Scan</Text>
                    </>
                  )}
                </TouchableOpacity>
              </View>
              <TouchableOpacity
                style={[styles.photoBtnSmall, { backgroundColor: theme.surface, borderColor: theme.border }]}
                onPress={handlePickGallery}
                activeOpacity={0.7}
              >
                <Text style={[styles.photoBtnSmallText, { color: theme.primary }]}>Change</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.photoRemoveBtn, { backgroundColor: 'rgba(239, 68, 68, 0.12)' }]}
                onPress={() => setPhotoUri(null)}
                activeOpacity={0.7}
              >
                <Trash2 size={16} color={theme.danger} />
              </TouchableOpacity>
            </View>
          ) : (
            <View style={styles.photoButtonsRow}>
              <TouchableOpacity
                style={[styles.photoAddBtn, { backgroundColor: theme.surfaceSubtle, borderColor: theme.border }]}
                onPress={handleCaptureCamera}
                activeOpacity={0.7}
              >
                <Camera size={16} color={theme.primary} />
                <Text style={[styles.photoAddBtnText, { color: theme.text }]}>Take Photo</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.photoAddBtn, { backgroundColor: theme.surfaceSubtle, borderColor: theme.border }]}
                onPress={handlePickGallery}
                activeOpacity={0.7}
              >
                <ImageIcon size={16} color={theme.primary} />
                <Text style={[styles.photoAddBtnText, { color: theme.text }]}>From Gallery</Text>
              </TouchableOpacity>
            </View>
          )}

          {/* Item Name */}
          <View style={styles.fieldGroup}>
            <Text style={[styles.inputLabel, { color: theme.text }]}>Item Name *</Text>
            <TextInput
              style={[
                styles.textInput,
                { backgroundColor: theme.surfaceSubtle, borderColor: theme.border, color: theme.text },
              ]}
              placeholder="e.g. Paracetamol, Milk"
              placeholderTextColor={theme.textMuted}
              value={name}
              onChangeText={setName}
            />
          </View>

          {/* Expiry Date */}
          <View style={styles.fieldGroup}>
            <View style={styles.labelRowBetween}>
              <Text style={[styles.inputLabel, { color: theme.text }]}>Expiry Date (YYYY-MM-DD) *</Text>
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
                      : `${evaluation.daysLeft} days remaining`}
                  </Text>
                </View>
              )}
            </View>

            <View style={styles.dateInputRow}>
              <TextInput
                style={[
                  styles.textInput,
                  { backgroundColor: theme.surfaceSubtle, borderColor: theme.border, color: theme.text, flex: 1 },
                ]}
                placeholder="YYYY-MM-DD"
                placeholderTextColor={theme.textMuted}
                value={expiryDate}
                onChangeText={setExpiryDate}
              />
              <TouchableOpacity
                style={[
                  styles.calendarPickerBtn,
                  { backgroundColor: theme.surfaceSubtle, borderColor: theme.border },
                ]}
                onPress={() => setIsCalendarModalVisible(true)}
                activeOpacity={0.7}
                accessibilityLabel="Choose date from calendar"
              >
                <Calendar size={18} color={theme.primary} />
              </TouchableOpacity>
            </View>

            <DatePickerModal
              visible={isCalendarModalVisible}
              selectedDate={expiryDate}
              onClose={() => setIsCalendarModalVisible(false)}
              onSelectDate={(date) => setExpiryDate(date)}
            />

            {/* Quick Presets */}
            <View style={styles.quickChipsWrap}>
              {[
                { label: 'Today', days: 0, emoji: '⚡' },
                { label: '+3 days', days: 3, emoji: '📅' },
                { label: '+7 days', days: 7, emoji: '🗓️' },
                { label: '+30 days', days: 30, emoji: '📦' },
                { label: '+60 days', days: 60, emoji: '⏳' },
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

          {/* Reminder Offsets */}
          <View style={styles.fieldGroup}>
            <Text style={[styles.inputLabel, { color: theme.text }]}>Reminder Alerts</Text>
            <Text style={[styles.helperText, { color: theme.textSecondary }]}>
              Notify me before expiry:
            </Text>
            <View style={styles.reminderChipsRow}>
              {[
                { offset: 7, label: '7 days before' },
                { offset: 3, label: '3 days before' },
                { offset: 1, label: '1 day before' },
                { offset: 0, label: 'On expiry day' },
              ].map(({ offset, label }) => {
                const isSelected = reminderOffsets.includes(offset);
                return (
                  <TouchableOpacity
                    key={offset}
                    style={[
                      styles.reminderChip,
                      isSelected
                        ? { backgroundColor: theme.primary, borderColor: theme.primary }
                        : { backgroundColor: theme.surfaceSubtle, borderColor: theme.border },
                    ]}
                    onPress={() => toggleReminderOffset(offset)}
                    activeOpacity={0.7}
                  >
                    {isSelected && <Check size={14} color="#FFFFFF" strokeWidth={2.5} style={{ marginRight: 4 }} />}
                    <Text
                      style={[
                        styles.reminderChipText,
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

          {/* Quantity and Unit */}
          <View style={styles.twoColRow}>
            <View style={[styles.fieldGroup, { flex: 1, marginRight: 8 }]}>
              <Text style={[styles.inputLabel, { color: theme.text }]}>Quantity</Text>
              <TextInput
                style={[
                  styles.textInput,
                  { backgroundColor: theme.surfaceSubtle, borderColor: theme.border, color: theme.text },
                ]}
                placeholder="e.g. 2"
                placeholderTextColor={theme.textMuted}
                keyboardType="numeric"
                value={quantity}
                onChangeText={setQuantity}
              />
            </View>
            <View style={[styles.fieldGroup, { flex: 1, marginLeft: 8 }]}>
              <Text style={[styles.inputLabel, { color: theme.text }]}>Unit</Text>
              <TextInput
                style={[
                  styles.textInput,
                  { backgroundColor: theme.surfaceSubtle, borderColor: theme.border, color: theme.text },
                ]}
                placeholder="bottles, kg, pcs"
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
              placeholder="e.g. Fridge Top Shelf, Medicine Box, Pantry"
              placeholderTextColor={theme.textMuted}
              value={location}
              onChangeText={setLocation}
            />
          </View>

          {/* Notes */}
          <View style={styles.fieldGroup}>
            <Text style={[styles.inputLabel, { color: theme.text }]}>Notes</Text>
            <TextInput
              style={[
                styles.textArea,
                { backgroundColor: theme.surfaceSubtle, borderColor: theme.border, color: theme.text },
              ]}
              placeholder="Optional notes or batch details..."
              placeholderTextColor={theme.textMuted}
              multiline
              numberOfLines={3}
              value={notes}
              onChangeText={setNotes}
            />
          </View>
        </View>

        {/* Primary Save Button */}
        <TouchableOpacity
          style={[styles.saveButton, { backgroundColor: theme.primary }]}
          onPress={handleSave}
          disabled={isSubmitting}
          activeOpacity={0.88}
        >
          <Check size={18} color="#FFFFFF" strokeWidth={2.5} style={{ marginRight: 8 }} />
          <Text style={styles.saveButtonText}>{isSubmitting ? 'Saving Changes...' : 'Save Changes'}</Text>
        </TouchableOpacity>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  centerContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 24,
  },
  notFoundText: {
    fontSize: 16,
    marginBottom: 16,
  },
  backButton: {
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 12,
  },
  backButtonText: {
    color: '#FFFFFF',
    fontWeight: '700',
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
  saveHeaderBtn: {
    paddingHorizontal: 14,
    paddingVertical: 7,
    borderRadius: 10,
  },
  saveHeaderBtnText: {
    color: '#FFFFFF',
    fontWeight: '700',
    fontSize: 14,
  },
  scrollContent: {
    padding: 16,
    paddingBottom: 48,
  },
  sectionHeading: {
    fontSize: 15,
    fontWeight: '700',
    marginBottom: 12,
    letterSpacing: -0.2,
  },
  categoryGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
    marginBottom: 20,
  },
  categoryTile: {
    width: '23%',
    minWidth: 74,
    borderRadius: 14,
    borderWidth: 1,
    paddingVertical: 10,
    paddingHorizontal: 6,
    alignItems: 'center',
    justifyContent: 'center',
  },
  categoryTileIcon: {
    width: 36,
    height: 36,
    borderRadius: 10,
    borderWidth: 1,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 6,
  },
  categoryTileEmoji: {
    fontSize: 18,
  },
  categoryTileLabel: {
    fontSize: 11,
    fontWeight: '600',
    textAlign: 'center',
  },
  formCard: {
    borderRadius: 18,
    borderWidth: 1,
    padding: 16,
    marginBottom: 20,
  },
  fieldGroup: {
    marginBottom: 16,
  },
  labelRowBetween: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 6,
  },
  inputLabel: {
    fontSize: 13,
    fontWeight: '600',
    marginBottom: 6,
  },
  helperText: {
    fontSize: 12,
    marginBottom: 8,
  },
  textInput: {
    height: 46,
    borderRadius: 12,
    borderWidth: 1,
    paddingHorizontal: 14,
    fontSize: 15,
  },
  dateInputRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  calendarPickerBtn: {
    width: 46,
    height: 46,
    borderRadius: 12,
    borderWidth: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  textArea: {
    minHeight: 80,
    borderRadius: 12,
    borderWidth: 1,
    paddingHorizontal: 14,
    paddingVertical: 10,
    fontSize: 14,
    textAlignVertical: 'top',
  },
  twoColRow: {
    flexDirection: 'row',
  },
  evaluationPillBox: {
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 8,
  },
  evaluationPill: {
    fontSize: 11,
    fontWeight: '700',
  },
  quickChipsWrap: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 6,
    marginTop: 10,
  },
  quickChip: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 8,
    borderWidth: 1,
  },
  quickChipEmoji: {
    fontSize: 12,
    marginRight: 4,
  },
  quickChipText: {
    fontSize: 12,
    fontWeight: '500',
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
    borderRadius: 10,
    borderWidth: 1,
  },
  reminderChipText: {
    fontSize: 12,
    fontWeight: '600',
  },
  saveButton: {
    height: 50,
    borderRadius: 14,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 24,
  },
  saveButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '700',
  },
  photoSection: {
    marginBottom: 6,
  },
  photoPreviewCard: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 10,
    borderRadius: 14,
    borderWidth: 1,
    gap: 12,
  },
  photoPreviewImg: {
    width: 52,
    height: 52,
    borderRadius: 10,
  },
  photoPreviewInfo: {
    flex: 1,
  },
  photoPreviewTitle: {
    fontSize: 14,
    fontWeight: '700',
    marginBottom: 4,
  },
  aiAutoFillBadgeBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 7,
    alignSelf: 'flex-start',
  },
  aiAutoFillBadgeText: {
    color: '#FFFFFF',
    fontSize: 10,
    fontWeight: '700',
  },
  photoPreviewSubtitle: {
    fontSize: 12,
  },
  photoBtnSmall: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 8,
    borderWidth: 1,
  },
  photoBtnSmallText: {
    fontSize: 12,
    fontWeight: '700',
  },
  photoRemoveBtn: {
    width: 36,
    height: 36,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
  },
  photoButtonsRow: {
    flexDirection: 'row',
    gap: 10,
  },
  photoAddBtn: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    height: 44,
    borderRadius: 12,
    borderWidth: 1,
    gap: 8,
  },
  photoAddBtnText: {
    fontSize: 13,
    fontWeight: '600',
  },
});
