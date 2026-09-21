import React from 'react';
import { View, StyleSheet, Text, ViewStyle } from 'react-native';
import { useTheme } from '../theme';
import { getCategoryVisual } from '../theme/categoryVisuals';

interface CategoryBadgeProps {
  category: string;
  size?: 'sm' | 'md' | 'lg' | 'xl';
  useEmoji?: boolean;
  style?: ViewStyle;
}

export const CategoryBadge: React.FC<CategoryBadgeProps> = ({
  category,
  size = 'md',
  useEmoji = false,
  style,
}) => {
  const { isDark } = useTheme();
  const visual = getCategoryVisual(category);
  const IconComponent = visual.icon;

  const sizeMetrics = {
    sm: { container: 36, iconSize: 18, emojiSize: 18, radius: 10 },
    md: { container: 44, iconSize: 22, emojiSize: 22, radius: 12 },
    lg: { container: 54, iconSize: 28, emojiSize: 28, radius: 16 },
    xl: { container: 72, iconSize: 36, emojiSize: 36, radius: 20 },
  }[size];

  const bgColor = isDark ? visual.bgColorDark : visual.bgColorLight;
  const borderColor = isDark ? visual.borderColorDark : visual.borderColorLight;

  return (
    <View
      style={[
        styles.container,
        {
          width: sizeMetrics.container,
          height: sizeMetrics.container,
          borderRadius: sizeMetrics.radius,
          backgroundColor: bgColor,
          borderColor: borderColor,
        },
        style,
      ]}
    >
      {useEmoji ? (
        <Text style={{ fontSize: sizeMetrics.emojiSize }}>{visual.emoji}</Text>
      ) : (
        <IconComponent size={sizeMetrics.iconSize} color={visual.color} />
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    borderWidth: 1,
    alignItems: 'center',
    justifyContent: 'center',
    flexShrink: 0,
  },
});
