import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

/// Unified service to check and request all Dateora permissions in a single coordinated flow.
class PermissionService {
  static const String _permissionsRequestedKey = 'dateora_permissions_requested_once';

  /// Returns true if the unified permission prompt was already triggered once.
  static Future<bool> wasRequestedOnce() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_permissionsRequestedKey) ?? false;
  }

  /// Check current status of Camera permission.
  static Future<bool> isCameraGranted() async {
    return await Permission.camera.isGranted;
  }

  /// Check current status of Photos / Gallery permission.
  static Future<bool> isPhotosGranted() async {
    if (!Platform.isAndroid && !Platform.isIOS) return true;
    if (Platform.isAndroid) {
      // Android 13+ (API 33+) uses photos, older versions use storage.
      // Modern Android system photo picker doesn't even need runtime permission.
      final photosStatus = await Permission.photos.status;
      final storageStatus = await Permission.storage.status;
      return photosStatus.isGranted || storageStatus.isGranted;
    }
    return await Permission.photos.isGranted;
  }

  /// Check current status of Notifications permission.
  static Future<bool> isNotificationGranted() async {
    return await Permission.notification.isGranted;
  }

  /// Request Camera, Gallery, and Notifications in a single seamless flow.
  /// Used in Onboarding and in Settings screen "Grant All Permissions".
  static Future<Map<String, bool>> requestAllPermissions() async {
    final results = <String, bool>{
      'camera': false,
      'photos': false,
      'notifications': false,
    };

    try {
      // 1. Request Camera and Notifications via permission_handler
      final permissionsToRequest = <Permission>[
        Permission.camera,
        Permission.notification,
      ];

      if (Platform.isAndroid) {
        permissionsToRequest.add(Permission.photos);
        permissionsToRequest.add(Permission.storage);
      } else if (Platform.isIOS) {
        permissionsToRequest.add(Permission.photos);
      }

      final statuses = await permissionsToRequest.request();

      results['camera'] = statuses[Permission.camera]?.isGranted ?? false;
      results['notifications'] = statuses[Permission.notification]?.isGranted ?? false;

      if (Platform.isAndroid) {
        final photosGranted = statuses[Permission.photos]?.isGranted ?? false;
        final storageGranted = statuses[Permission.storage]?.isGranted ?? false;
        results['photos'] = photosGranted || storageGranted;
      } else if (Platform.isIOS) {
        results['photos'] = statuses[Permission.photos]?.isGranted ?? false;
      } else {
        results['photos'] = true;
      }

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
}
