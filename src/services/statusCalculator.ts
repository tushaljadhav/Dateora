import { ComputedItemStatus } from '../types/item';
import { brandColors } from '../theme/colors';

/**
 * Normalizes a date string or Date to start of day in local time for accurate day comparisons.
 */
export function normalizeToStartOfDay(date: Date | string): Date {
  const d = typeof date === 'string' ? new Date(date) : new Date(date.getTime());
  // If parsing YYYY-MM-DD directly:
  if (typeof date === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(date)) {
    const [year, month, day] = date.split('-').map(Number);
    return new Date(year, month - 1, day, 0, 0, 0, 0);
  }
  d.setHours(0, 0, 0, 0);
  return d;
}

/**
 * Calculates days remaining until expiry.
 * Negative number means already expired.
 */
export function getDaysUntilExpiry(expiryDateStr: string, referenceDate: Date = new Date()): number {
  const target = normalizeToStartOfDay(expiryDateStr);
  const now = normalizeToStartOfDay(referenceDate);

  const diffMs = target.getTime() - now.getTime();
  return Math.round(diffMs / (1000 * 60 * 60 * 24));
}

export interface StatusEvaluation {
  status: ComputedItemStatus;
  label: string;
  daysLeft: number;
  relativeText: string;
  badgeBg: string;
  textColor: string;
  borderColor: string;
  iconName: 'AlertCircle' | 'Clock' | 'CheckCircle';
}

/**
 * Evaluates the status of an item against the current reference date and configured window.
 */
export function evaluateItemStatus(
  expiryDateStr: string,
  windowDays: number = 7,
  referenceDate: Date = new Date()
): StatusEvaluation {
  const daysLeft = getDaysUntilExpiry(expiryDateStr, referenceDate);

  if (daysLeft < 0) {
    const absDays = Math.abs(daysLeft);
    const relativeText = absDays === 1 ? 'Expired yesterday' : `Expired ${absDays} days ago`;
    return {
      status: 'expired',
      label: 'Expired',
      daysLeft,
      relativeText,
      badgeBg: 'rgba(239, 68, 68, 0.15)',
      textColor: '#F87171',
      borderColor: 'rgba(239, 68, 68, 0.35)',
      iconName: 'AlertCircle',
    };
  }

  if (daysLeft === 0) {
    return {
      status: 'expiring_soon',
      label: 'Expires Today',
      daysLeft: 0,
      relativeText: 'Expires today',
      badgeBg: 'rgba(245, 158, 11, 0.15)',
      textColor: '#FBBF24',
      borderColor: 'rgba(245, 158, 11, 0.35)',
      iconName: 'Clock',
    };
  }

  if (daysLeft === 1) {
    return {
      status: 'expiring_soon',
      label: 'Expires Tomorrow',
      daysLeft: 1,
      relativeText: 'Expires tomorrow',
      badgeBg: 'rgba(245, 158, 11, 0.15)',
      textColor: '#FBBF24',
      borderColor: 'rgba(245, 158, 11, 0.35)',
      iconName: 'Clock',
    };
  }

  if (daysLeft <= windowDays) {
    return {
      status: 'expiring_soon',
      label: `In ${daysLeft} days`,
      daysLeft,
      relativeText: `Expires in ${daysLeft} days`,
      badgeBg: 'rgba(245, 158, 11, 0.15)',
      textColor: '#FBBF24',
      borderColor: 'rgba(245, 158, 11, 0.35)',
      iconName: 'Clock',
    };
  }

  return {
    status: 'safe',
    label: 'Safe',
    daysLeft,
    relativeText: `Expires in ${daysLeft} days`,
    badgeBg: 'rgba(16, 185, 129, 0.15)',
    textColor: '#34D399',
    borderColor: 'rgba(16, 185, 129, 0.35)',
    iconName: 'CheckCircle',
  };
}

/**
 * Formats YYYY-MM-DD into a readable localized format (e.g., "16 Oct 2026")
 */
export function formatDisplayDate(dateStr: string): string {
  try {
    const d = normalizeToStartOfDay(dateStr);
    return d.toLocaleDateString(undefined, {
      day: 'numeric',
      month: 'short',
      year: 'numeric',
    });
  } catch {
    return dateStr;
  }
}
