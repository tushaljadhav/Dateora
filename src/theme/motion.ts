import { Easing } from 'react-native-reanimated';

export const motion = {
  duration: {
    fast: 150,
    normal: 250,
    slow: 400,
  },
  easing: {
    standard: Easing.out(Easing.cubic),
    emphasized: Easing.bezier(0.2, 0, 0, 1),
    decelerate: Easing.out(Easing.quad),
  },
  scale: {
    pressed: 0.97,
    pressedSubtle: 0.985,
  },
} as const;

export type Motion = typeof motion;
