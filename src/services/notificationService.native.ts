import notifee, { TriggerType, AndroidImportance, TimestampTrigger } from '@notifee/react-native';
import { Item, NotificationRecord } from '../types/item';

export const NOTIFICATION_CHANNEL_ID = 'expiry_reminders';
export const NOTIFICATION_CHANNEL_NAME = 'Expiry Reminders';

class NativeNotificationService {
  private isInitialized = false;

  public async initialize(): Promise<void> {
    if (this.isInitialized) return;

    try {
      await notifee.createChannel({
        id: NOTIFICATION_CHANNEL_ID,
        name: NOTIFICATION_CHANNEL_NAME,
        importance: AndroidImportance.HIGH,
        sound: 'default',
        vibration: true,
      });
    } catch (err) {
      console.warn('Failed to create Android notification channel:', err);
    }

    this.isInitialized = true;
  }

  public async requestPermissions(): Promise<boolean> {
    try {
      const settings = await notifee.requestPermission();
      return settings.authorizationStatus >= 1;
    } catch {
      return false;
    }
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

    await this.initialize();

    const scheduledRecords: NotificationRecord[] = [];
    const now = new Date();

    for (const offset of item.reminderOffsets) {
      const firesAtDate = this.calculateFiresAt(item.expiryDate, offset, dailyNotificationTime);

      if (firesAtDate.getTime() > now.getTime()) {
        const id = this.generateNotificationId(item.id, offset);
        const body = this.getNotificationBody(item.name, offset);

        const trigger: TimestampTrigger = {
          type: TriggerType.TIMESTAMP,
          timestamp: firesAtDate.getTime(),
          alarmManager: {
            allowWhileIdle: true,
          },
        };

        try {
          await notifee.createTriggerNotification(
            {
              id,
              title: 'Dateora Expiry Alert',
              body,
              android: {
                channelId: NOTIFICATION_CHANNEL_ID,
                importance: AndroidImportance.HIGH,
                pressAction: { id: 'default' },
              },
            },
            trigger
          );
        } catch (err) {
          console.warn(`Could not schedule Notifee trigger for ${id}:`, err);
        }

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
    const commonOffsets = [0, 1, 3, 7, 14, 30];
    for (const offset of commonOffsets) {
      const id = this.generateNotificationId(itemId, offset);
      try {
        await notifee.cancelNotification(id);
      } catch {
        // ignore
      }
    }
  }

  public async rescheduleAll(): Promise<void> {
    try {
      await notifee.cancelAllNotifications();
      const { itemRepository } = require('./itemRepository');
      const active = await itemRepository.getActiveItems();
      for (const item of active) {
        await this.scheduleItemReminders(item);
      }
    } catch (err) {
      console.warn('Failed to reschedule all notifications:', err);
    }
  }

  public async sendCatchUpNotice(expiredItemName: string, daysAgo: number): Promise<void> {
    const body =
      daysAgo === 1
        ? `${expiredItemName} expired yesterday. Check your items.`
        : `${expiredItemName} expired ${daysAgo} days ago. Mark it as used or disposed.`;

    try {
      await notifee.displayNotification({
        title: 'Dateora Expiry Notice',
        body,
        android: {
          channelId: NOTIFICATION_CHANNEL_ID,
          importance: AndroidImportance.HIGH,
          pressAction: { id: 'default' },
        },
      });
    } catch (err) {
      console.warn('Could not display catch-up notification:', err);
    }
  }
}

export const notificationService = new NativeNotificationService();
