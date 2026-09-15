import React, { useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, SafeAreaView } from 'react-native';
import { useRouter } from 'expo-router';
import { useTheme } from '../src/theme';
import { useSettingsStore } from '../src/stores/useSettingsStore';
import { ShieldCheck, BellRing, ArrowRight, Check } from 'lucide-react-native';

export default function OnboardingScreen() {
  const { theme } = useTheme();
  const router = useRouter();
  const setHasCompletedOnboarding = useSettingsStore((s) => s.setHasCompletedOnboarding);
  const setNotificationsEnabled = useSettingsStore((s) => s.setNotificationsEnabled);

  const [step, setStep] = useState<1 | 2>(1);

  const handleFinish = async (enableNotifications: boolean) => {
    await setNotificationsEnabled(enableNotifications);
    await setHasCompletedOnboarding(true);
    router.replace('/(tabs)/home');
  };

  return (
    <SafeAreaView style={[styles.container, { backgroundColor: theme.background }]}>
      <View style={styles.content}>
        {/* Step indicator */}
        <View style={styles.stepIndicatorRow}>
          <View style={[styles.stepDot, { backgroundColor: theme.primary }]} />
          <View
            style={[
              styles.stepDot,
              { backgroundColor: step === 2 ? theme.primary : theme.surfaceSubtle },
            ]}
          />
        </View>

        {step === 1 ? (
          /* Step 1: What Dateora does & No login promise */
          <View style={styles.stepContent}>
            <View style={[styles.iconCircle, { backgroundColor: theme.surfaceSubtle }]}>
              <ShieldCheck size={48} color={theme.primary} />
            </View>

            <Text style={[styles.title, { color: theme.text }]}>Welcome to Dateora</Text>
            <Text style={[styles.description, { color: theme.textSecondary }]}>
              Stop throwing away money and using expired medicine. Track groceries, skincare, documents, and pantry goods in one offline-first place.
            </Text>

            <View style={[styles.promiseCard, { backgroundColor: theme.surface, borderColor: theme.border }]}>
              <Text style={[styles.promiseTitle, { color: theme.primary }]}>🔒 No Account Needed</Text>
              <Text style={[styles.promiseText, { color: theme.textMuted }]}>
                100% private. All your data stays on this device. No logins, no tracking, works in airplane mode.
              </Text>
            </View>

            <View style={styles.bottomBar}>
              <TouchableOpacity
                style={[styles.primaryButton, { backgroundColor: theme.primary }]}
                onPress={() => setStep(2)}
              >
                <Text style={styles.primaryButtonText}>Continue</Text>
                <ArrowRight size={18} color="#FFFFFF" />
              </TouchableOpacity>
            </View>
          </View>
        ) : (
          /* Step 2: Contextual Notification Permission */
          <View style={styles.stepContent}>
            <View style={[styles.iconCircle, { backgroundColor: '#FEF3C7' }]}>
              <BellRing size={48} color={theme.warningDark} />
            </View>

            <Text style={[styles.title, { color: theme.text }]}>Stay Ahead of Expiries</Text>
            <Text style={[styles.description, { color: theme.textSecondary }]}>
              Dateora reminds you before things expire so you can use them in time.
            </Text>

            <View style={[styles.permissionCard, { backgroundColor: theme.surface, borderColor: theme.border }]}>
              <Text style={[styles.permissionContext, { color: theme.text }]}>
                "Dateora reminds you before things expire — allow notifications?"
              </Text>
              <Text style={[styles.permissionFootnote, { color: theme.textMuted }]}>
                You can change this or adjust your daily alert time anytime in Settings.
              </Text>
            </View>

            <View style={styles.bottomBar}>
              <TouchableOpacity
                style={[styles.primaryButton, { backgroundColor: theme.primary }]}
                onPress={() => handleFinish(true)}
              >
                <Text style={styles.primaryButtonText}>Enable Reminders</Text>
                <Check size={18} color="#FFFFFF" />
              </TouchableOpacity>

              <TouchableOpacity style={styles.skipButton} onPress={() => handleFinish(false)}>
                <Text style={[styles.skipButtonText, { color: theme.textMuted }]}>Not now, maybe later</Text>
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
  content: {
    flex: 1,
    padding: 24,
    justifyContent: 'space-between',
  },
  stepIndicatorRow: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: 8,
    marginTop: 16,
  },
  stepDot: {
    width: 24,
    height: 4,
    borderRadius: 2,
  },
  stepContent: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 8,
  },
  iconCircle: {
    width: 96,
    height: 96,
    borderRadius: 48,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 24,
  },
  title: {
    fontSize: 24,
    fontWeight: '700',
    textAlign: 'center',
    marginBottom: 12,
  },
  description: {
    fontSize: 15,
    textAlign: 'center',
    lineHeight: 22,
    marginBottom: 24,
  },
  promiseCard: {
    borderRadius: 12,
    borderWidth: 1,
    padding: 16,
    width: '100%',
  },
  promiseTitle: {
    fontSize: 14,
    fontWeight: '700',
    marginBottom: 4,
  },
  promiseText: {
    fontSize: 13,
    lineHeight: 18,
  },
  permissionCard: {
    borderRadius: 12,
    borderWidth: 1,
    padding: 18,
    width: '100%',
  },
  permissionContext: {
    fontSize: 15,
    fontWeight: '600',
    lineHeight: 22,
    marginBottom: 8,
    textAlign: 'center',
  },
  permissionFootnote: {
    fontSize: 12,
    textAlign: 'center',
    lineHeight: 16,
  },
  bottomBar: {
    width: '100%',
    marginTop: 32,
    gap: 12,
  },
  primaryButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    height: 50,
    borderRadius: 8,
    gap: 8,
  },
  primaryButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
  },
  skipButton: {
    alignItems: 'center',
    paddingVertical: 10,
  },
  skipButtonText: {
    fontSize: 14,
  },
});
