export const brandColors = {
  primary: '#16A34A', // Emerald Green (Reference Primary: Green 600)
  primaryDark: '#15803D', // Green 700
  primaryLight: '#22C55E', // Green 500
  primarySubtle: 'rgba(22, 163, 74, 0.10)',
  primaryGlow: 'rgba(22, 163, 74, 0.20)',

  secondary: '#10B981', // Mint (Reference Secondary: Green 500)
  secondaryLight: '#34D399',
  secondaryDark: '#059669',
  secondarySubtle: 'rgba(16, 185, 129, 0.12)',

  accent: '#22C55E', // Green 400
  lightGreen: '#DCFCE7', // Green 100
  veryLightGreen: '#F0FDF4', // Green 50

  success: '#16A34A',
  successLight: '#DCFCE7',
  successDark: '#15803D',

  warning: '#F59E0B', // Radiant Amber
  warningLight: '#FEF3C7',
  warningDark: '#D97706',

  danger: '#EF4444', // Error Red
  dangerLight: '#FEE2E2',
  dangerDark: '#DC2626',

  info: '#0284C7', // Ocean Blue
  infoLight: '#E0F2FE',
  infoDark: '#0369A1',
} as const;

/**
 * Premium Minimal Light Theme (Primary reference: Apple Health / Notion / Dateora case-study)
 * Clean, fresh canvas #F8FAFC, crisp white cards #FFFFFF, refined borders #E2E8F0,
 * and high-contrast typography #0F172A.
 */
export const lightTheme = {
  ...brandColors,
  background: '#F8FAFC',
  surface: '#FFFFFF',
  surfaceSubtle: '#F1F5F9',
  surfaceActive: '#E2E8F0',
  border: '#E2E8F0',
  borderSubtle: '#F1F5F9',
  borderFocus: '#16A34A',
  text: '#0F172A',
  textSecondary: '#475569',
  textMuted: '#94A3B8',
  textInverse: '#FFFFFF',
  shadow: 'rgba(15, 23, 42, 0.04)',
  tabBarBackground: '#FFFFFF',
  tabBarBorder: '#E2E8F0',
} as const;

/**
 * Premium Minimal Dark Theme (Reference Dark Mode)
 * Deep midnight slate #0B1215, elevated cards #141E24, subtle borders #1E2D38,
 * crisp white text #F8FAFC, and vibrant Emerald & Mint accents.
 */
export const darkTheme = {
  ...brandColors,
  primary: '#22C55E', // Slightly brighter emerald for dark canvas
  primarySubtle: 'rgba(34, 197, 94, 0.16)',
  lightGreen: 'rgba(34, 197, 94, 0.20)',
  veryLightGreen: 'rgba(34, 197, 94, 0.10)',
  background: '#0B1215',
  surface: '#141E24',
  surfaceSubtle: '#1C2932',
  surfaceActive: '#243743',
  border: '#1E2D38',
  borderSubtle: '#18242D',
  borderFocus: '#22C55E',
  text: '#F8FAFC',
  textSecondary: '#94A3B8',
  textMuted: '#64748B',
  textInverse: '#0B1215',
  shadow: 'rgba(0, 0, 0, 0.4)',
  tabBarBackground: '#10171D',
  tabBarBorder: '#1A2731',
} as const;

export type ThemeColors = Record<keyof typeof lightTheme, string>;
