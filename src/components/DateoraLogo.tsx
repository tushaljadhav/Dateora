import React from 'react';
import { View, StyleSheet, Text, ViewStyle } from 'react-native';
import Svg, { Path, Rect, Circle, Defs, LinearGradient, Stop } from 'react-native-svg';
import { useTheme } from '../theme';

interface DateoraLogoProps {
  size?: number;
  showText?: boolean;
  tagline?: boolean;
  textColor?: string;
  withBackground?: boolean;
  style?: ViewStyle;
}

export const DateoraLogo: React.FC<DateoraLogoProps> = ({
  size = 36,
  showText = false,
  tagline = false,
  textColor,
  withBackground = true,
  style,
}) => {
  const { theme } = useTheme();
  const labelColor = textColor || theme.text;

  return (
    <View style={[styles.container, style]}>
      <Svg width={size} height={size} viewBox="0 0 1024 1024" fill="none">
        <Defs>
          {/* 135deg Brand Gradient */}
          <LinearGradient id="dateoraGrad" x1="100" y1="100" x2="924" y2="924" gradientUnits="userSpaceOnUse">
            <Stop offset="0%" stopColor="#3566FF" />
            <Stop offset="45%" stopColor="#4A65FF" />
            <Stop offset="100%" stopColor="#7E54FF" />
          </LinearGradient>
        </Defs>

        {withBackground ? (
          <Rect width="1024" height="1024" rx="230" fill="url(#dateoraGrad)" />
        ) : null}

        {/* Open Clock Arc (Vigilant Expiry Arc) */}
        <Path
          d="M 689 603 A 220 220 0 1 1 653 399"
          stroke={withBackground ? '#FFFFFF' : '#3566FF'}
          strokeWidth="60"
          strokeLinecap="round"
        />

        {/* Affirmative Caught-in-Time Checkmark */}
        <Path
          d="M 428 506 L 500 578 L 652 426"
          stroke={withBackground ? '#FFFFFF' : '#3566FF'}
          strokeWidth="74"
          strokeLinecap="round"
          strokeLinejoin="round"
        />

        {/* Notification Alert Aura Beacon */}
        <Circle cx="722" cy="286" r="64" fill="#FF5858" />
      </Svg>

      {showText && (
        <View style={styles.textContainer}>
          <Text style={[styles.brandTitle, { color: labelColor, fontSize: size * 0.62 }]}>Dateora</Text>
          {tagline && (
            <Text style={[styles.taglineText, { color: theme.textSecondary }]}>
              Never miss an expiry
            </Text>
          )}
        </View>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  textContainer: {
    justifyContent: 'center',
  },
  brandTitle: {
    fontWeight: '700',
    letterSpacing: -0.4,
  },
  taglineText: {
    fontSize: 12,
    fontWeight: '500',
    marginTop: 1,
  },
});
