import React from 'react';
import { View, Text, StyleSheet, ViewStyle } from 'react-native';
import { CheckCircle, Clock, WarningCircle } from 'phosphor-react-native';
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
  const { theme } = useTheme();

  let text = label;
  let bg = theme.status.safe.bg;
  let color = theme.status.safe.color;
  let IconComponent = CheckCircle;

  if (status === 'expired') {
    text = text || (daysLeft < 0 ? `Expired (${Math.abs(daysLeft)}d ago)` : 'Expired');
    bg = theme.status.expired.bg;
    color = theme.status.expired.color;
    IconComponent = WarningCircle;
  } else if (daysLeft === 0) {
    text = text || 'Expires today';
    bg = theme.status.expired.bg;
    color = theme.status.expired.color;
    IconComponent = WarningCircle;
  } else if (daysLeft === 1) {
    text = text || '1 day left';
    bg = theme.status.expiring.bg;
    color = theme.status.expiring.color;
    IconComponent = Clock;
  } else if (status === 'expiring_soon') {
    text = text || `${daysLeft} days left`;
    bg = theme.status.expiring.bg;
    color = theme.status.expiring.color;
    IconComponent = Clock;
  } else {
    text = text || `${daysLeft} days left`;
    bg = theme.status.safe.bg;
    color = theme.status.safe.color;
    IconComponent = CheckCircle;
  }

  return (
    <View style={[styles.pill, { backgroundColor: bg }, style]}>
      <IconComponent size={13} color={color} weight="fill" />
      <Text style={[styles.text, { color }]}>{text}</Text>
    </View>
  );
};

const styles = StyleSheet.create({
  pill: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 999,
    gap: 4,
    flexShrink: 0,
  },
  text: {
    fontSize: 11,
    lineHeight: 14,
    fontWeight: '600',
    letterSpacing: 0.1,
  },
});
