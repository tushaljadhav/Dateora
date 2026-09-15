import { Item, NotificationRecord } from '../types/item';

export interface ScheduleNotificationParams {
  item: Item;
  dailyNotificationTime: string; // 'HH:mm'
}

class NotificationService {
  private isInitialized = false;

  public async initialize(): Promise<void> {
    if (this.isInitialized) return;
    // Will register Notifee channel in Phase 3
    this.isInitialized = true;
  }

  public async requestPermissions(): Promise<boolean> {
    // Contextual permission requester
    return true;
  }

  /**
   * Deterministic Notification ID generator: `${itemId}:${offsetDays}`
   */
  public generateNotificationId(itemId: string, offsetDays: number): string {
    return `${itemId}:${offsetDays}`;
  }

  /**
   * Calculates the exact firesAt ISO string for a given expiry date, offset days, and daily notification time.
   */
  public calculateFiresAt(expiryDateStr: string, offsetDays: number, dailyTime: string = '09:00'): Date {
    const [year, month, day] = expiryDateStr.split('-').map(Number);
    const [hours, minutes] = dailyTime.split(':').map(Number);

    const targetDate = new Date(year, month - 1, day, hours, minutes, 0, 0);
    targetDate.setDate(targetDate.getDate() - offsetDays);
    return targetDate;
  }

  /**
   * Schedules deterministic notifications for an item.
   * Cancels any existing reminders for this item first.
   */
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

      // Only schedule if fire time is in the future
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

  /**
   * Cancels all notifications tied to an item.
   */
  public async cancelItemReminders(itemId: string): Promise<void> {
    // In Phase 3: notifee.cancelNotification(id)
  }
}

export const notificationService = new NotificationService();
