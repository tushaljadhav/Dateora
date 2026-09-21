import React from 'react';
import { View, StyleSheet, Text, ViewStyle } from 'react-native';
import Svg, { Path, Defs, LinearGradient, Stop } from 'react-native-svg';

interface DateoraLogoProps {
  size?: number;
  showText?: boolean;
  tagline?: boolean;
  textColor?: string;
  style?: ViewStyle;
}

export const DateoraLogo: React.FC<DateoraLogoProps> = ({
  size = 36,
  showText = false,
  tagline = false,
  textColor = '#0F172A',
  style,
}) => {
  return (
    <View style={[styles.container, style]}>
      <Svg width={size} height={size} viewBox="0 0 100 100" fill="none">
        <Defs>
          <LinearGradient id="emeraldGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <Stop offset="0%" stopColor="#22C55E" />
            <Stop offset="100%" stopColor="#16A34A" />
          </LinearGradient>
          <LinearGradient id="mintGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <Stop offset="0%" stopColor="#34D399" />
            <Stop offset="100%" stopColor="#10B981" />
          </LinearGradient>
        </Defs>

        {/* Left Primary Leaf */}
        <Path
          d="M20 75 C 10 45, 30 18, 55 15 C 60 40, 48 70, 20 75 Z"
          fill="url(#emeraldGrad)"
        />
        {/* Leaf Stem / Rib */}
        <Path
          d="M24 72 C 34 50, 44 32, 53 18"
          stroke="rgba(255,255,255,0.4)"
          strokeWidth="3"
          strokeLinecap="round"
        />

        {/* Right Overlapping Secondary Mint Leaf */}
        <Path
          d="M52 82 C 42 58, 54 36, 82 28 C 88 52, 76 76, 52 82 Z"
          fill="url(#mintGrad)"
        />
        <Path
          d="M55 78 C 62 60, 70 45, 80 30"
          stroke="rgba(255,255,255,0.4)"
          strokeWidth="3"
          strokeLinecap="round"
        />
      </Svg>

      {showText && (
        <View style={styles.textContainer}>
          <Text style={[styles.brandTitle, { color: textColor, fontSize: size * 0.65 }]}>Dateora</Text>
          {tagline && (
            <Text style={[styles.taglineText, { color: textColor, opacity: 0.7 }]}>
              Never let good things go to waste
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
    fontWeight: '800',
    letterSpacing: -0.5,
  },
  taglineText: {
    fontSize: 12,
    fontWeight: '500',
    marginTop: 2,
  },
});
