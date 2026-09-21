import React, { useState, useRef } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Switch,
  Alert,
  Platform,
  Modal,
  ActivityIndicator,
} from 'react-native';
import { useTheme, ThemePreference } from '../../src/theme';
import { useSettingsStore } from '../../src/stores/useSettingsStore';
import { useItemsStore } from '../../src/stores/useItemsStore';
import { getDatabase } from '../../src/db/client';
import { items, notificationRecords } from '../../src/db/schema';
import {
  exportDataToFile,
  inspectImportJson,
  commitImport,
  ImportPreview,
} from '../../src/services/exportService';
import {
  Moon,
  Sun,
  Monitor,
  Bell,
  Clock,
  Database,
  Shield,
  Trash2,
  Download,
  Upload,
  CheckCircle2,
  AlertTriangle,
  X,
  FileJson,
} from 'lucide-react-native';

const TIME_PRESETS = ['07:00', '08:00', '09:00', '10:00', '12:00', '18:00', '20:00'];
const OFFSET_OPTIONS = [
  { value: 0, label: 'Day of (0d)' },
  { value: 1, label: '1 day before' },
  { value: 3, label: '3 days before' },
  { value: 7, label: '7 days before' },
];

export default function SettingsScreen() {
  const { theme, preference, setPreference } = useTheme();

  const notificationsEnabled = useSettingsStore((s) => s.notificationsEnabled);
  const setNotificationsEnabled = useSettingsStore((s) => s.setNotificationsEnabled);

  const dailyNotificationTime = useSettingsStore((s) => s.dailyNotificationTime);
  const setDailyNotificationTime = useSettingsStore((s) => s.setDailyNotificationTime);

  const expiringSoonWindowDays = useSettingsStore((s) => s.expiringSoonWindowDays);
  const setExpiringSoonWindowDays = useSettingsStore((s) => s.setExpiringSoonWindowDays);

  const defaultReminderOffsets = useSettingsStore((s) => s.defaultReminderOffsets);
  const setDefaultReminderOffsets = useSettingsStore((s) => s.setDefaultReminderOffsets);

  const loadItems = useItemsStore((s) => s.loadItems);
  const loadHistory = useItemsStore((s) => s.loadHistory);

  // State for import workflow
  const [importPreview, setImportPreview] = useState<ImportPreview | null>(null);
  const [isImportModalVisible, setIsImportModalVisible] = useState(false);
  const [isImporting, setIsImporting] = useState(false);
  const [exporting, setExporting] = useState(false);
  const [showTimePicker, setShowTimePicker] = useState(false);

  const fileInputRef = useRef<any>(null);

  const handleExport = async () => {
    try {
      setExporting(true);
      const res = await exportDataToFile();
      if (Platform.OS === 'web') {
        alert(`Backup downloaded successfully as ${res.filename}`);
      }
    } catch (err: any) {
      Alert.alert('Export Failed', err?.message || 'Could not export data.');
    } finally {
      setExporting(false);
    }
  };

  const handlePickImportFile = async () => {
    if (Platform.OS === 'web') {
      if (fileInputRef.current) {
        fileInputRef.current.value = '';
        fileInputRef.current.click();
      }
      return;
    }

    try {
      const DocumentPicker = require('expo-document-picker');
      const FileSystem = require('expo-file-system');

      const result = await DocumentPicker.getDocumentAsync({
        type: 'application/json',
        copyToCacheDirectory: true,
      });

      if (!result.canceled && result.assets && result.assets.length > 0) {
        const fileUri = result.assets[0].uri;
        const fileContent = await FileSystem.readAsStringAsync(fileUri);
        processRawImport(fileContent);
      }
    } catch (err: any) {
      Alert.alert('File Picker Error', err?.message || 'Failed to select file');
    }
  };

  const handleWebFileSelected = (e: any) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = (event) => {
      const content = event.target?.result as string;
      if (content) {
        processRawImport(content);
      }
    };
    reader.readAsText(file);
  };

  const processRawImport = async (rawJson: string) => {
    const preview = await inspectImportJson(rawJson);
    if (!preview.isValid) {
      Alert.alert('Invalid Backup File', preview.error || 'The file could not be parsed.');
      return;
    }
    setImportPreview(preview);
    setIsImportModalVisible(true);
  };

  const handleConfirmImport = async (overwrite: boolean) => {
    if (!importPreview) return;
    try {
      setIsImporting(true);
      const res = await commitImport(importPreview, overwrite);
      await loadItems();
      await loadHistory();
      setIsImportModalVisible(false);
      setImportPreview(null);

      const msg = `Import complete: ${res.added} items added, ${res.updated} updated, ${res.skipped} skipped.`;
      if (Platform.OS === 'web') {
        alert(msg);
      } else {
        Alert.alert('Import Successful', msg);
      }
    } catch (err: any) {
      Alert.alert('Import Failed', err?.message || 'Failed to apply imported items.');
    } finally {
      setIsImporting(false);
    }
  };

  const handleToggleOffset = (offset: number) => {
    const current = [...defaultReminderOffsets];
    const idx = current.indexOf(offset);
    if (idx >= 0) {
      if (current.length > 1) {
        current.splice(idx, 1);
        setDefaultReminderOffsets(current);
      }
    } else {
      current.push(offset);
      current.sort((a, b) => b - a);
      setDefaultReminderOffsets(current);
    }
  };

  const handleClearAllData = () => {
    const performClear = async () => {
      const { db } = getDatabase();
      if (db) {
        await db.delete(notificationRecords);
        await db.delete(items);
      } else if (typeof window !== 'undefined' && window.localStorage) {
        window.localStorage.removeItem('dateora_items_data');
      }
      await loadItems();
      await loadHistory();
      if (Platform.OS === 'web') {
        alert('All items have been erased.');
      } else {
        Alert.alert('Data Cleared', 'All items have been removed.');
      }
    };

    if (Platform.OS === 'web') {
      const step1 = window.confirm('Delete all tracked items, reminders, and history permanently?');
      if (step1) {
        const step2 = window.confirm('Are you absolutely sure? This action CANNOT be undone.');
        if (step2) {
          performClear();
        }
      }
      return;
    }

    Alert.alert(
      'Delete All Data?',
      'This will delete all tracked items, reminders, and history permanently. This action cannot be undone.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete Everything',
          style: 'destructive',
          onPress: () => {
            Alert.alert(
              'Are you absolutely sure?',
              'Confirm once more to erase all Dateora data.',
              [
                { text: 'Cancel', style: 'cancel' },
                {
                  text: 'Confirm Erasure',
                  style: 'destructive',
                  onPress: performClear,
                },
              ]
            );
          },
        },
      ]
    );
  };

  const themeOptions: Array<{ id: ThemePreference; label: string; icon: any }> = [
    { id: 'dark', label: 'Dark', icon: Moon },
    { id: 'light', label: 'Light', icon: Sun },
    { id: 'system', label: 'System', icon: Monitor },
  ];

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      {/* Hidden Web File Input for JSON import */}
      {Platform.OS === 'web' && (
        <input
          type="file"
          ref={fileInputRef}
          accept=".json,application/json"
          style={{ display: 'none' }}
          onChange={handleWebFileSelected}
        />
      )}

      <ScrollView contentContainerStyle={styles.scrollContent}>
        {/* Appearance Section */}
        <Text style={[styles.sectionHeading, { color: theme.textMuted }]}>APPEARANCE</Text>
        <View style={[styles.card, { backgroundColor: theme.surface, borderColor: theme.border }]}>
          <Text style={[styles.cardTitle, { color: theme.text }]}>Color Theme</Text>
          <View style={styles.themeRow}>
            {themeOptions.map((opt) => {
              const isSelected = preference === opt.id;
              const IconComp = opt.icon;
              return (
                <TouchableOpacity
                  key={opt.id}
                  style={[
                    styles.themeOption,
                    isSelected
                      ? {
                          backgroundColor: 'rgba(59, 130, 246, 0.2)',
                          borderColor: theme.primary,
                        }
                      : { backgroundColor: theme.surfaceSubtle, borderColor: theme.border },
                  ]}
                  onPress={() => setPreference(opt.id)}
                >
                  <IconComp size={16} color={isSelected ? theme.primary : theme.text} />
                  <Text
                    style={[
                      styles.themeOptionText,
                      { color: isSelected ? theme.primary : theme.text },
                      isSelected && { fontWeight: '700' },
                    ]}
                  >
                    {opt.label}
                  </Text>
                </TouchableOpacity>
              );
            })}
          </View>
        </View>

        {/* Notifications Section */}
        <Text style={[styles.sectionHeading, { color: theme.textMuted }]}>REMINDERS & NOTIFICATIONS</Text>
        <View style={[styles.card, { backgroundColor: theme.surface, borderColor: theme.border }]}>
          <View style={styles.rowBetween}>
            <View style={styles.rowLabel}>
              <Bell size={18} color={theme.primary} />
              <View>
                <Text style={[styles.labelTitle, { color: theme.text }]}>Enable Reminders</Text>
                <Text style={[styles.labelSubtitle, { color: theme.textMuted }]}>
                  Schedule offline alerts on this device
                </Text>
              </View>
            </View>
            <Switch
              value={notificationsEnabled}
              onValueChange={setNotificationsEnabled}
              trackColor={{ false: theme.border, true: theme.primary }}
            />
          </View>

          <View style={[styles.divider, { backgroundColor: theme.border }]} />

          {/* Daily Alert Time */}
          <View style={styles.rowBetween}>
            <View style={styles.rowLabel}>
              <Clock size={18} color={theme.primary} />
              <View>
                <Text style={[styles.labelTitle, { color: theme.text }]}>Daily Alert Time</Text>
                <Text style={[styles.labelSubtitle, { color: theme.textMuted }]}>
                  When morning notifications arrive
                </Text>
              </View>
            </View>
            <TouchableOpacity
              style={[
                styles.timeBadge,
                { backgroundColor: 'rgba(59, 130, 246, 0.15)', borderColor: 'rgba(59, 130, 246, 0.3)' },
              ]}
              onPress={() => setShowTimePicker(!showTimePicker)}
            >
              <Text style={[styles.timeBadgeText, { color: theme.primary }]}>{dailyNotificationTime}</Text>
            </TouchableOpacity>
          </View>

          {/* Time Picker Chips Dropdown */}
          {showTimePicker && (
            <View style={[styles.timePickerContainer, { backgroundColor: theme.surfaceSubtle, borderColor: theme.border }]}>
              <Text style={[styles.pickerHint, { color: theme.textMuted }]}>Select preferred morning time:</Text>
              <View style={styles.chipsWrap}>
                {TIME_PRESETS.map((time) => {
                  const isSelected = dailyNotificationTime === time;
                  return (
                    <TouchableOpacity
                      key={time}
                      style={[
                        styles.chip,
                        isSelected
                          ? { backgroundColor: theme.primary, borderColor: theme.primary }
                          : { backgroundColor: theme.surface, borderColor: theme.border },
                      ]}
                      onPress={() => {
                        setDailyNotificationTime(time);
                        setShowTimePicker(false);
                      }}
                    >
                      <Text
                        style={[
                          styles.chipText,
                          { color: isSelected ? '#FFFFFF' : theme.text },
                          isSelected && { fontWeight: '700' },
                        ]}
                      >
                        {time}
                      </Text>
                    </TouchableOpacity>
                  );
                })}
              </View>
            </View>
          )}

          <View style={[styles.divider, { backgroundColor: theme.border }]} />

          {/* Expiring Soon Window */}
          <View style={styles.rowBetween}>
            <View>
              <Text style={[styles.labelTitle, { color: theme.text }]}>Expiring Soon Threshold</Text>
              <Text style={[styles.labelSubtitle, { color: theme.textMuted }]}>
                Items turn amber when within this window
              </Text>
            </View>
            <View style={styles.chipsRow}>
              {[3, 7, 14].map((days) => {
                const isSelected = expiringSoonWindowDays === days;
                return (
                  <TouchableOpacity
                    key={days}
                    style={[
                      styles.chip,
                      isSelected
                        ? { backgroundColor: theme.primary, borderColor: theme.primary }
                        : { backgroundColor: theme.surfaceSubtle, borderColor: theme.border },
                    ]}
                    onPress={() => setExpiringSoonWindowDays(days)}
                  >
                    <Text
                      style={[
                        styles.chipText,
                        { color: isSelected ? '#FFFFFF' : theme.text },
                        isSelected && { fontWeight: '700' },
                      ]}
                    >
                      {days}d
                    </Text>
                  </TouchableOpacity>
                );
              })}
            </View>
          </View>

          <View style={[styles.divider, { backgroundColor: theme.border }]} />

          {/* Default Reminder Offsets */}
          <View>
            <Text style={[styles.labelTitle, { color: theme.text, marginBottom: 4 }]}>
              Default Reminder Triggers
            </Text>
            <Text style={[styles.labelSubtitle, { color: theme.textMuted, marginBottom: 10 }]}>
              Pre-selected alert intervals for new items
            </Text>
            <View style={styles.chipsWrap}>
              {OFFSET_OPTIONS.map((opt) => {
                const isSelected = defaultReminderOffsets.includes(opt.value);
                return (
                  <TouchableOpacity
                    key={opt.value}
                    style={[
                      styles.chip,
                      isSelected
                        ? { backgroundColor: 'rgba(59, 130, 246, 0.2)', borderColor: theme.primary }
                        : { backgroundColor: theme.surfaceSubtle, borderColor: theme.border },
                    ]}
                    onPress={() => handleToggleOffset(opt.value)}
                  >
                    <Text
                      style={[
                        styles.chipText,
                        { color: isSelected ? theme.primary : theme.textSecondary },
                        isSelected && { fontWeight: '600' },
                      ]}
                    >
                      {opt.label}
                    </Text>
                  </TouchableOpacity>
                );
              })}
            </View>
          </View>
        </View>

        {/* Data Portability (Phase 5) */}
        <Text style={[styles.sectionHeading, { color: theme.textMuted }]}>BACKUP & DATA PORTABILITY</Text>
        <View style={[styles.card, { backgroundColor: theme.surface, borderColor: theme.border }]}>
          <Text style={[styles.cardTitle, { color: theme.text }]}>Local Data Management</Text>
          <Text style={[styles.labelSubtitle, { color: theme.textMuted, marginBottom: 14 }]}>
            Export your items and history to a portable JSON backup file, or restore from an earlier backup.
          </Text>

          <View style={styles.portabilityButtonsRow}>
            <TouchableOpacity
              style={[
                styles.portabilityBtn,
                { backgroundColor: 'rgba(59, 130, 246, 0.15)', borderColor: 'rgba(59, 130, 246, 0.4)' },
              ]}
              onPress={handleExport}
              disabled={exporting}
            >
              {exporting ? (
                <ActivityIndicator size="small" color={theme.primary} />
              ) : (
                <>
                  <Download size={18} color={theme.primary} />
                  <Text style={[styles.portabilityBtnText, { color: theme.primary }]}>Export Backup</Text>
                </>
              )}
            </TouchableOpacity>

            <TouchableOpacity
              style={[
                styles.portabilityBtn,
                { backgroundColor: 'rgba(6, 182, 212, 0.15)', borderColor: 'rgba(6, 182, 212, 0.4)' },
              ]}
              onPress={handlePickImportFile}
            >
              <Upload size={18} color="#22D3EE" />
              <Text style={[styles.portabilityBtnText, { color: '#22D3EE' }]}>Import Backup</Text>
            </TouchableOpacity>
          </View>
        </View>

        {/* Data & Privacy */}
        <Text style={[styles.sectionHeading, { color: theme.textMuted }]}>PRIVACY & RESET</Text>
        <View style={[styles.card, { backgroundColor: theme.surface, borderColor: theme.border }]}>
          <View style={styles.privacyBanner}>
            <Shield size={20} color={theme.success} />
            <Text style={[styles.privacyText, { color: theme.textSecondary }]}>
              100% Offline & Private. No accounts, no trackers, no external cloud syncing. All data lives on this device.
            </Text>
          </View>

          <View style={[styles.divider, { backgroundColor: theme.border }]} />

          <TouchableOpacity style={styles.rowBetween} onPress={handleClearAllData}>
            <View style={styles.rowLabel}>
              <Trash2 size={18} color={theme.danger} />
              <Text style={[styles.labelTitle, { color: theme.danger }]}>Delete All Data</Text>
            </View>
            <View
              style={[
                styles.dangerBadge,
                { backgroundColor: 'rgba(239, 68, 68, 0.15)', borderColor: 'rgba(239, 68, 68, 0.3)' },
              ]}
            >
              <Text style={[styles.dangerBadgeText, { color: theme.danger }]}>Erase</Text>
            </View>
          </TouchableOpacity>
        </View>

        {/* About Dateora */}
        <Text style={[styles.sectionHeading, { color: theme.textMuted }]}>ABOUT</Text>
        <View style={[styles.card, { backgroundColor: theme.surface, borderColor: theme.border }]}>
          <View style={styles.rowBetween}>
            <Text style={[styles.labelTitle, { color: theme.text }]}>Version</Text>
            <Text style={[styles.valueText, { color: theme.textMuted }]}>1.0.0 (GoTall Dark Edition)</Text>
          </View>
          <View style={[styles.divider, { backgroundColor: theme.border }]} />
          <View style={styles.rowBetween}>
            <Text style={[styles.labelTitle, { color: theme.text }]}>Architecture</Text>
            <Text style={[styles.valueText, { color: theme.primary }]}>Offline SQLite + Local Storage</Text>
          </View>
        </View>
      </ScrollView>

      {/* Import Diff Inspection Modal */}
      <Modal
        visible={isImportModalVisible}
        transparent
        animationType="fade"
        onRequestClose={() => setIsImportModalVisible(false)}
      >
        <View style={styles.modalOverlay}>
          <View style={[styles.modalContent, { backgroundColor: theme.surface, borderColor: theme.border }]}>
            <View style={styles.modalHeader}>
              <View style={styles.modalHeaderTitleRow}>
                <FileJson size={22} color={theme.primary} />
                <Text style={[styles.modalTitle, { color: theme.text }]}>Inspect Backup File</Text>
              </View>
              <TouchableOpacity onPress={() => setIsImportModalVisible(false)}>
                <X size={20} color={theme.textMuted} />
              </TouchableOpacity>
            </View>

            {importPreview && (
              <View style={styles.modalBody}>
                <Text style={[styles.diffSubtitle, { color: theme.textSecondary }]}>
                  Found {importPreview.totalInFile} item(s) in this Dateora backup.
                </Text>

                <View style={[styles.diffStatCard, { backgroundColor: theme.surfaceSubtle, borderColor: theme.border }]}>
                  <View style={styles.diffStatRow}>
                    <CheckCircle2 size={18} color="#34D399" />
                    <Text style={[styles.diffStatText, { color: theme.text }]}>
                      <Text style={{ fontWeight: '700', color: '#34D399' }}>{importPreview.newItemsCount}</Text> new
                      items will be added
                    </Text>
                  </View>

                  {importPreview.conflictItemsCount > 0 && (
                    <View style={styles.diffStatRow}>
                      <AlertTriangle size={18} color="#FBBF24" />
                      <Text style={[styles.diffStatText, { color: theme.text }]}>
                        <Text style={{ fontWeight: '700', color: '#FBBF24' }}>
                          {importPreview.conflictItemsCount}
                        </Text>{' '}
                        items already exist (conflicts)
                      </Text>
                    </View>
                  )}
                </View>

                <Text style={[styles.actionPrompt, { color: theme.textMuted }]}>
                  Choose how to handle existing items:
                </Text>

                <View style={styles.modalActions}>
                  <TouchableOpacity
                    style={[styles.modalActionBtn, { backgroundColor: theme.primary }]}
                    onPress={() => handleConfirmImport(false)}
                    disabled={isImporting}
                  >
                    {isImporting ? (
                      <ActivityIndicator size="small" color="#FFFFFF" />
                    ) : (
                      <Text style={styles.modalActionBtnText}>
                        Merge (Keep existing, add {importPreview.newItemsCount})
                      </Text>
                    )}
                  </TouchableOpacity>

                  {importPreview.conflictItemsCount > 0 && (
                    <TouchableOpacity
                      style={[
                        styles.modalActionBtnSecondary,
                        { borderColor: 'rgba(239, 68, 68, 0.4)', backgroundColor: 'rgba(239, 68, 68, 0.12)' },
                      ]}
                      onPress={() => handleConfirmImport(true)}
                      disabled={isImporting}
                    >
                      <Text style={[styles.modalActionBtnSecondaryText, { color: '#F87171' }]}>
                        Overwrite Existing Items ({importPreview.conflictItemsCount})
                      </Text>
                    </TouchableOpacity>
                  )}

                  <TouchableOpacity
                    style={[styles.modalCancelBtn, { borderColor: theme.border }]}
                    onPress={() => setIsImportModalVisible(false)}
                    disabled={isImporting}
                  >
                    <Text style={[styles.modalCancelText, { color: theme.textMuted }]}>Cancel</Text>
                  </TouchableOpacity>
                </View>
              </View>
            )}
          </View>
        </View>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  scrollContent: {
    padding: 16,
    paddingBottom: 48,
  },
  sectionHeading: {
    fontSize: 12,
    fontWeight: '700',
    letterSpacing: 0.8,
    marginBottom: 8,
    marginTop: 14,
    paddingHorizontal: 4,
  },
  card: {
    borderRadius: 14,
    borderWidth: 1,
    padding: 16,
    marginBottom: 16,
  },
  cardTitle: {
    fontSize: 15,
    fontWeight: '600',
    marginBottom: 12,
  },
  themeRow: {
    flexDirection: 'row',
    gap: 8,
  },
  themeOption: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 10,
    borderRadius: 10,
    borderWidth: 1,
    gap: 6,
  },
  themeOptionText: {
    fontSize: 13,
  },
  rowBetween: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 4,
  },
  rowLabel: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    flex: 1,
  },
  labelTitle: {
    fontSize: 15,
    fontWeight: '500',
  },
  labelSubtitle: {
    fontSize: 12,
    marginTop: 2,
  },
  valueText: {
    fontSize: 14,
  },
  divider: {
    height: StyleSheet.hairlineWidth,
    marginVertical: 14,
  },
  timeBadge: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 8,
    borderWidth: 1,
  },
  timeBadgeText: {
    fontSize: 14,
    fontWeight: '600',
  },
  timePickerContainer: {
    marginTop: 10,
    padding: 12,
    borderRadius: 10,
    borderWidth: 1,
  },
  pickerHint: {
    fontSize: 12,
    marginBottom: 8,
  },
  chipsRow: {
    flexDirection: 'row',
    gap: 6,
  },
  chipsWrap: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  chip: {
    paddingHorizontal: 12,
    paddingVertical: 7,
    borderRadius: 8,
    borderWidth: 1,
  },
  chipText: {
    fontSize: 13,
  },
  portabilityButtonsRow: {
    flexDirection: 'row',
    gap: 10,
    marginTop: 6,
  },
  portabilityBtn: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 12,
    borderRadius: 10,
    borderWidth: 1,
    gap: 8,
  },
  portabilityBtnText: {
    fontSize: 14,
    fontWeight: '600',
  },
  privacyBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    paddingVertical: 4,
  },
  privacyText: {
    fontSize: 13,
    flex: 1,
    lineHeight: 18,
  },
  dangerBadge: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 8,
    borderWidth: 1,
  },
  dangerBadgeText: {
    fontSize: 13,
    fontWeight: '600',
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.7)',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
  modalContent: {
    width: '100%',
    maxWidth: 420,
    borderRadius: 16,
    borderWidth: 1,
    padding: 20,
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  modalHeaderTitleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  modalTitle: {
    fontSize: 17,
    fontWeight: '700',
  },
  modalBody: {
    gap: 12,
  },
  diffSubtitle: {
    fontSize: 14,
    lineHeight: 20,
  },
  diffStatCard: {
    padding: 12,
    borderRadius: 10,
    borderWidth: 1,
    gap: 8,
    marginVertical: 4,
  },
  diffStatRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  diffStatText: {
    fontSize: 13,
  },
  actionPrompt: {
    fontSize: 12,
    marginTop: 4,
  },
  modalActions: {
    gap: 8,
    marginTop: 8,
  },
  modalActionBtn: {
    paddingVertical: 12,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
  },
  modalActionBtnText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '600',
  },
  modalActionBtnSecondary: {
    paddingVertical: 11,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
  },
  modalActionBtnSecondaryText: {
    fontSize: 13,
    fontWeight: '600',
  },
  modalCancelBtn: {
    paddingVertical: 10,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    marginTop: 2,
  },
  modalCancelText: {
    fontSize: 13,
  },
});
