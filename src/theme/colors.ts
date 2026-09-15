export const brandColors = {
  primary: '#3B82F6', // Electric Cobalt / Royal Blue
  primaryDark: '#2563EB',
  primaryLight: '#60A5FA',
  primaryGlow: 'rgba(59, 130, 246, 0.25)',

  accent: '#06B6D4', // Vibrant Cyan / Aqua
  accentLight: '#22D3EE',
  accentDark: '#0891B2',
  accentGlow: 'rgba(6, 182, 212, 0.25)',

  success: '#10B981', // Neon Mint / Emerald
  successLight: 'rgba(16, 185, 129, 0.16)',
  successDark: '#059669',

  warning: '#F59E0B', // Radiant Amber / Warm Gold
  warningLight: 'rgba(245, 158, 11, 0.16)',
  warningDark: '#D97706',

  danger: '#EF4444', // Vivid Coral / Neon Red
  dangerLight: 'rgba(239, 68, 68, 0.16)',
  dangerDark: '#DC2626',
} as const;

/**
 * GoTall-inspired signature ultra-sleek Dark Theme (Default)
 * Deep obsidian midnight background, elevated graphite-navy cards,
 * crisp neon accents, glowing pills, and high-contrast typography.
 */
export const darkTheme = {
  ...brandColors,
  background: '#080B11', // Deep obsidian
  surface: '#101622', // Elevated sleek card
  surfaceSubtle: '#172032', // Secondary container / inputs
  surfaceActive: '#1E2A42', // Active / pressed state
  border: '#1E293B', // Subtle crisp border
  borderSubtle: '#141D2C',
  borderFocus: '#3B82F6', // Glowing blue border
  text: '#FFFFFF', // High-contrast crisp white
  textSecondary: '#94A3B8', // Sleek slate
  textMuted: '#64748B', // Muted label
  textInverse: '#080B11',
  shadow: '#000000',
  tabBarBackground: '#0C101A', // Dark bottom bar
  tabBarBorder: '#172032',
} as const;

/**
 * Sleek Light Theme counterpart with matching vibrant accents
 */
export const lightTheme = {
  ...brandColors,
  background: '#F8FAFC',
  surface: '#FFFFFF',
  surfaceSubtle: '#F1F5F9',
  surfaceActive: '#E2E8F0',
  border: '#E2E8F0',
  borderSubtle: '#F1F5F9',
  borderFocus: '#3B82F6',
  text: '#0F172A',
  textSecondary: '#475569',
  textMuted: '#64748B',
  textInverse: '#FFFFFF',
  shadow: '#000000',
  tabBarBackground: '#FFFFFF',
  tabBarBorder: '#E2E8F0',
} as const;

export type ThemeColors = Record<keyof typeof darkTheme, string>;
