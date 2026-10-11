/**
 * Dateora Spacing Scale
 * Strictly follows 4pt/8pt grid for predictable, harmonious spacing.
 */
export const spacing = {
  xxs: 2,
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 20,
  xxl: 24,
  '2xl': 24,
  xxxl: 32,
  '3xl': 32,
  '4xl': 40,
  '5xl': 48,
} as const;

export type Spacing = typeof spacing;
