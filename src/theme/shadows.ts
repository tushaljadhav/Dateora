import { ViewStyle } from 'react-native';

/**
 * Locked Soft Shadows: Blue-tinted, low opacity (never gray heavy shadows)
 */
export const shadows = {
  none: {
    shadowColor: 'transparent',
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0,
    shadowRadius: 0,
    elevation: 0,
  } as ViewStyle,
  xs: {
    shadowColor: '#3B6BFF',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.04,
    shadowRadius: 6,
    elevation: 1,
  } as ViewStyle,
  sm: {
    shadowColor: '#3B6BFF',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.06,
    shadowRadius: 12,
    elevation: 2,
  } as ViewStyle,
  md: {
    shadowColor: '#3B6BFF',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.08,
    shadowRadius: 20,
    elevation: 4,
  } as ViewStyle,
  glow: {
    shadowColor: '#3B6BFF',
    shadowOffset: { width: 0, height: 6 },
    shadowOpacity: 0.22,
    shadowRadius: 16,
    elevation: 5,
  } as ViewStyle,
} as const;

export type Shadows = typeof shadows;
