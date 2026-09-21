import React, { useMemo, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
  Platform,
  Switch,
} from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { useTheme } from '../../src/theme';
import { useItemsStore } from '../../src/stores/useItemsStore';
import { useSettingsStore } from '../../src/stores/useSettingsStore';
import { evaluateItemStatus, formatDisplayDate } from '../../src/services/statusCalculator';
import {
  ArrowLeft,
  Calendar,
  Clock,
  MapPin,
  FileText,
  Trash2,
  CheckCircle2,
  XCircle,
  Package,
  Layers,
  Bell,
  Milk,
  Pill,
  Sparkle,
  Home,
  Coffee,
  HelpCircle,
  Archive,
} from 'lucide-react-native';
import { StatusPill } from '../../src/components/StatusPill';

export default function ItemDetailsScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { theme, isDark } = useTheme();
  const router = useRouter();

  const items = useItemsStore((s) => s.items);
  const markItemStatus = useItemsStore((s) => s.markItemStatus);
  const deleteItem = useItemsStore((s) => s.deleteItem);
  const expiringSoonWindowDays = useSettingsStore((s) => s.expiringSoonWindowDays);

  const item = useMemo(() => items.find((i) => i.id === id), [items, id]);
  const [remindMe, setRemindMe] = useState(true);

  if (!item) {
    return (
      <View style={[styles.centerContainer, { backgroundColor: theme.background }]}>
        <Text style={[styles.notFoundText, { color: theme.textSecondary }]}>
          Item not found or already archived.
        </Text>
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

    if (Platform.OS === 'web') {
      const confirmed = window.confirm(`Move "${item.name}" to History under ${status}?`);
      if (confirmed) {
        markItemStatus(item.id, status).then(() => {
          router.back();
        });
      }
      return;
    }

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
    if (Platform.OS === 'web') {
      const confirmed = window.confirm(
        `Permanently delete "${item.name}"? This removes all scheduled reminders.`
      );
      if (confirmed) {
        deleteItem(item.id).then(() => {
          router.back();
        });
      }
      return;
    }

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

  const getCategoryIcon = (category: string) => {
    switch (category.toLowerCase()) {
      case 'groceries':
      case 'food':
        return <Milk size={32} color={theme.primary} />;
      case 'medicine':
        return <Pill size={32} color="#06B6D4" />;
      case 'skincare':
      case 'cosmetics':
        return <Sparkle size={32} color="#EC4899" />;
      case 'household':
        return <Home size={32} color="#8B5CF6" />;
      case 'beverages':
        return <Coffee size={32} color="#F59E0B" />;
      default:
        return <Package size={32} color={theme.primary} />;
    }
  };

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      {/* Top Header */}
      <View style={[styles.headerBar, { backgroundColor: theme.surface, borderBottomColor: theme.border }]}>
        <TouchableOpacity style={styles.backBtn} onPress={() => router.back()} activeOpacity={0.7}>
          <ArrowLeft size={22} color={theme.text} />
        </TouchableOpacity>
        <Text style={[styles.headerTitle, { color: theme.text }]}>Item Details</Text>
        <TouchableOpacity style={styles.backBtn} onPress={handleDelete}>
          <Trash2 size={20} color={theme.danger} />
        </TouchableOpacity>
      </View>

      <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
        {/* Hero Card */}
        <View style={[styles.heroCard, { backgroundColor: theme.surface, borderColor: theme.border }]}>
          <View style={[styles.heroIconCircle, { backgroundColor: theme.surfaceSubtle }]}>
            {getCategoryIcon(item.category)}
          </View>

          <View style={styles.heroTitleRow}>
            <View style={styles.heroTextCol}>
              <Text style={[styles.itemName, { color: theme.text }]}>{item.name}</Text>
              <View style={[styles.categoryTag, { backgroundColor: isDark ? 'rgba(34, 197, 94, 0.15)' : '#DCFCE7' }]}>
                <Text style={[styles.categoryTagText, { color: theme.primary }]}>@ {item.category}</Text>
              </View>
            </View>

            <StatusPill
              daysLeft={evaluation.daysLeft}
              status={evaluation.status}
            />
          </View>
        </View>

        {/* Details Card */}
        <View style={[styles.card, { backgroundColor: theme.surface, borderColor: theme.border }]}>
          <Text style={[styles.cardHeading, { color: theme.text }]}>Item Information</Text>

          {/* Expiry Date */}
          <View style={styles.detailRow}>
            <View style={[styles.detailIconBox, { backgroundColor: 'rgba(245, 158, 11, 0.12)' }]}>
              <Calendar size={18} color="#F59E0B" />
            </View>
            <View style={styles.detailTextCol}>
              <Text style={[styles.detailLabel, { color: theme.textSecondary }]}>Expiry Date</Text>
              <Text style={[styles.detailValue, { color: theme.text }]}>
                {formatDisplayDate(item.expiryDate)} ({item.expiryDate})
              </Text>
            </View>
          </View>

          <View style={[styles.divider, { backgroundColor: theme.border }]} />

          {/* Added On */}
          <View style={styles.detailRow}>
            <View style={[styles.detailIconBox, { backgroundColor: 'rgba(100, 116, 139, 0.12)' }]}>
              <Clock size={18} color={theme.textSecondary} />
            </View>
            <View style={styles.detailTextCol}>
              <Text style={[styles.detailLabel, { color: theme.textSecondary }]}>Added On</Text>
              <Text style={[styles.detailValue, { color: theme.text }]}>
                {new Date(item.createdAt).toLocaleDateString()}
              </Text>
            </View>
          </View>

          {/* Quantity */}
          {(item.quantity !== null || item.unit) && (
            <>
              <View style={[styles.divider, { backgroundColor: theme.border }]} />
              <View style={styles.detailRow}>
                <View style={[styles.detailIconBox, { backgroundColor: 'rgba(22, 163, 74, 0.12)' }]}>
                  <Package size={18} color={theme.primary} />
                </View>
                <View style={styles.detailTextCol}>
                  <Text style={[styles.detailLabel, { color: theme.textSecondary }]}>Quantity</Text>
                  <Text style={[styles.detailValue, { color: theme.text }]}>
                    {item.quantity ?? ''} {item.unit ?? ''}
                  </Text>
                </View>
              </View>
            </>
          )}

          {/* Location */}
          {item.location && (
            <>
              <View style={[styles.divider, { backgroundColor: theme.border }]} />
              <View style={styles.detailRow}>
                <View style={[styles.detailIconBox, { backgroundColor: 'rgba(6, 182, 212, 0.12)' }]}>
                  <MapPin size={18} color="#06B6D4" />
                </View>
                <View style={styles.detailTextCol}>
                  <Text style={[styles.detailLabel, { color: theme.textSecondary }]}>Storage Location</Text>
                  <Text style={[styles.detailValue, { color: theme.text }]}>{item.location}</Text>
                </View>
              </View>
            </>
          )}

          {/* Remind Me Toggle */}
          <View style={[styles.divider, { backgroundColor: theme.border }]} />
          <View style={styles.remindMeRow}>
            <View style={styles.detailRowNoPad}>
              <View style={[styles.detailIconBox, { backgroundColor: 'rgba(22, 163, 74, 0.12)' }]}>
                <Bell size={18} color={theme.primary} />
              </View>
              <View style={styles.detailTextCol}>
                <Text style={[styles.detailLabel, { color: theme.textSecondary }]}>Remind Me</Text>
                <Text style={[styles.detailValue, { color: theme.text }]}>
                  Alerts: {item.reminderOffsets.map((o) => `${o}d`).join(', ')} before
                </Text>
              </View>
            </View>
            <Switch
              value={remindMe}
              onValueChange={setRemindMe}
              trackColor={{ false: theme.border, true: theme.primary }}
            />
          </View>
        </View>

        {/* Notes Card if present */}
        {item.notes && (
          <View style={[styles.card, { backgroundColor: theme.surface, borderColor: theme.border }]}>
            <Text style={[styles.cardHeading, { color: theme.text }]}>Notes</Text>
            <Text style={[styles.notesText, { color: theme.textSecondary }]}>{item.notes}</Text>
          </View>
        )}

        {/* Lifecycle Status Action Buttons */}
        <View style={styles.actionsContainer}>
          <Text style={[styles.actionsHeading, { color: theme.textSecondary }]}>UPDATE ITEM STATUS</Text>
          <View style={styles.statusButtonsRow}>
            <TouchableOpacity
              style={[styles.statusBtn, { backgroundColor: 'rgba(22, 163, 74, 0.12)', borderColor: 'rgba(22, 163, 74, 0.3)' }]}
              onPress={() => handleMarkStatus('used')}
              activeOpacity={0.7}
            >
              <CheckCircle2 size={16} color={theme.primary} />
              <Text style={[styles.statusBtnText, { color: theme.primary }]}>Mark as Used</Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={[styles.statusBtn, { backgroundColor: 'rgba(6, 182, 212, 0.12)', borderColor: 'rgba(6, 182, 212, 0.3)' }]}
              onPress={() => handleMarkStatus('finished')}
              activeOpacity={0.7}
            >
              <Archive size={16} color="#0891B2" />
              <Text style={[styles.statusBtnText, { color: '#0891B2' }]}>Finished</Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={[styles.statusBtn, { backgroundColor: 'rgba(239, 68, 68, 0.12)', borderColor: 'rgba(239, 68, 68, 0.3)' }]}
              onPress={() => handleMarkStatus('disposed')}
              activeOpacity={0.7}
            >
              <XCircle size={16} color="#DC2626" />
              <Text style={[styles.statusBtnText, { color: '#DC2626' }]}>Disposed</Text>
            </TouchableOpacity>
          </View>

          {/* Delete Soft Red Button */}
          <TouchableOpacity
            style={[styles.deleteBtn, { backgroundColor: 'rgba(239, 68, 68, 0.12)', borderColor: 'rgba(239, 68, 68, 0.25)' }]}
            onPress={handleDelete}
            activeOpacity={0.7}
          >
            <Trash2 size={18} color="#EF4444" />
            <Text style={[styles.deleteBtnText, { color: '#EF4444' }]}>Delete Item</Text>
          </TouchableOpacity>
        </View>
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
    justifyContent: 'center',
    alignItems: 'center',
    padding: 24,
  },
  notFoundText: {
    fontSize: 16,
    marginBottom: 16,
    textAlign: 'center',
  },
  backButton: {
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 12,
  },
  backButtonText: {
    color: '#FFFFFF',
    fontWeight: '700',
  },
  headerBar: {
    height: 56,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    borderBottomWidth: 1,
  },
  backBtn: {
    width: 40,
    height: 40,
    alignItems: 'center',
    justifyContent: 'center',
  },
  headerTitle: {
    fontSize: 17,
    fontWeight: '700',
  },
  scrollContent: {
    padding: 16,
    paddingBottom: 48,
  },
  heroCard: {
    borderRadius: 16,
    borderWidth: 1,
    padding: 20,
    marginBottom: 16,
    alignItems: 'center',
  },
  heroIconCircle: {
    width: 72,
    height: 72,
    borderRadius: 36,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 14,
  },
  heroTitleRow: {
    width: '100%',
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  heroTextCol: {
    flex: 1,
    paddingRight: 10,
  },
  itemName: {
    fontSize: 22,
    fontWeight: '800',
    marginBottom: 4,
  },
  categoryTag: {
    alignSelf: 'flex-start',
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 9999,
  },
  categoryTagText: {
    fontSize: 12,
    fontWeight: '700',
  },
  statusPill: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 9999,
    borderWidth: 1,
  },
  statusPillText: {
    fontSize: 12,
    fontWeight: '700',
  },
  card: {
    borderRadius: 16,
    borderWidth: 1,
    padding: 16,
    marginBottom: 16,
  },
  cardHeading: {
    fontSize: 15,
    fontWeight: '700',
    marginBottom: 14,
  },
  detailRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  detailRowNoPad: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    flex: 1,
  },
  remindMeRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  detailIconBox: {
    width: 36,
    height: 36,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
  },
  detailTextCol: {
    flex: 1,
  },
  detailLabel: {
    fontSize: 12,
    fontWeight: '500',
    marginBottom: 2,
  },
  detailValue: {
    fontSize: 14,
    fontWeight: '600',
  },
  divider: {
    height: StyleSheet.hairlineWidth,
    marginVertical: 12,
  },
  notesText: {
    fontSize: 14,
    lineHeight: 20,
  },
  actionsContainer: {
    gap: 12,
  },
  actionsHeading: {
    fontSize: 12,
    fontWeight: '700',
    letterSpacing: 0.6,
    paddingHorizontal: 4,
  },
  statusButtonsRow: {
    flexDirection: 'row',
    gap: 8,
  },
  statusBtn: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 12,
    borderRadius: 12,
    borderWidth: 1,
    gap: 6,
  },
  statusBtnText: {
    fontSize: 12,
    fontWeight: '700',
  },
  deleteBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    height: 48,
    borderRadius: 12,
    borderWidth: 1,
    gap: 8,
    marginTop: 4,
  },
  deleteBtnText: {
    fontSize: 14,
    fontWeight: '700',
  },
});
