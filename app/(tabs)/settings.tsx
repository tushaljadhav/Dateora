import React from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, Switch, Alert } from 'react-native';
import { useTheme, ThemePreference } from '../../src/theme';
import { useSettingsStore } from '../../src/stores/useSettingsStore';
import { useItemsStore } from '../../src/stores/useItemsStore';
import { getDatabase } from '../../src/db/client';
import { items, notificationRecords, appSettingsTable } from '../../src/db/schema';
import { Moon, Sun, Monitor, Bell, Clock, Database, Shield, Info, Trash2, ArrowUpRight } from 'lucide-react-native';

export default function SettingsScreen() {
  const { theme, preference, setPreference } = useTheme();

  const notificationsEnabled = useSettingsStore((s) => s.notificationsEnabled);
  const setNotificationsEnabled = useSettingsStore((s) => s.setNotificationsEnabled);

  const dailyNotificationTime = useSettingsStore((s) => s.dailyNotificationTime);
  const setDailyNotificationTime = useSettingsStore((s) => s.setDailyNotificationTime);

  const expiringSoonWindowDays = useSettingsStore((s) => s.expiringSoonWindowDays);
  const setExpiringSoonWindowDays = useSettingsStore((s) => s.setExpiringSoonWindowDays);

  const loadItems = useItemsStore((s) => s.loadItems);
  const loadHistory = useItemsStore((s) => s.loadHistory);

  const handleClearAllData = () => {
    Alert.alert(
      'Delete All Data?',
      'This will delete all tracked items, reminders, and history permanently. This action cannot be undone.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete Everything',
          style: 'destructive',
          onPress: () => {
            // Double confirmation per PRD §4.7
            Alert.alert(
              'Are you absolutely sure?',
              'Confirm once more to erase all Dateora data.',
              [
                { text: 'Cancel', style: 'cancel' },
                {
                  text: 'Confirm Erasure',
                  style: 'destructive',
                  onPress: async () => {
                    const { db } = getDatabase();
                    await db.delete(notificationRecords);
                    await db.delete(items);
                    await loadItems();
                    await loadHistory();
                    Alert.alert('Data Cleared', 'All items have been removed.');
                  },
                },
              ]
            );
          },
        },
      ]
    );
  };

  const themeOptions: Array<{ id: ThemePreference; label: string; icon: any }> = [
    { id: 'light', label: 'Light', icon: Sun },
    { id: 'dark', label: 'Dark', icon: Moon },
    { id: 'system', label: 'System', icon: Monitor },
  ];

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      <ScrollView contentContainerStyle={styles.scrollContent}>
        {/* Appearance Section */}
        <Text style={[styles.sectionHeading, { color: theme.textMuted }]}>APPEARANCE</Text>
        <View style={[styles.card, { backgroundColor: theme.surface, borderColor: theme.border }]}>
          <Text style={[styles.cardTitle, { color: theme.text }]}>Theme</Text>
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
                      ? { backgroundColor: theme.primary, borderColor: theme.primary }
                      : { backgroundColor: theme.surfaceSubtle, borderColor: theme.border },
                  ]}
                  onPress={() => setPreference(opt.id)}
                >
                  <IconComp size={16} color={isSelected ? '#FFFFFF' : theme.text} />
                  <Text
                    style={[
                      styles.themeOptionText,
                      { color: isSelected ? '#FFFFFF' : theme.text },
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

        {/* Notifications Section */}
        <Text style={[styles.sectionHeading, { color: theme.textMuted }]}>NOTIFICATIONS</Text>
        <View style={[styles.card, { backgroundColor: theme.surface, borderColor: theme.border }]}>
          <View style={styles.rowBetween}>
            <View style={styles.rowLabel}>
              <Bell size={18} color={theme.text} />
              <Text style={[styles.labelTitle, { color: theme.text }]}>Enable Reminders</Text>
            </View>
            <Switch
              value={notificationsEnabled}
              onValueChange={setNotificationsEnabled}
              trackColor={{ false: theme.border, true: theme.primary }}
            />
          </View>

          <View style={[styles.divider, { backgroundColor: theme.border }]} />

          <View style={styles.rowBetween}>
            <View style={styles.rowLabel}>
              <Clock size={18} color={theme.text} />
              <Text style={[styles.labelTitle, { color: theme.text }]}>Daily Alert Time</Text>
            </View>
            <Text style={[styles.valueText, { color: theme.textSecondary }]}>{dailyNotificationTime}</Text>
          </View>

          <View style={[styles.divider, { backgroundColor: theme.border }]} />

          <View style={styles.rowBetween}>
            <View style={styles.rowLabel}>
              <Text style={[styles.labelTitle, { color: theme.text }]}>Expiring Soon Window</Text>
            </View>
            <View style={styles.windowChips}>
              {[3, 7, 14].map((days) => {
                const isSelected = expiringSoonWindowDays === days;
                return (
                  <TouchableOpacity
                    key={days}
                    style={[
                      styles.windowChip,
                      isSelected
                        ? { backgroundColor: theme.primary, borderColor: theme.primary }
                        : { backgroundColor: theme.surfaceSubtle, borderColor: theme.border },
                    ]}
                    onPress={() => setExpiringSoonWindowDays(days)}
                  >
                    <Text
                      style={[
                        styles.windowChipText,
                        { color: isSelected ? '#FFFFFF' : theme.text },
                        isSelected && { fontWeight: '600' },
                      ]}
                    >
                      {days}d
                    </Text>
                  </TouchableOpacity>
                );
              })}
            </View>
          </View>
        </View>

        {/* Data & Privacy */}
        <Text style={[styles.sectionHeading, { color: theme.textMuted }]}>DATA & PRIVACY</Text>
        <View style={[styles.card, { backgroundColor: theme.surface, borderColor: theme.border }]}>
          <View style={styles.privacyBanner}>
            <Shield size={18} color={theme.success} />
            <Text style={[styles.privacyText, { color: theme.textSecondary }]}>
              100% Offline & Private. No accounts, no analytics, no cloud uploads.
            </Text>
          </View>

          <View style={[styles.divider, { backgroundColor: theme.border }]} />

          <TouchableOpacity style={styles.rowBetween} onPress={handleClearAllData}>
            <View style={styles.rowLabel}>
              <Trash2 size={18} color={theme.danger} />
              <Text style={[styles.labelTitle, { color: theme.danger }]}>Delete All Data</Text>
            </View>
            <Text style={[styles.valueText, { color: theme.danger }]}>Clear</Text>
          </TouchableOpacity>
        </View>

        {/* About Dateora */}
        <Text style={[styles.sectionHeading, { color: theme.textMuted }]}>ABOUT</Text>
        <View style={[styles.card, { backgroundColor: theme.surface, borderColor: theme.border }]}>
          <View style={styles.rowBetween}>
            <Text style={[styles.labelTitle, { color: theme.text }]}>Version</Text>
            <Text style={[styles.valueText, { color: theme.textMuted }]}>1.0.0 (v1 MVP)</Text>
          </View>
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
    padding: 16,
    paddingBottom: 40,
  },
  sectionHeading: {
    fontSize: 12,
    fontWeight: '600',
    letterSpacing: 0.5,
    marginBottom: 8,
    marginTop: 12,
    paddingHorizontal: 4,
  },
  card: {
    borderRadius: 12,
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
    borderRadius: 8,
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
    gap: 10,
  },
  labelTitle: {
    fontSize: 15,
    fontWeight: '500',
  },
  valueText: {
    fontSize: 14,
  },
  divider: {
    height: StyleSheet.hairlineWidth,
    marginVertical: 12,
  },
  windowChips: {
    flexDirection: 'row',
    gap: 6,
  },
  windowChip: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 8,
    borderWidth: 1,
  },
  windowChipText: {
    fontSize: 12,
  },
  privacyBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    paddingVertical: 4,
  },
  privacyText: {
    fontSize: 13,
    flex: 1,
    lineHeight: 18,
  },
});
