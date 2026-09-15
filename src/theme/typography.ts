import { TextStyle } from 'react-native';

export const typography = {
  weights: {
    regular: '400' as TextStyle['fontWeight'],
    medium: '500' as TextStyle['fontWeight'],
    semibold: '600' as TextStyle['fontWeight'],
    bold: '700' as TextStyle['fontWeight'],
  },
  sizes: {
    xs: 12,
    sm: 14,
    base: 16,
    lg: 18,
    xl: 20,
    xxl: 24,
    hero: 30,
  },
  lineHeights: {
    xs: 16,
    sm: 20,
    base: 24,
    lg: 26,
    xl: 28,
    xxl: 32,
    hero: 38,
  },
} as const;

export type Typography = typeof typography;
