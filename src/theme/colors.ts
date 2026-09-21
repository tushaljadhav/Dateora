export const brandColors = {
  primary: '#16A34A', // Emerald Green (Reference Primary)
  primaryDark: '#15803D',
  primaryLight: '#22C55E',
  primarySubtle: 'rgba(22, 163, 74, 0.12)',
  primaryGlow: 'rgba(22, 163, 74, 0.25)',

  secondary: '#10B981', // Mint (Reference Secondary)
  secondaryLight: '#34D399',
  secondaryDark: '#059669',
  secondarySubtle: 'rgba(16, 185, 129, 0.12)',

  success: '#10B981', // Mint / Emerald
  successLight: 'rgba(16, 185, 129, 0.14)',
  successDark: '#059669',

  warning: '#F59E0B', // Radiant Amber
  warningLight: 'rgba(245, 158, 11, 0.14)',
  warningDark: '#D97706',

  danger: '#EF4444', // Error Red
  dangerLight: 'rgba(239, 68, 68, 0.14)',
  dangerDark: '#DC2626',
} as const;

/**
 * Premium Minimal Light Theme (Default in reference: Apple Health / Notion style)
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
  textSecondary: '#64748B',
  textMuted: '#94A3B8',
  textInverse: '#FFFFFF',
  shadow: 'rgba(15, 23, 42, 0.06)',
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
  primarySubtle: 'rgba(34, 197, 94, 0.18)',
  background: '#0B1215',
  surface: '#141E24',
  surfaceSubtle: '#1C2932',
  surfaceActive: '#233440',
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
