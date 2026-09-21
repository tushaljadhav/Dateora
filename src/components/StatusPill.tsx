import React from 'react';
import { View, Text, StyleSheet, ViewStyle } from 'react-native';
import { useTheme } from '../theme';

interface StatusPillProps {
  daysLeft: number;
  status: 'expired' | 'expiring_soon' | 'safe';
  label?: string;
  style?: ViewStyle;
}

export const StatusPill: React.FC<StatusPillProps> = ({
  daysLeft,
  status,
  label,
  style,
}) => {
  const { isDark } = useTheme();

  let text = label;
  let bg = '#DCFCE7';
  let color = '#15803D';
  let dotColor = '#16A34A';

  if (status === 'expired') {
    text = text || 'Expired';
    bg = isDark ? 'rgba(239, 68, 68, 0.22)' : '#FEE2E2';
    color = isDark ? '#F87171' : '#DC2626';
    dotColor = '#EF4444';
  } else if (daysLeft === 0) {
    text = text || 'Today';
    bg = isDark ? 'rgba(239, 68, 68, 0.22)' : '#FEE2E2';
    color = isDark ? '#F87171' : '#DC2626';
    dotColor = '#EF4444';
  } else if (daysLeft === 1) {
    text = text || '1 day';
    bg = isDark ? 'rgba(245, 158, 11, 0.22)' : '#FEF3C7';
    color = isDark ? '#FBBF24' : '#D97706';
    dotColor = '#F59E0B';
  } else if (status === 'expiring_soon') {
    text = text || `${daysLeft} days`;
    bg = isDark ? 'rgba(245, 158, 11, 0.22)' : '#FEF3C7';
    color = isDark ? '#FBBF24' : '#D97706';
    dotColor = '#F59E0B';
  } else {
    text = text || (daysLeft > 0 ? `${daysLeft} days` : 'Safe');
    bg = isDark ? 'rgba(34, 197, 94, 0.20)' : '#DCFCE7';
    color = isDark ? '#34D399' : '#15803D';
    dotColor = '#16A34A';
  }

  return (
    <View style={[styles.pill, { backgroundColor: bg }, style]}>
      <View style={[styles.dot, { backgroundColor: dotColor }]} />
      <Text style={[styles.text, { color }]}>{text}</Text>
    </View>
  );
};

const styles = StyleSheet.create({
  pill: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 9,
    paddingVertical: 4,
    borderRadius: 9999,
    gap: 5,
    flexShrink: 0,
  },
  dot: {
    width: 6,
    height: 6,
    borderRadius: 3,
  },
  text: {
    fontSize: 12,
    fontWeight: '600',
    letterSpacing: -0.2,
  },
});
