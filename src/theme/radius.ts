/**
 * Dateora Corner Radius Scale
 * Strict scale: 12px cards, 8px chips/buttons/inputs, 9999px pills. Never mixed.
 */
export const radius = {
  button: 8,
  chip: 8,
  input: 8,
  card: 12,
  sheet: 16,
  pill: 9999,
} as const;

export type Radius = typeof radius;
