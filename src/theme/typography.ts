import { TextStyle, Platform } from 'react-native';

export const fontFamilies = {
  regular: Platform.select({ ios: 'Inter_400Regular', android: 'Inter_400Regular', default: 'Inter, sans-serif' }),
  medium: Platform.select({ ios: 'Inter_500Medium', android: 'Inter_500Medium', default: 'Inter, sans-serif' }),
  semibold: Platform.select({ ios: 'Inter_600SemiBold', android: 'Inter_600SemiBold', default: 'Inter, sans-serif' }),
  bold: Platform.select({ ios: 'Inter_700Bold', android: 'Inter_700Bold', default: 'Inter, sans-serif' }),
} as const;

export const typography = {
  fontFamilies,
  weights: {
    regular: '400' as TextStyle['fontWeight'],
    medium: '500' as TextStyle['fontWeight'],
    semibold: '600' as TextStyle['fontWeight'],
    bold: '700' as TextStyle['fontWeight'],
  },
  sizes: {
    caption: 12,
    body: 15,
    title: 20,
    display: 28,
  },
  lineHeights: {
    caption: 16,
    body: 22,
    title: 28,
    display: 36,
  },
  // Exact presets from design specification
  presets: {
    display: {
      fontFamily: fontFamilies.bold,
      fontSize: 28,
      lineHeight: 36,
      fontWeight: '700' as TextStyle['fontWeight'],
      letterSpacing: -0.5,
    },
    title: {
      fontFamily: fontFamilies.semibold,
      fontSize: 20,
      lineHeight: 28,
      fontWeight: '600' as TextStyle['fontWeight'],
      letterSpacing: -0.3,
    },
    body: {
      fontFamily: fontFamilies.regular,
      fontSize: 15,
      lineHeight: 22,
      fontWeight: '400' as TextStyle['fontWeight'],
    },
    bodyMedium: {
      fontFamily: fontFamilies.medium,
      fontSize: 15,
      lineHeight: 22,
      fontWeight: '500' as TextStyle['fontWeight'],
    },
    bodyBold: {
      fontFamily: fontFamilies.semibold,
      fontSize: 15,
      lineHeight: 22,
      fontWeight: '600' as TextStyle['fontWeight'],
    },
    caption: {
      fontFamily: fontFamilies.medium,
      fontSize: 12,
      lineHeight: 16,
      fontWeight: '500' as TextStyle['fontWeight'],
      letterSpacing: 0.1,
    },
  },
} as const;

export type Typography = typeof typography;
