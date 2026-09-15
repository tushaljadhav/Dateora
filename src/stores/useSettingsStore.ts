import { create } from 'zustand';
import { AppSettings, DEFAULT_SETTINGS } from '../types/settings';
import { ThemePreference } from '../theme';
import { getDatabase } from '../db/client';
import { appSettingsTable } from '../db/schema';
import { eq } from 'drizzle-orm';

interface SettingsState extends AppSettings {
  isLoaded: boolean;
  loadSettings: () => Promise<void>;
  setTheme: (theme: ThemePreference) => Promise<void>;
  setExpiringSoonWindowDays: (days: number) => Promise<void>;
  setDefaultReminderOffsets: (offsets: number[]) => Promise<void>;
  setDailyNotificationTime: (time: string) => Promise<void>;
  setNotificationsEnabled: (enabled: boolean) => Promise<void>;
  setHasCompletedOnboarding: (completed: boolean) => Promise<void>;
}

export const useSettingsStore = create<SettingsState>((set, get) => ({
  ...DEFAULT_SETTINGS,
  isLoaded: false,

  loadSettings: async () => {
    try {
      const { db } = getDatabase();
      const rows = await db.select().from(appSettingsTable);
      const settingsMap: Record<string, string> = {};
      rows.forEach((r) => {
        settingsMap[r.key] = r.value;
      });

      set({
        theme: (settingsMap['theme'] as ThemePreference) || DEFAULT_SETTINGS.theme,
        expiringSoonWindowDays: settingsMap['expiringSoonWindowDays']
          ? parseInt(settingsMap['expiringSoonWindowDays'], 10)
          : DEFAULT_SETTINGS.expiringSoonWindowDays,
        defaultReminderOffsets: settingsMap['defaultReminderOffsets']
          ? JSON.parse(settingsMap['defaultReminderOffsets'])
          : DEFAULT_SETTINGS.defaultReminderOffsets,
        dailyNotificationTime: settingsMap['dailyNotificationTime'] || DEFAULT_SETTINGS.dailyNotificationTime,
        hasCompletedOnboarding: settingsMap['hasCompletedOnboarding'] === 'true',
        notificationsEnabled: settingsMap['notificationsEnabled'] !== 'false',
        isLoaded: true,
      });
    } catch {
      set({ isLoaded: true });
    }
  },

  setTheme: async (theme: ThemePreference) => {
    set({ theme });
    const { db } = getDatabase();
    await db
      .insert(appSettingsTable)
      .values({ key: 'theme', value: theme })
      .onConflictDoUpdate({ target: appSettingsTable.key, set: { value: theme } });
  },

  setExpiringSoonWindowDays: async (days: number) => {
    set({ expiringSoonWindowDays: days });
    const { db } = getDatabase();
    await db
      .insert(appSettingsTable)
      .values({ key: 'expiringSoonWindowDays', value: days.toString() })
      .onConflictDoUpdate({ target: appSettingsTable.key, set: { value: days.toString() } });
  },

  setDefaultReminderOffsets: async (offsets: number[]) => {
    set({ defaultReminderOffsets: offsets });
    const { db } = getDatabase();
    await db
      .insert(appSettingsTable)
      .values({ key: 'defaultReminderOffsets', value: JSON.stringify(offsets) })
      .onConflictDoUpdate({ target: appSettingsTable.key, set: { value: JSON.stringify(offsets) } });
  },

  setDailyNotificationTime: async (time: string) => {
    set({ dailyNotificationTime: time });
    const { db } = getDatabase();
    await db
      .insert(appSettingsTable)
      .values({ key: 'dailyNotificationTime', value: time })
      .onConflictDoUpdate({ target: appSettingsTable.key, set: { value: time } });
  },

  setNotificationsEnabled: async (enabled: boolean) => {
    set({ notificationsEnabled: enabled });
    const { db } = getDatabase();
    await db
      .insert(appSettingsTable)
      .values({ key: 'notificationsEnabled', value: enabled.toString() })
      .onConflictDoUpdate({ target: appSettingsTable.key, set: { value: enabled.toString() } });
  },

  setHasCompletedOnboarding: async (completed: boolean) => {
    set({ hasCompletedOnboarding: completed });
    const { db } = getDatabase();
    await db
      .insert(appSettingsTable)
      .values({ key: 'hasCompletedOnboarding', value: completed.toString() })
      .onConflictDoUpdate({ target: appSettingsTable.key, set: { value: completed.toString() } });
  },
}));
