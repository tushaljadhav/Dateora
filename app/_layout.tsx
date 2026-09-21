import React, { useEffect, useState } from 'react';
import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { View, ActivityIndicator, Text, StyleSheet, AppState } from 'react-native';
import { ThemeProvider, useTheme } from '../src/theme';
import { initializeDatabase } from '../src/db/client';
import { useSettingsStore } from '../src/stores/useSettingsStore';
import { useItemsStore } from '../src/stores/useItemsStore';

function RootNavigation() {
  const { theme, isDark } = useTheme();

  return (
    <>
      <StatusBar style={isDark ? 'light' : 'dark'} />
      <Stack
        screenOptions={{
          headerStyle: {
            backgroundColor: theme.surface,
          },
          headerTintColor: theme.text,
          headerTitleStyle: {
            fontWeight: '600',
          },
          contentStyle: {
            backgroundColor: theme.background,
          },
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
          name="onboarding"
          options={{
            headerShown: false,
            gestureEnabled: false,
          }}
        />
      </Stack>
    </>
  );
}

export default function RootLayout() {
  const [dbReady, setDbReady] = useState(false);
  const [initError, setInitError] = useState<string | null>(null);
  const loadSettings = useSettingsStore((s) => s.loadSettings);
  const themePref = useSettingsStore((s) => s.theme);
  const setThemePref = useSettingsStore((s) => s.setTheme);

  const loadItems = useItemsStore((s) => s.loadItems);

  useEffect(() => {
    async function init() {
      try {
        await initializeDatabase();
        await loadSettings();
        await loadItems();
        setDbReady(true);
      } catch (err: unknown) {
        const msg = err instanceof Error ? err.message : 'Database initialization failed';
        setInitError(msg);
      }
    }
    init();

    // Re-verify expiry on app foreground per Rules §3
    const subscription = AppState.addEventListener('change', async (status) => {
      if (status === 'active') {
        await loadItems();
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

  if (!dbReady) {
    return (
      <View style={styles.centerContainer}>
        <ActivityIndicator size="large" color="#2563EB" />
        <Text style={styles.loadingText}>Preparing Dateora...</Text>
      </View>
    );
  }

  return (
    <ThemeProvider preference={themePref} onPreferenceChange={setThemePref}>
      <RootNavigation />
    </ThemeProvider>
  );
}

const styles = StyleSheet.create({
  centerContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#F8FAFC',
    padding: 24,
  },
  loadingText: {
    marginTop: 16,
    color: '#64748B',
    fontSize: 15,
  },
  errorTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#EF4444',
    marginBottom: 8,
  },
  errorText: {
    fontSize: 14,
    color: '#64748B',
    textAlign: 'center',
  },
});
