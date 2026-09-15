/**
 * Dateora Spacing Scale
 * Strictly follows 8pt grid (8 / 16 / 24 / 32 / 40 / 48) with 4pt half-step for micro-spacings.
 */
export const spacing = {
  xxs: 2,
  xs: 4,
  sm: 8,
  md: 16,
  lg: 24,
  xl: 32,
  xxl: 40,
  xxxl: 48,
} as const;

export type Spacing = typeof spacing;
