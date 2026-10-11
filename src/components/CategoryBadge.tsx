import React from 'react';
import { View, StyleSheet, Text, ViewStyle } from 'react-native';
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
  const visual = getCategoryVisual(category);
  const IconComponent = visual.icon;

  const sizeMetrics = {
    sm: { container: 32, iconSize: 18, emojiSize: 15, radius: 999 },
    md: { container: 42, iconSize: 22, emojiSize: 18, radius: 999 },
    lg: { container: 50, iconSize: 26, emojiSize: 22, radius: 999 },
    xl: { container: 64, iconSize: 32, emojiSize: 28, radius: 999 },
  }[size];

  return (
    <View
      style={[
        styles.container,
        {
          width: sizeMetrics.container,
          height: sizeMetrics.container,
          borderRadius: sizeMetrics.radius,
          backgroundColor: visual.bgColor,
          borderColor: visual.borderColor,
        },
        style,
      ]}
    >
      {useEmoji ? (
        <Text style={{ fontSize: sizeMetrics.emojiSize }}>{visual.emoji}</Text>
      ) : (
        <IconComponent size={sizeMetrics.iconSize} color={visual.color} weight="duotone" />
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
