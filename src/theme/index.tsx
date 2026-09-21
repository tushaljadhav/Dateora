import React, { createContext, useContext, useMemo } from 'react';
import { useColorScheme } from 'react-native';
import { lightTheme, darkTheme, ThemeColors, brandColors } from './colors';
import { spacing } from './spacing';
import { radius } from './radius';
import { typography } from './typography';

export { lightTheme, darkTheme, brandColors, spacing, radius, typography };
export type { ThemeColors } from './colors';
export type { Spacing } from './spacing';
export type { Radius } from './radius';
export type { Typography } from './typography';

export type ThemePreference = 'light' | 'dark' | 'system';

interface ThemeContextType {
  theme: ThemeColors;
  isDark: boolean;
  preference: ThemePreference;
  setPreference: (pref: ThemePreference) => void;
  spacing: typeof spacing;
  radius: typeof radius;
  typography: typeof typography;
}

const ThemeContext = createContext<ThemeContextType>({
  theme: darkTheme,
  isDark: true,
  preference: 'dark',
  setPreference: () => {},
  spacing,
  radius,
  typography,
});

export const ThemeProvider: React.FC<{
  children: React.ReactNode;
  preference?: ThemePreference;
  onPreferenceChange?: (pref: ThemePreference) => void;
}> = ({ children, preference = 'dark', onPreferenceChange }) => {
  const systemScheme = useColorScheme();

  const isDark = useMemo(() => {
    if (preference === 'light') return false;
    // Default to true (GoTall signature dark aesthetic)
    return true;
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
    }),
    [theme, isDark, preference, onPreferenceChange]
  );

  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>;
};

export const useTheme = () => useContext(ThemeContext);
