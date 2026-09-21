import { ThemePreference } from '../theme';

export interface AppSettings {
  theme: ThemePreference;
  defaultReminderOffsets: number[];
  dailyNotificationTime: string; // 'HH:mm' format, e.g. '09:00'
  expiringSoonWindowDays: number; // default 7
  hasCompletedOnboarding: boolean;
  notificationsEnabled: boolean;
}

export const DEFAULT_SETTINGS: AppSettings = {
  theme: 'light',
  defaultReminderOffsets: [3, 1],
  dailyNotificationTime: '09:00',
  expiringSoonWindowDays: 7,
  hasCompletedOnboarding: false,
  notificationsEnabled: true,
};
