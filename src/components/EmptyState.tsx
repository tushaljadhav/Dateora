import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ViewStyle, Image } from 'react-native';
import { useTheme } from '../theme';
import { DateoraLogo } from './DateoraLogo';
import { Plus } from 'lucide-react-native';

const ILLUSTRATIONS = {
  basket: require('../../assets/illustrations/empty_basket.png'),
  groceries: require('../../assets/illustrations/groceries_hero.png'),
  bell: require('../../assets/illustrations/bell_hero.png'),
  shield: require('../../assets/illustrations/shield_hero.png'),
};

interface EmptyStateProps {
  title?: string;
  subtitle?: string;
  actionLabel?: string;
  onAction?: () => void;
  icon?: React.ReactNode;
  illustration?: keyof typeof ILLUSTRATIONS;
  style?: ViewStyle;
}

export const EmptyState: React.FC<EmptyStateProps> = ({
  title = 'No items yet',
  subtitle = 'Start tracking your items to keep them fresh and safe.',
  actionLabel,
  onAction,
  icon,
  illustration = 'basket',
  style,
}) => {
  const { theme, isDark } = useTheme();

  return (
    <View
      style={[
        styles.container,
        {
          backgroundColor: theme.surface,
          borderColor: theme.border,
        },
        style,
      ]}
    >
      {illustration && ILLUSTRATIONS[illustration] ? (
        <View style={styles.illustrationWrapper}>
          <Image
            source={ILLUSTRATIONS[illustration]}
            style={styles.illustrationImage}
            resizeMode="contain"
          />
        </View>
      ) : (
        <View
          style={[
            styles.iconCircle,
            {
              backgroundColor: isDark ? 'rgba(34, 197, 94, 0.15)' : '#DCFCE7',
            },
          ]}
        >
          {icon || <DateoraLogo size={36} />}
        </View>
      )}

      <Text style={[styles.title, { color: theme.text }]}>{title}</Text>
      <Text style={[styles.subtitle, { color: theme.textSecondary }]}>
        {subtitle}
      </Text>

      {actionLabel && onAction && (
        <TouchableOpacity
          style={[styles.actionButton, { backgroundColor: theme.primary }]}
          onPress={onAction}
          activeOpacity={0.85}
        >
          <Plus size={18} color="#FFFFFF" strokeWidth={2.5} />
          <Text style={styles.actionButtonText}>{actionLabel}</Text>
        </TouchableOpacity>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    padding: 24,
    borderRadius: 20,
    borderWidth: 1,
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.04,
    shadowRadius: 10,
    elevation: 2,
  },
  illustrationWrapper: {
    width: 120,
    height: 120,
    borderRadius: 60,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 14,
    overflow: 'hidden',
  },
  illustrationImage: {
    width: 110,
    height: 110,
  },
  iconCircle: {
    width: 64,
    height: 64,
    borderRadius: 32,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 16,
  },
  title: {
    fontSize: 18,
    fontWeight: '700',
    textAlign: 'center',
    marginBottom: 6,
    letterSpacing: -0.3,
  },
  subtitle: {
    fontSize: 14,
    lineHeight: 20,
    textAlign: 'center',
    maxWidth: 280,
    marginBottom: 16,
  },
  actionButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 20,
    paddingVertical: 12,
    borderRadius: 12,
    marginTop: 4,
  },
  actionButtonText: {
    color: '#FFFFFF',
    fontSize: 15,
    fontWeight: '600',
  },
});
