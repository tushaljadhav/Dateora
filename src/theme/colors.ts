/**
 * Dateora Design System — Locked Color Tokens
 * Light theme only. Clean, bright, premium and trustworthy.
 */

export const brandPalette = {
  primaryBlue: '#3B6BFF',
  primaryPurple: '#7C5CFF',

  // Gradient endpoints
  gradientStart: '#3B6BFF',
  gradientEnd: '#7C5CFF',

  // Tinted Fills (10%)
  blue10: 'rgba(59, 107, 255, 0.10)',
  purple10: 'rgba(124, 92, 255, 0.10)',

  // Semantic Status (Soft, restrained)
  statusSafe: '#22C58B',
  statusSafeBg: 'rgba(34, 197, 139, 0.12)',

  statusExpiring: '#FFB020',
  statusExpiringBg: 'rgba(255, 176, 32, 0.12)',

  statusExpired: '#FF5C6C',
  statusExpiredBg: 'rgba(255, 92, 108, 0.12)',

  // Neutral Canvas & Text
  background: '#F6F7FF',
  surface: '#FFFFFF',
  textPrimary: '#12142B',
  textSecondary: '#6B7194',
  textMuted: '#9CA3AF',
  border: '#E6E8F5',
  borderDivider: '#E6E8F5',
};

export const brandColors = {
  primary: brandPalette.primaryBlue,
  primaryLight: '#5F85FF',
  primaryDark: '#2550D6',
  primarySubtle: brandPalette.blue10,
  primaryGlow: 'rgba(59, 107, 255, 0.18)',

  secondary: brandPalette.primaryPurple,
  secondaryLight: '#977EFF',
  secondaryDark: '#603FE0',
  secondarySubtle: brandPalette.purple10,

  accent: brandPalette.primaryPurple,
  accentLight: '#977EFF',
  accentDark: '#603FE0',
  accentSubtle: brandPalette.purple10,

  // Semantic Status Mapping (Always soft with badge and icon)
  status: {
    safe: {
      color: brandPalette.statusSafe,
      bg: brandPalette.statusSafeBg,
      text: brandPalette.statusSafe,
      border: 'rgba(34, 197, 139, 0.20)',
      dot: brandPalette.statusSafe,
    },
    expiring: {
      color: brandPalette.statusExpiring,
      bg: brandPalette.statusExpiringBg,
      text: brandPalette.statusExpiring,
      border: 'rgba(255, 176, 32, 0.20)',
      dot: brandPalette.statusExpiring,
    },
    expired: {
      color: brandPalette.statusExpired,
      bg: brandPalette.statusExpiredBg,
      text: brandPalette.statusExpired,
      border: 'rgba(255, 92, 108, 0.20)',
      dot: brandPalette.statusExpired,
    },
  },

  success: brandPalette.statusSafe,
  successLight: brandPalette.statusSafeBg,
  successDark: '#179E6F',

  warning: brandPalette.statusExpiring,
  warningLight: brandPalette.statusExpiringBg,
  warningDark: '#D48F11',

  danger: brandPalette.statusExpired,
  dangerLight: brandPalette.statusExpiredBg,
  dangerDark: '#DE3A4B',

  info: brandPalette.primaryBlue,
  infoLight: brandPalette.blue10,
  infoDark: '#2550D6',
};

export interface ThemeColors {
  primary: string;
  primaryLight: string;
  primaryDark: string;
  primarySubtle: string;
  primaryGlow: string;
  secondary: string;
  secondaryLight: string;
  secondaryDark: string;
  secondarySubtle: string;
  accent: string;
  accentLight: string;
  accentDark: string;
  accentSubtle: string;
  status: {
    safe: { color: string; bg: string; text: string; border: string; dot: string };
    expiring: { color: string; bg: string; text: string; border: string; dot: string };
    expired: { color: string; bg: string; text: string; border: string; dot: string };
  };
  success: string;
  successLight: string;
  successDark: string;
  warning: string;
  warningLight: string;
  warningDark: string;
  danger: string;
  dangerLight: string;
  dangerDark: string;
  info: string;
  infoLight: string;
  infoDark: string;
  isDarkTheme: boolean;
  background: string;
  surface: string;
  surfaceRaised: string;
  surfaceSubtle: string;
  surfaceActive: string;
  border: string;
  borderSubtle: string;
  borderFocus: string;
  text: string;
  textSecondary: string;
  textMuted: string;
  textInverse: string;
  shadow: string;
  tabBarBackground: string;
  tabBarBorder: string;
}

/**
 * Locked Theme (Light theme only, generous whitespace)
 */
export const lightTheme: ThemeColors = {
  ...brandColors,
  isDarkTheme: false,
  background: brandPalette.background,
  surface: brandPalette.surface,
  surfaceRaised: '#FFFFFF',
  surfaceSubtle: brandPalette.blue10,
  surfaceActive: 'rgba(59, 107, 255, 0.08)',
  border: brandPalette.border,
  borderSubtle: '#F0F2FA',
  borderFocus: brandPalette.primaryBlue,
  text: brandPalette.textPrimary,
  textSecondary: brandPalette.textSecondary,
  textMuted: brandPalette.textMuted,
  textInverse: '#FFFFFF',
  shadow: 'rgba(59, 107, 255, 0.06)',
  tabBarBackground: '#FFFFFF',
  tabBarBorder: brandPalette.border,
};

// Professional OLED Dark Theme with high-contrast luxury styling
export const darkTheme: ThemeColors = {
  ...brandColors,
  isDarkTheme: true,
  background: '#0B0F19',
  surface: '#131B2E',
  surfaceRaised: '#1E293B',
  surfaceSubtle: 'rgba(59, 107, 255, 0.16)',
  surfaceActive: 'rgba(59, 107, 255, 0.28)',
  border: '#1F293D',
  borderSubtle: '#162032',
  borderFocus: '#60A5FA',
  text: '#F8FAFC',
  textSecondary: '#94A3B8',
  textMuted: '#64748B',
  textInverse: '#0B0F19',
  shadow: 'rgba(0, 0, 0, 0.55)',
  tabBarBackground: '#0F1626',
  tabBarBorder: '#1F293D',

  // Status mapping tuned for deep dark backgrounds
  status: {
    safe: {
      color: '#34D399',
      bg: 'rgba(52, 211, 153, 0.15)',
      text: '#34D399',
      border: 'rgba(52, 211, 153, 0.25)',
      dot: '#34D399',
    },
    expiring: {
      color: '#FBBF24',
      bg: 'rgba(251, 191, 36, 0.15)',
      text: '#FBBF24',
      border: 'rgba(251, 191, 36, 0.25)',
      dot: '#FBBF24',
    },
    expired: {
      color: '#F87171',
      bg: 'rgba(248, 113, 113, 0.15)',
      text: '#F87171',
      border: 'rgba(248, 113, 113, 0.25)',
      dot: '#F87171',
    },
  },
};
