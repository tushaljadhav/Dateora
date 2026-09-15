import React, { useEffect, useState, useMemo } from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, Alert, ActivityIndicator } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { useTheme } from '../../src/theme';
import { useItemsStore } from '../../src/stores/useItemsStore';
import { useSettingsStore } from '../../src/stores/useSettingsStore';
import { evaluateItemStatus, formatDisplayDate } from '../../src/services/statusCalculator';
import { Item, ItemLifecycleStatus } from '../../src/types/item';
import {
  Calendar,
  Clock,
  MapPin,
  FileText,
  Trash2,
  CheckCircle2,
  XCircle,
  Package,
  Layers,
  ChevronLeft,
} from 'lucide-react-native';

export default function ItemDetailsScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { theme } = useTheme();
  const router = useRouter();

  const items = useItemsStore((s) => s.items);
  const markItemStatus = useItemsStore((s) => s.markItemStatus);
  const deleteItem = useItemsStore((s) => s.deleteItem);
  const expiringSoonWindowDays = useSettingsStore((s) => s.expiringSoonWindowDays);

  const item = useMemo(() => items.find((i) => i.id === id), [items, id]);

  if (!item) {
    return (
      <View style={[styles.centerContainer, { backgroundColor: theme.background }]}>
        <Text style={[styles.notFoundText, { color: theme.textSecondary }]}>Item not found or already archived.</Text>
        <TouchableOpacity
          style={[styles.backButton, { backgroundColor: theme.primary }]}
          onPress={() => router.back()}
        >
          <Text style={styles.backButtonText}>Return</Text>
        </TouchableOpacity>
      </View>
    );
  }

  const evaluation = evaluateItemStatus(item.expiryDate, expiringSoonWindowDays);

  const handleMarkStatus = (status: 'used' | 'finished' | 'disposed') => {
    const titles: Record<string, string> = {
      used: 'Mark as Used',
      finished: 'Mark as Finished',
      disposed: 'Mark as Disposed',
    };

    Alert.alert(
      titles[status],
      `Move "${item.name}" to History under ${status}?`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Confirm',
          onPress: async () => {
            await markItemStatus(item.id, status);
            router.back();
          },
        },
      ]
    );
  };

  const handleDelete = () => {
    Alert.alert(
      'Delete Item',
      `Permanently delete "${item.name}"? This removes all scheduled reminders.`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: async () => {
            await deleteItem(item.id);
            router.back();
          },
        },
      ]
    );
  };

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      <ScrollView contentContainerStyle={styles.scrollContent}>
        {/* Top Header Card */}
        <View style={[styles.headerCard, { backgroundColor: theme.surface, borderColor: theme.border }]}>
          <View style={styles.headerTop}>
            <View style={[styles.categoryIconCircle, { backgroundColor: theme.surfaceSubtle }]}>
              <Package size={28} color={theme.primary} />
            </View>
            <View
              style={[
                styles.statusBadge,
                { backgroundColor: evaluation.badgeBg, borderColor: evaluation.borderColor },
              ]}
            >
              <Text style={[styles.statusBadgeText, { color: evaluation.textColor }]}>
                {evaluation.label}
              </Text>
            </View>
          </View>

          <Text style={[styles.itemName, { color: theme.text }]}>{item.name}</Text>
          <Text style={[styles.itemCategory, { color: theme.textMuted }]}>{item.category}</Text>

          <View style={[styles.countdownBox, { backgroundColor: theme.surfaceSubtle, borderColor: theme.border }]}>
            <Clock size={16} color={evaluation.textColor} />
            <Text style={[styles.countdownText, { color: evaluation.textColor }]}>
              {evaluation.relativeText}
            </Text>
          </View>
        </View>

        {/* Details Grid */}
        <View style={[styles.card, { backgroundColor: theme.surface, borderColor: theme.border }]}>
          <Text style={[styles.sectionTitle, { color: theme.text }]}>Item Details</Text>

          <View style={styles.detailRow}>
            <Calendar size={18} color={theme.textMuted} />
            <View style={styles.detailTextCol}>
              <Text style={[styles.detailLabel, { color: theme.textMuted }]}>Expiry Date</Text>
              <Text style={[styles.detailValue, { color: theme.text }]}>
                {formatDisplayDate(item.expiryDate)} ({item.expiryDate})
              </Text>
            </View>
          </View>

          {(item.quantity !== null || item.unit) && (
            <View style={styles.detailRow}>
              <Layers size={18} color={theme.textMuted} />
              <View style={styles.detailTextCol}>
                <Text style={[styles.detailLabel, { color: theme.textMuted }]}>Quantity</Text>
                <Text style={[styles.detailValue, { color: theme.text }]}>
                  {item.quantity ?? ''} {item.unit ?? ''}
                </Text>
              </View>
            </View>
          )}

          {item.location && (
            <View style={styles.detailRow}>
              <MapPin size={18} color={theme.textMuted} />
              <View style={styles.detailTextCol}>
                <Text style={[styles.detailLabel, { color: theme.textMuted }]}>Storage Location</Text>
                <Text style={[styles.detailValue, { color: theme.text }]}>{item.location}</Text>
              </View>
            </View>
          )}

          {item.notes && (
            <View style={styles.detailRow}>
              <FileText size={18} color={theme.textMuted} />
              <View style={styles.detailTextCol}>
                <Text style={[styles.detailLabel, { color: theme.textMuted }]}>Notes</Text>
                <Text style={[styles.detailValue, { color: theme.text }]}>{item.notes}</Text>
              </View>
            </View>
          )}

          <View style={styles.detailRow}>
            <Clock size={18} color={theme.textMuted} />
            <View style={styles.detailTextCol}>
              <Text style={[styles.detailLabel, { color: theme.textMuted }]}>Active Reminders</Text>
              <Text style={[styles.detailValue, { color: theme.text }]}>
                {item.reminderOffsets.length > 0
                  ? item.reminderOffsets.map((o) => (o === 0 ? 'Day of expiry' : `${o}d before`)).join(', ')
                  : 'No reminders set'}
              </Text>
            </View>
          </View>
        </View>

        {/* Mark As Actions (PRD §4.4: 3 distinct outcomes) */}
        <Text style={[styles.sectionHeading, { color: theme.textMuted }]}>LIFECYCLE ACTIONS</Text>
        <View style={styles.markActionsRow}>
          <TouchableOpacity
            style={[styles.markButton, { backgroundColor: '#DCFCE7', borderColor: '#86EFAC' }]}
            onPress={() => handleMarkStatus('used')}
          >
            <CheckCircle2 size={16} color={theme.successDark} />
            <Text style={[styles.markButtonText, { color: theme.successDark }]}>Mark Used</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.markButton, { backgroundColor: '#E0F2FE', borderColor: '#7DD3FC' }]}
            onPress={() => handleMarkStatus('finished')}
          >
            <CheckCircle2 size={16} color={theme.accent} />
            <Text style={[styles.markButtonText, { color: theme.accent }]}>Finished</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.markButton, { backgroundColor: '#FEE2E2', borderColor: '#FCA5A5' }]}
            onPress={() => handleMarkStatus('disposed')}
          >
            <XCircle size={16} color={theme.danger} />
            <Text style={[styles.markButtonText, { color: theme.danger }]}>Disposed</Text>
          </TouchableOpacity>
        </View>

        {/* Delete Item */}
        <TouchableOpacity
          style={[styles.deleteButton, { borderColor: theme.danger }]}
          onPress={handleDelete}
        >
          <Trash2 size={16} color={theme.danger} />
          <Text style={[styles.deleteButtonText, { color: theme.danger }]}>Delete Item</Text>
        </TouchableOpacity>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  centerContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 24,
  },
  notFoundText: {
    fontSize: 16,
    marginBottom: 16,
  },
  backButton: {
    paddingHorizontal: 20,
    paddingVertical: 10,
    borderRadius: 8,
  },
  backButtonText: {
    color: '#FFFFFF',
    fontWeight: '600',
  },
  scrollContent: {
    padding: 16,
    paddingBottom: 40,
  },
  headerCard: {
    borderRadius: 12,
    borderWidth: 1,
    padding: 20,
    marginBottom: 16,
  },
  headerTop: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  categoryIconCircle: {
    width: 48,
    height: 48,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  statusBadge: {
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 9999,
    borderWidth: 1,
  },
  statusBadgeText: {
    fontSize: 12,
    fontWeight: '600',
  },
  itemName: {
    fontSize: 22,
    fontWeight: '700',
    marginBottom: 4,
  },
  itemCategory: {
    fontSize: 14,
    marginBottom: 16,
  },
  countdownBox: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    padding: 10,
    borderRadius: 8,
    borderWidth: 1,
  },
  countdownText: {
    fontSize: 14,
    fontWeight: '600',
  },
  card: {
    borderRadius: 12,
    borderWidth: 1,
    padding: 16,
    marginBottom: 16,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: '600',
    marginBottom: 16,
  },
  detailRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 12,
    marginBottom: 14,
  },
  detailTextCol: {
    flex: 1,
  },
  detailLabel: {
    fontSize: 12,
    marginBottom: 2,
  },
  detailValue: {
    fontSize: 14,
    fontWeight: '500',
  },
  sectionHeading: {
    fontSize: 12,
    fontWeight: '600',
    letterSpacing: 0.5,
    marginBottom: 8,
    marginTop: 4,
    paddingHorizontal: 4,
  },
  markActionsRow: {
    flexDirection: 'row',
    gap: 8,
    marginBottom: 16,
  },
  markButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 12,
    borderRadius: 8,
    borderWidth: 1,
    gap: 6,
  },
  markButtonText: {
    fontSize: 13,
    fontWeight: '600',
  },
  deleteButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 12,
    borderRadius: 8,
    borderWidth: 1,
    gap: 6,
    marginTop: 8,
  },
  deleteButtonText: {
    fontSize: 14,
    fontWeight: '600',
  },
});
