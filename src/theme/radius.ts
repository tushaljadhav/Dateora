/**
 * Dateora Corner Radius Scale
 * Locked: Card radius 20, buttons 14, chips 999
 */
export const radius = {
  xs: 6,
  sm: 8,
  md: 12,
  button: 14,
  card: 20,
  lg: 20,
  xl: 24,
  full: 999,
  chip: 999,
  pill: 999,
} as const;

export type Radius = typeof radius;
