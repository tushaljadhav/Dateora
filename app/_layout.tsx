import React, { useEffect, useState } from 'react';
import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { View, ActivityIndicator, Text, StyleSheet, AppState, Platform } from 'react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import {
  useFonts,
  Inter_400Regular,
  Inter_500Medium,
  Inter_600SemiBold,
  Inter_700Bold,
} from '@expo-google-fonts/inter';
import { ThemeProvider, useTheme } from '../src/theme';
import { initializeDatabase } from '../src/db/client';
import { useSettingsStore } from '../src/stores/useSettingsStore';
import { useItemsStore } from '../src/stores/useItemsStore';
import { DateoraLogo } from '../src/components/DateoraLogo';
import { notificationService } from '../src/services/notificationService';
import { evaluateItemStatus } from '../src/services/statusCalculator';

// Web viewport constraint fix: Ensure body and #root never exceed 100vw
if (Platform.OS === 'web' && typeof document !== 'undefined') {
  const styleId = 'dateora-web-viewport-fix';
  if (!document.getElementById(styleId)) {
    const style = document.createElement('style');
    style.id = styleId;
    style.textContent = `
      html, body {
        width: 100% !important;
        max-width: 100vw !important;
        overflow-x: hidden !important;
        margin: 0 !important;
        padding: 0 !important;
      }
      #root {
        width: 100% !important;
        max-width: 100vw !important;
        min-width: 0 !important;
        display: flex !important;
        flex-direction: column !important;
        overflow-x: hidden !important;
      }
      * {
        box-sizing: border-box;
      }
    `;
    document.head.appendChild(style);
  }
}

function RootNavigation() {
  const { theme, typography, isDark } = useTheme();

  return (
    <View style={[styles.rootContainer, { backgroundColor: theme.background }]}>
      <StatusBar style={isDark ? 'light' : 'dark'} />
      <Stack
        screenOptions={{
          headerStyle: {
            backgroundColor: theme.surface,
          },
          headerTintColor: theme.text,
          headerTitleStyle: {
            fontFamily: typography.fontFamilies.semibold,
            fontSize: 17,
            fontWeight: '600',
          },
          contentStyle: {
            backgroundColor: theme.background,
          },
          animation: 'fade_from_bottom',
        }}
      >
        <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
        <Stack.Screen
          name="add-item"
          options={{
            presentation: 'modal',
            headerShown: false,
          }}
        />
        <Stack.Screen
          name="item/[id]"
          options={{
            headerShown: false,
          }}
        />
        <Stack.Screen
          name="edit-item"
          options={{
            presentation: 'modal',
            headerShown: false,
          }}
        />
        <Stack.Screen
          name="onboarding"
          options={{
            headerShown: false,
            gestureEnabled: false,
          }}
        />
      </Stack>
    </View>
  );
}

export default function RootLayout() {
  const [dbReady, setDbReady] = useState(false);
  const [initError, setInitError] = useState<string | null>(null);

  const [fontsLoaded] = useFonts({
    Inter_400Regular,
    Inter_500Medium,
    Inter_600SemiBold,
    Inter_700Bold,
  });

  const loadSettings = useSettingsStore((s) => s.loadSettings);
  const themePref = useSettingsStore((s) => s.theme);
  const setThemePref = useSettingsStore((s) => s.setTheme);

  const loadItems = useItemsStore((s) => s.loadItems);

  useEffect(() => {
    const notifiedCatchUpIds = new Set<string>();

    async function checkCatchUpExpiredItems() {
      try {
        const activeItems = useItemsStore.getState().items;
        const expiringSoonWindowDays = useSettingsStore.getState().expiringSoonWindowDays;
        const notificationsEnabled = useSettingsStore.getState().notificationsEnabled;

        if (!notificationsEnabled) return;

        for (const item of activeItems) {
          if (item.status === 'active' && !notifiedCatchUpIds.has(item.id)) {
            const evaluation = evaluateItemStatus(item.expiryDate, expiringSoonWindowDays);
            if (evaluation.status === 'expired') {
              notifiedCatchUpIds.add(item.id);
              const daysAgo = Math.max(1, Math.abs(evaluation.daysLeft));
              await notificationService.sendCatchUpNotice(item.name, daysAgo);
              break;
            }
          }
        }
      } catch (err) {
        console.warn('Catch-up check failed:', err);
      }
    }

    async function init() {
      try {
        await initializeDatabase();
        await notificationService.initialize();
        await loadSettings();
        await loadItems();
        setDbReady(true);
        setTimeout(() => {
          checkCatchUpExpiredItems();
        }, 1200);
      } catch (err: unknown) {
        const msg = err instanceof Error ? err.message : 'Database initialization failed';
        setInitError(msg);
      }
    }
    init();

    // Re-verify expiry and check catch-up on app foreground per Rules §3
    const subscription = AppState.addEventListener('change', async (status) => {
      if (status === 'active') {
        await loadItems();
        await checkCatchUpExpiredItems();
      }
    });

    return () => subscription.remove();
  }, [loadSettings, loadItems]);

  if (initError) {
    return (
      <View style={styles.centerContainer}>
        <Text style={styles.errorTitle}>Initialization Error</Text>
        <Text style={styles.errorText}>{initError}</Text>
      </View>
    );
  }

  if (!dbReady || !fontsLoaded) {
    return (
      <View style={styles.centerContainer}>
        <DateoraLogo size={56} />
        <ActivityIndicator size="small" color="#4F46E5" style={{ marginTop: 24 }} />
        <Text style={styles.loadingText}>Opening Dateora...</Text>
      </View>
    );
  }

  return (
    <SafeAreaProvider>
      <ThemeProvider preference={themePref} onPreferenceChange={setThemePref}>
        <RootNavigation />
      </ThemeProvider>
    </SafeAreaProvider>
  );
}

const styles = StyleSheet.create({
  rootContainer: {
    flex: 1,
    width: '100%',
    maxWidth: Platform.OS === 'web' ? 480 : undefined,
    minWidth: 0,
    alignSelf: 'center',
    overflow: 'hidden',
  },
  centerContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#F8FAFF',
    padding: 24,
  },
  loadingText: {
    marginTop: 12,
    color: '#6B7280',
    fontSize: 14,
    fontWeight: '500',
  },
  errorTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: '#DC2626',
    marginBottom: 8,
  },
  errorText: {
    fontSize: 14,
    color: '#6B7280',
    textAlign: 'center',
  },
});
