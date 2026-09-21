/**
 * Dateora Corner Radius Scale
 * Apple Health & Notion inspired rounded corners and pills.
 */
export const radius = {
  xs: 6,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 20,
  xxl: 24,
  button: 14,
  chip: 9999,
  input: 12,
  card: 16,
  sheet: 24,
  pill: 9999,
} as const;

export type Radius = typeof radius;
