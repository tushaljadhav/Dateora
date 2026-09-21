import React, { useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, SafeAreaView, Dimensions } from 'react-native';
import { useRouter } from 'expo-router';
import { useTheme } from '../src/theme';
import { useSettingsStore } from '../src/stores/useSettingsStore';
import { DateoraLogo } from '../src/components/DateoraLogo';
import { ShieldCheck, BellRing, ArrowRight, Check, Sparkles, Carrot, Milk, Pill } from 'lucide-react-native';

const { width } = Dimensions.get('window');

export default function OnboardingScreen() {
  const { theme } = useTheme();
  const router = useRouter();
  const setHasCompletedOnboarding = useSettingsStore((s) => s.setHasCompletedOnboarding);
  const setNotificationsEnabled = useSettingsStore((s) => s.setNotificationsEnabled);

  const [slide, setSlide] = useState<0 | 1>(0);

  const handleFinish = async (enableNotifications: boolean) => {
    await setNotificationsEnabled(enableNotifications);
    await setHasCompletedOnboarding(true);
    router.replace('/(tabs)/home');
  };

  return (
    <SafeAreaView style={[styles.container, { backgroundColor: theme.background }]}>
      <View style={styles.inner}>
        {/* Top Branding */}
        <View style={styles.topLogo}>
          <DateoraLogo size={32} showText textColor={theme.text} />
        </View>

        {slide === 0 ? (
          /* Slide 1: Core Value Proposition */
          <View style={styles.slideContent}>
            {/* Visual Grocery Basket Card */}
            <View style={[styles.heroCard, { backgroundColor: theme.surface, borderColor: theme.border }]}>
              <View style={styles.illustrationWrap}>
                <View style={[styles.leafCircle, { backgroundColor: 'rgba(22, 163, 74, 0.12)' }]}>
                  <DateoraLogo size={64} />
                </View>
                <View style={styles.groceryIconsRow}>
                  <View style={[styles.miniBadge, { backgroundColor: 'rgba(245, 158, 11, 0.15)' }]}>
                    <Carrot size={20} color="#F59E0B" />
                  </View>
                  <View style={[styles.miniBadge, { backgroundColor: 'rgba(22, 163, 74, 0.15)' }]}>
                    <Milk size={20} color="#16A34A" />
                  </View>
                  <View style={[styles.miniBadge, { backgroundColor: 'rgba(6, 182, 212, 0.15)' }]}>
                    <Pill size={20} color="#06B6D4" />
                  </View>
                </View>
              </View>
            </View>

            {/* Headline & Subtitle */}
            <Text style={[styles.mainHeadline, { color: theme.text }]}>
              Track Expiry Dates Effortlessly
            </Text>
            <Text style={[styles.mainSubtitle, { color: theme.textSecondary }]}>
              Keep your food, medicines and household items fresh and safe. Never let good things go to waste.
            </Text>

            {/* Pagination Dots */}
            <View style={styles.dotsRow}>
              <View style={[styles.activeDot, { backgroundColor: theme.primary }]} />
              <View style={[styles.inactiveDot, { backgroundColor: theme.border }]} />
            </View>

            {/* CTA Buttons */}
            <View style={styles.buttonGroup}>
              <TouchableOpacity
                style={[styles.primaryButton, { backgroundColor: theme.primary }]}
                onPress={() => setSlide(1)}
                activeOpacity={0.85}
              >
                <Text style={styles.primaryButtonText}>Get Started</Text>
                <ArrowRight size={18} color="#FFFFFF" />
              </TouchableOpacity>

              <TouchableOpacity
                style={styles.skipButton}
                onPress={() => handleFinish(true)}
                activeOpacity={0.7}
              >
                <Text style={[styles.skipText, { color: theme.textMuted }]}>Skip</Text>
              </TouchableOpacity>
            </View>
          </View>
        ) : (
          /* Slide 2: Smart Alerts Context */
          <View style={styles.slideContent}>
            <View style={[styles.heroCard, { backgroundColor: theme.surface, borderColor: theme.border }]}>
              <View style={styles.illustrationWrap}>
                <View style={[styles.leafCircle, { backgroundColor: 'rgba(245, 158, 11, 0.14)' }]}>
                  <BellRing size={52} color="#F59E0B" />
                </View>
              </View>
            </View>

            <Text style={[styles.mainHeadline, { color: theme.text }]}>
              Smart Offline Reminders
            </Text>
            <Text style={[styles.mainSubtitle, { color: theme.textSecondary }]}>
              Get timely notifications before items expire. 100% private, offline-first, with zero cloud tracking.
            </Text>

            {/* Pagination Dots */}
            <View style={styles.dotsRow}>
              <View style={[styles.inactiveDot, { backgroundColor: theme.border }]} />
              <View style={[styles.activeDot, { backgroundColor: theme.primary }]} />
            </View>

            {/* CTA Buttons */}
            <View style={styles.buttonGroup}>
              <TouchableOpacity
                style={[styles.primaryButton, { backgroundColor: theme.primary }]}
                onPress={() => handleFinish(true)}
                activeOpacity={0.85}
              >
                <Text style={styles.primaryButtonText}>Enable Reminders</Text>
                <Check size={18} color="#FFFFFF" />
              </TouchableOpacity>

              <TouchableOpacity
                style={styles.skipButton}
                onPress={() => handleFinish(false)}
                activeOpacity={0.7}
              >
                <Text style={[styles.skipText, { color: theme.textMuted }]}>Maybe later</Text>
              </TouchableOpacity>
            </View>
          </View>
        )}
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  inner: {
    flex: 1,
    padding: 24,
    justifyContent: 'space-between',
  },
  topLogo: {
    alignItems: 'center',
    marginTop: 12,
  },
  slideContent: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 20,
  },
  heroCard: {
    width: '100%',
    aspectRatio: 1.2,
    borderRadius: 24,
    borderWidth: 1,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 32,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.05,
    shadowRadius: 12,
    elevation: 2,
  },
  illustrationWrap: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  leafCircle: {
    width: 100,
    height: 100,
    borderRadius: 50,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 16,
  },
  groceryIconsRow: {
    flexDirection: 'row',
    gap: 12,
  },
  miniBadge: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
  },
  mainHeadline: {
    fontSize: 24,
    fontWeight: '800',
    textAlign: 'center',
    letterSpacing: -0.4,
    marginBottom: 10,
    paddingHorizontal: 8,
  },
  mainSubtitle: {
    fontSize: 15,
    textAlign: 'center',
    lineHeight: 22,
    paddingHorizontal: 16,
    marginBottom: 24,
  },
  dotsRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginBottom: 32,
  },
  activeDot: {
    width: 24,
    height: 8,
    borderRadius: 4,
  },
  inactiveDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
  },
  buttonGroup: {
    width: '100%',
    gap: 12,
  },
  primaryButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    height: 54,
    borderRadius: 14,
    gap: 8,
    shadowColor: '#16A34A',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.25,
    shadowRadius: 10,
    elevation: 3,
  },
  primaryButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '700',
  },
  skipButton: {
    alignItems: 'center',
    paddingVertical: 10,
  },
  skipText: {
    fontSize: 14,
    fontWeight: '600',
  },
});
