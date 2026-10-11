import React, { createContext, useContext, useMemo } from 'react';
import { useColorScheme } from 'react-native';
import { lightTheme, darkTheme, ThemeColors, brandColors, brandPalette } from './colors';
import { spacing, Spacing } from './spacing';
import { radius, Radius } from './radius';
import { typography, Typography } from './typography';
import { shadows, Shadows } from './shadows';
import { motion, Motion } from './motion';

export { lightTheme, darkTheme, brandColors, brandPalette, spacing, radius, typography, shadows, motion };
export type { ThemeColors, Spacing, Radius, Typography, Shadows, Motion };

export type ThemePreference = 'light' | 'dark' | 'system';

interface ThemeContextType {
  theme: ThemeColors;
  isDark: boolean;
  preference: ThemePreference;
  setPreference: (pref: ThemePreference) => void;
  spacing: typeof spacing;
  radius: typeof radius;
  typography: typeof typography;
  shadows: typeof shadows;
  motion: typeof motion;
}

const ThemeContext = createContext<ThemeContextType>({
  theme: lightTheme,
  isDark: false,
  preference: 'light',
  setPreference: () => {},
  spacing,
  radius,
  typography,
  shadows,
  motion,
});

export const ThemeProvider: React.FC<{
  children: React.ReactNode;
  preference?: ThemePreference;
  onPreferenceChange?: (pref: ThemePreference) => void;
}> = ({ children, preference = 'light', onPreferenceChange }) => {
  const systemScheme = useColorScheme();

  const isDark = useMemo(() => {
    if (preference === 'dark') return true;
    if (preference === 'light') return false;
    return systemScheme === 'dark';
  }, [preference, systemScheme]);

  const theme = isDark ? darkTheme : lightTheme;

  const value = useMemo(
    () => ({
      theme,
      isDark,
      preference,
      setPreference: (p: ThemePreference) => onPreferenceChange?.(p),
      spacing,
      radius,
      typography,
      shadows,
      motion,
    }),
    [theme, isDark, preference, onPreferenceChange]
  );

  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>;
};

export const useTheme = () => useContext(ThemeContext);
