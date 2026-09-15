export const brandColors = {
  primary: '#2563EB', // Blue
  primaryDark: '#1D4ED8',
  primaryLight: '#3B82F6',
  accent: '#0EA5E9', // Cyan
  accentLight: '#38BDF8',
  success: '#22C55E', // Green
  successLight: '#DCFCE7',
  successDark: '#16A34A',
  warning: '#F59E0B', // Amber
  warningLight: '#FEF3C7',
  warningDark: '#D97706',
  danger: '#EF4444', // Red
  dangerLight: '#FEE2E2',
  dangerDark: '#DC2626',
} as const;

export const lightTheme = {
  ...brandColors,
  background: '#F8FAFC',
  surface: '#FFFFFF',
  surfaceSubtle: '#F1F5F9',
  surfaceActive: '#E2E8F0',
  border: '#E2E8F0',
  borderSubtle: '#F1F5F9',
  borderFocus: '#2563EB',
  text: '#0F172A',
  textSecondary: '#475569',
  textMuted: '#64748B',
  textInverse: '#FFFFFF',
  shadow: '#000000',
  tabBarBackground: '#FFFFFF',
  tabBarBorder: '#E2E8F0',
} as const;

export const darkTheme = {
  ...brandColors,
  background: '#0B0F19',
  surface: '#151D2F',
  surfaceSubtle: '#1E293B',
  surfaceActive: '#334155',
  border: '#2A364F',
  borderSubtle: '#1E293B',
  borderFocus: '#38BDF8',
  text: '#F8FAFC',
  textSecondary: '#CBD5E1',
  textMuted: '#94A3B8',
  textInverse: '#0F172A',
  shadow: '#000000',
  tabBarBackground: '#111726',
  tabBarBorder: '#1E293B',
} as const;

export type ThemeColors = Record<keyof typeof lightTheme, string>;
