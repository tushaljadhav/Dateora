import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import 'notification_service.dart';

/// Service to check and request permissions in context (Camera on tap, Notifications after first save).
class PermissionService {
  static const String _permissionsRequestedKey = 'dateora_permissions_requested_once';
  static const String _notificationPromptedAfterSaveKey = 'dateora_notification_prompted_after_save';

  /// Returns true if the unified permission prompt was already triggered once.
  static Future<bool> wasRequestedOnce() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_permissionsRequestedKey) ?? false;
  }

  /// Check current status of Camera permission.
  static Future<bool> isCameraGranted() async {
    return await Permission.camera.isGranted;
  }

  /// System photo picker requires no runtime permissions.
  static Future<bool> isPhotosGranted() async {
    return true;
  }

  /// Check current status of Notifications permission.
  static Future<bool> isNotificationGranted() async {
    return await Permission.notification.isGranted;
  }

  /// Request Camera permission.
  static Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// System photo picker is used for gallery selection without runtime permissions.
  static Future<bool> requestPhotos() async {
    return true;
  }

  /// Request Notification permission.
  static Future<bool> requestNotification() async {
    return await NotificationService.instance.requestPermissions();
  }

  /// Inexact alarms are used; exact alarm permission is no longer required.
  static Future<bool> isExactAlarmGranted() async {
    return false;
  }

  /// Inexact alarms are used; exact alarm permission is no longer requested.
  static Future<bool> requestExactAlarm() async {
    return false;
  }

  /// Request Camera and Notifications in a single seamless flow.
  /// Used in Settings screen "Grant All Permissions".
  static Future<Map<String, bool>> requestAllPermissions() async {
    final results = <String, bool>{
      'camera': false,
      'photos': true,
      'notifications': false,
    };

    try {
      // Request Camera and Notifications via permission_handler
      final permissionsToRequest = <Permission>[
        Permission.camera,
        Permission.notification,
      ];

      final statuses = await permissionsToRequest.request();

      results['camera'] = statuses[Permission.camera]?.isGranted ?? false;
      results['notifications'] = statuses[Permission.notification]?.isGranted ?? false;
      results['photos'] = true;

      // 2. Also ensure local notifications plugin initiates OS channel if on Android
      try {
        await NotificationService.instance.requestPermissions();
      } catch (e) {
        debugPrint('Notification channel permission error: $e');
      }

      // 3. Mark as requested once in preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_permissionsRequestedKey, true);
    } catch (e) {
      debugPrint('Unified permissions error: $e');
    }

    return results;
  }

  /// Opens system app settings if a required permission is permanently denied.
  static Future<bool> openSettings() async {
    return await openAppSettings();
  }

  /// Prompts for Notification permission in-context right after the first item is saved.
  /// Displays a friendly educational dialog first.
  static Future<void> checkAndPromptNotificationPermissionAfterFirstSave(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyPrompted = prefs.getBool(_notificationPromptedAfterSaveKey) ?? false;
    if (alreadyPrompted) return;

    final isGranted = await Permission.notification.isGranted;
    if (isGranted) {
      await prefs.setBool(_notificationPromptedAfterSaveKey, true);
      return;
    }

    if (!context.mounted) return;

    // Show short educational explanation dialog first
    final bool? proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.notifications_active_rounded, color: AppColors.primaryStrong),
            SizedBox(width: 8),
            Text('Enable Reminders'),
          ],
        ),
        content: const Text(
          'Dateora alerts you 7 days, 3 days, and on the day your products expire so you never waste groceries or medicines.\n\nAllow notifications to receive timely offline reminders on this phone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryStrong,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enable Alerts'),
          ),
        ],
      ),
    );

    await prefs.setBool(_notificationPromptedAfterSaveKey, true);

    if (proceed == true) {
      final status = await Permission.notification.request();
      if (status.isPermanentlyDenied && context.mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Notification Permission Needed'),
            content: const Text(
              'Notification access was blocked. Please enable Notifications in App Settings so Dateora can alert you before products expire.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      } else if (status.isGranted) {
        try {
          await NotificationService.instance.requestPermissions();
        } catch (_) {}
      }
    }
  }
}
