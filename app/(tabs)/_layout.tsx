import React from 'react';
import { Tabs } from 'expo-router';
import { useTheme } from '../../src/theme';
import { Home, Package, Calendar, History, Settings } from 'lucide-react-native';

export default function TabLayout() {
  const { theme } = useTheme();

  return (
    <Tabs
      screenOptions={{
        tabBarActiveTintColor: theme.primary,
        tabBarInactiveTintColor: theme.textMuted,
        tabBarStyle: {
          backgroundColor: theme.tabBarBackground,
          borderTopColor: theme.tabBarBorder,
          borderTopWidth: 1,
          height: 60,
          paddingBottom: 8,
          paddingTop: 6,
        },
        tabBarLabelStyle: {
          fontSize: 11,
          fontWeight: '500',
        },
        headerStyle: {
          backgroundColor: theme.surface,
        },
        headerTintColor: theme.text,
        headerTitleStyle: {
          fontWeight: '600',
        },
      }}
    >
      <Tabs.Screen
        name="home"
        options={{
          title: 'Home',
          headerTitle: 'Dateora',
          tabBarIcon: ({ color, size }) => <Home color={color} size={size || 22} />,
        }}
      />
      <Tabs.Screen
        name="items"
        options={{
          title: 'Items',
          headerTitle: 'All Items',
          tabBarIcon: ({ color, size }) => <Package color={color} size={size || 22} />,
        }}
      />
      <Tabs.Screen
        name="calendar"
        options={{
          title: 'Calendar',
          headerTitle: 'Expiry Calendar',
          tabBarIcon: ({ color, size }) => <Calendar color={color} size={size || 22} />,
        }}
      />
      <Tabs.Screen
        name="history"
        options={{
          title: 'History',
          headerTitle: 'Item History',
          tabBarIcon: ({ color, size }) => <History color={color} size={size || 22} />,
        }}
      />
      <Tabs.Screen
        name="settings"
        options={{
          title: 'Settings',
          headerTitle: 'Settings',
          tabBarIcon: ({ color, size }) => <Settings color={color} size={size || 22} />,
        }}
      />
    </Tabs>
  );
}
