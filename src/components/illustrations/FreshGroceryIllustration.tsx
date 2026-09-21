import React from 'react';
import { View, StyleSheet, ViewStyle } from 'react-native';
import Svg, {
  Path,
  Circle,
  Rect,
  Defs,
  LinearGradient,
  Stop,
  G,
} from 'react-native-svg';

interface FreshGroceryIllustrationProps {
  width?: number;
  height?: number;
  style?: ViewStyle;
}

export const FreshGroceryIllustration: React.FC<FreshGroceryIllustrationProps> = ({
  width = 240,
  height = 180,
  style,
}) => {
  return (
    <View style={[styles.container, style]}>
      <Svg width={width} height={height} viewBox="0 0 240 180" fill="none">
        <Defs>
          {/* Soft background glow */}
          <LinearGradient id="bgGlow" x1="0%" y1="0%" x2="100%" y2="100%">
            <Stop offset="0%" stopColor="#DCFCE7" stopOpacity="0.8" />
            <Stop offset="100%" stopColor="#F0FDF4" stopOpacity="0.4" />
          </LinearGradient>

          {/* Milk bottle gradient */}
          <LinearGradient id="bottleGrad" x1="0%" y1="0%" x2="100%" y2="0%">
            <Stop offset="0%" stopColor="#F8FAFC" />
            <Stop offset="50%" stopColor="#FFFFFF" />
            <Stop offset="100%" stopColor="#E2E8F0" />
          </LinearGradient>

          {/* Milk cap gradient */}
          <LinearGradient id="capGrad" x1="0%" y1="0%" x2="100%" y2="0%">
            <Stop offset="0%" stopColor="#22C55E" />
            <Stop offset="100%" stopColor="#16A34A" />
          </LinearGradient>

          {/* Carrot gradient */}
          <LinearGradient id="carrotGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <Stop offset="0%" stopColor="#FB923C" />
            <Stop offset="100%" stopColor="#EA580C" />
          </LinearGradient>

          {/* Tomato gradient */}
          <LinearGradient id="tomatoGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <Stop offset="0%" stopColor="#F87171" />
            <Stop offset="100%" stopColor="#DC2626" />
          </LinearGradient>

          {/* Leaf gradient */}
          <LinearGradient id="leafGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <Stop offset="0%" stopColor="#34D399" />
            <Stop offset="100%" stopColor="#10B981" />
          </LinearGradient>
        </Defs>

        {/* Backdrop Soft Circle */}
        <Circle cx="120" cy="95" r="75" fill="url(#bgGlow)" />
        <Circle cx="175" cy="55" r="14" fill="#DCFCE7" fillOpacity="0.6" />
        <Circle cx="60" cy="130" r="10" fill="#DCFCE7" fillOpacity="0.5" />

        {/* Ground shadow */}
        <Path
          d="M45 152 C 75 160, 165 160, 195 152 C 180 156, 60 156, 45 152 Z"
          fill="#CBD5E1"
          fillOpacity="0.5"
        />

        {/* Glass Milk Bottle */}
        <G>
          {/* Bottle body */}
          <Path
            d="M92 72 L92 144 C92 148 95 150 100 150 L128 150 C133 150 136 148 136 144 L136 72 C136 68 130 60 125 58 L125 44 L103 44 L103 58 C98 60 92 68 92 72 Z"
            fill="url(#bottleGrad)"
            stroke="#CBD5E1"
            strokeWidth="1.5"
          />
          {/* Milk liquid */}
          <Path
            d="M94 88 L94 143 C94 146 97 148 101 148 L127 148 C131 148 134 146 134 143 L134 88 C126 90 118 86 114 88 C108 90 100 86 94 88 Z"
            fill="#FFFFFF"
          />
          {/* Bottle Cap */}
          <Rect x="100" y="38" width="28" height="7" rx="3" fill="url(#capGrad)" />
          {/* Label on bottle */}
          <Rect x="98" y="98" width="32" height="24" rx="4" fill="#F1F5F9" />
          <Path d="M106 108 C108 104 114 104 116 108 C118 112 110 116 106 108 Z" fill="#16A34A" />
          <Rect x="104" y="115" width="20" height="2" rx="1" fill="#94A3B8" />
        </G>

        {/* Ripe Tomato / Fruit */}
        <G>
          <Circle cx="76" cy="136" r="18" fill="url(#tomatoGrad)" />
          {/* Specular highlight */}
          <Circle cx="71" cy="128" r="4" fill="#FFFFFF" fillOpacity="0.4" />
          {/* Tomato stem / calyx */}
          <Path
            d="M76 118 L74 114 M76 118 L79 115 M76 118 L72 119 M76 118 L78 120"
            stroke="#15803D"
            strokeWidth="2.5"
            strokeLinecap="round"
          />
        </G>

        {/* Fresh Carrot */}
        <G transform="rotate(22 150 120)">
          {/* Carrot body */}
          <Path
            d="M142 90 C 146 90, 158 90, 160 93 C 158 120, 144 148, 142 154 C 140 148, 134 120, 134 93 C 136 90, 139 90, 142 90 Z"
            fill="url(#carrotGrad)"
          />
          {/* Carrot ridges */}
          <Path d="M138 105 Q 144 107 148 105" stroke="#EA580C" strokeWidth="1.5" strokeLinecap="round" />
          <Path d="M137 120 Q 142 122 147 120" stroke="#EA580C" strokeWidth="1.5" strokeLinecap="round" />
          <Path d="M139 135 Q 143 137 146 135" stroke="#EA580C" strokeWidth="1.5" strokeLinecap="round" />
          {/* Green Carrot Fronds */}
          <Path
            d="M142 90 C 140 76, 132 68, 126 66 M142 90 C 144 74, 148 64, 150 60 M142 90 C 148 78, 156 70, 162 70"
            stroke="#16A34A"
            strokeWidth="2.5"
            strokeLinecap="round"
          />
        </G>

        {/* Floating Organic Green Leaves */}
        <G>
          {/* Left top leaf */}
          <Path
            d="M58 80 C 50 65, 62 50, 75 52 C 78 65, 70 80, 58 80 Z"
            fill="url(#leafGrad)"
          />
          {/* Right floating leaf */}
          <Path
            d="M178 88 C 172 74, 185 64, 195 68 C 196 78, 188 90, 178 88 Z"
            fill="url(#leafGrad)"
          />
          {/* Small sparkle dots */}
          <Circle cx="166" cy="46" r="2.5" fill="#10B981" />
          <Circle cx="76" cy="98" r="2" fill="#22C55E" />
          <Circle cx="188" cy="116" r="2.5" fill="#F59E0B" />
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
