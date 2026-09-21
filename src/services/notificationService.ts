import { Item, NotificationRecord } from '../types/item';

export const NOTIFICATION_CHANNEL_ID = 'expiry_reminders';
export const NOTIFICATION_CHANNEL_NAME = 'Expiry Reminders';

class WebNotificationService {
  public async initialize(): Promise<void> {
    // Web initialization
  }

  public async requestPermissions(): Promise<boolean> {
    if (typeof window !== 'undefined' && 'Notification' in window) {
      try {
        const perm = await window.Notification.requestPermission();
        return perm === 'granted';
      } catch {
        return false;
      }
    }
    return true;
  }

  public generateNotificationId(itemId: string, offsetDays: number): string {
    return `${itemId}:${offsetDays}`;
  }

  public getNotificationBody(itemName: string, offsetDays: number): string {
    if (offsetDays === 0) return `${itemName} expires today.`;
    if (offsetDays === 1) return `${itemName} expires tomorrow.`;
    return `${itemName} expires in ${offsetDays} days.`;
  }

  public calculateFiresAt(expiryDateStr: string, offsetDays: number, dailyTime: string = '09:00'): Date {
    const [year, month, day] = expiryDateStr.split('-').map(Number);
    const [hours, minutes] = dailyTime.split(':').map(Number);

    const targetDate = new Date(year, month - 1, day, hours, minutes, 0, 0);
    targetDate.setDate(targetDate.getDate() - offsetDays);
    return targetDate;
  }

  public async scheduleItemReminders(
    item: Item,
    dailyNotificationTime: string = '09:00'
  ): Promise<NotificationRecord[]> {
    await this.cancelItemReminders(item.id);

    if (item.status !== 'active') {
      return [];
    }

    const scheduledRecords: NotificationRecord[] = [];
    const now = new Date();

    for (const offset of item.reminderOffsets) {
      const firesAtDate = this.calculateFiresAt(item.expiryDate, offset, dailyNotificationTime);

      if (firesAtDate.getTime() > now.getTime()) {
        const id = this.generateNotificationId(item.id, offset);
        scheduledRecords.push({
          id,
          itemId: item.id,
          firesAt: firesAtDate.toISOString(),
          notifeeTriggerId: id,
        });
      }
    }

    return scheduledRecords;
  }

  public async cancelItemReminders(itemId: string): Promise<void> {
    // In-memory / web cancellation
  }

  public async rescheduleAll(): Promise<void> {
    // Web fallback: no persistent OS alarm triggers to reschedule
  }

  public async sendCatchUpNotice(expiredItemName: string, daysAgo: number): Promise<void> {
    const body =
      daysAgo === 1
        ? `${expiredItemName} expired yesterday. Check your items.`
        : `${expiredItemName} expired ${daysAgo} days ago. Mark it as used or disposed.`;

    if (typeof window !== 'undefined' && 'Notification' in window && window.Notification.permission === 'granted') {
      new window.Notification('Dateora Expiry Notice', { body });
    }
  }
}

export const notificationService = new WebNotificationService();
