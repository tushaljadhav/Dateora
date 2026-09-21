import React from 'react';
import { View, StyleSheet, ViewStyle } from 'react-native';
import Svg, {
  Path,
  Circle,
  Defs,
  LinearGradient,
  Stop,
  G,
} from 'react-native-svg';

interface SmartBellIllustrationProps {
  width?: number;
  height?: number;
  style?: ViewStyle;
}

export const SmartBellIllustration: React.FC<SmartBellIllustrationProps> = ({
  width = 240,
  height = 180,
  style,
}) => {
  return (
    <View style={[styles.container, style]}>
      <Svg width={width} height={height} viewBox="0 0 240 180" fill="none">
        <Defs>
          {/* Background glow */}
          <LinearGradient id="bellBgGlow" x1="0%" y1="0%" x2="100%" y2="100%">
            <Stop offset="0%" stopColor="#DCFCE7" stopOpacity="0.8" />
            <Stop offset="100%" stopColor="#FEF3C7" stopOpacity="0.4" />
          </LinearGradient>

          {/* Bell body gradient */}
          <LinearGradient id="bellGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <Stop offset="0%" stopColor="#34D399" />
            <Stop offset="50%" stopColor="#10B981" />
            <Stop offset="100%" stopColor="#16A34A" />
          </LinearGradient>

          {/* Clapper / Sparkle gradient */}
          <LinearGradient id="amberGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <Stop offset="0%" stopColor="#FBBF24" />
            <Stop offset="100%" stopColor="#F59E0B" />
          </LinearGradient>
        </Defs>

        {/* Soft background circle */}
        <Circle cx="120" cy="90" r="70" fill="url(#bellBgGlow)" />

        {/* Outer Ripple Wave Rings */}
        <Circle
          cx="120"
          cy="90"
          r="84"
          stroke="#10B981"
          strokeWidth="1.5"
          strokeOpacity="0.25"
          strokeDasharray="4 6"
        />
        <Circle
          cx="120"
          cy="90"
          r="98"
          stroke="#10B981"
          strokeWidth="1"
          strokeOpacity="0.15"
        />

        {/* Ground shadow */}
        <Path
          d="M75 146 C 90 152, 150 152, 165 146 C 150 150, 90 150, 75 146 Z"
          fill="#CBD5E1"
          fillOpacity="0.5"
        />

        {/* Bell Body */}
        <G>
          {/* Bell Top Handle */}
          <Path
            d="M112 50 C 112 45, 128 45, 128 50 L128 56 L112 56 Z"
            fill="#059669"
          />

          {/* Main Bell Dome & Flange */}
          <Path
            d="M120 54 C 102 54, 94 72, 92 100 C 90 114, 80 120, 78 126 C 76 130, 80 134, 86 134 L154 134 C 160 134, 164 130, 162 126 C 160 120, 150 114, 148 100 C 146 72, 138 54, 120 54 Z"
            fill="url(#bellGrad)"
          />

          {/* Specular curved highlight on bell */}
          <Path
            d="M102 68 C 98 80, 96 100, 92 118"
            stroke="#FFFFFF"
            strokeWidth="3.5"
            strokeOpacity="0.4"
            strokeLinecap="round"
          />

          {/* Clapper / Bell Ball */}
          <Circle cx="120" cy="140" r="10" fill="url(#amberGrad)" />

          {/* Small notification badge dot */}
          <Circle cx="150" cy="62" r="8" fill="#EF4444" />
          <Circle cx="150" cy="62" r="3" fill="#FFFFFF" />
        </G>

        {/* Sparkles / Sound Waves */}
        <G>
          <Path
            d="M62 76 C 58 84, 58 96, 62 104"
            stroke="#10B981"
            strokeWidth="2.5"
            strokeLinecap="round"
            strokeOpacity="0.7"
          />
          <Path
            d="M178 76 C 182 84, 182 96, 178 104"
            stroke="#10B981"
            strokeWidth="2.5"
            strokeLinecap="round"
            strokeOpacity="0.7"
          />

          {/* Small 4-point sparkles */}
          <Path
            d="M176 46 Q 176 52 182 52 Q 176 52 176 58 Q 176 52 170 52 Q 176 52 176 46 Z"
            fill="#F59E0B"
          />
          <Path
            d="M68 52 Q 68 56 72 56 Q 68 56 68 60 Q 68 56 64 56 Q 68 56 68 52 Z"
            fill="#10B981"
          />
        </G>
      </Svg>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    justifyContent: 'center',
  },
});
