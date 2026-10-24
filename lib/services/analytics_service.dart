import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Central wrapper for Firebase Analytics and Crashlytics.
/// Ensures no screen calls Firebase directly, and strictly respects user privacy.
/// Free-text (item names, notes, photos) is NEVER logged.
class AnalyticsService {
  static final AnalyticsService instance = AnalyticsService._init();
  AnalyticsService._init();

  FirebaseAnalytics? _analytics;
  bool _isFirebaseAvailable = false;
  bool _isEnabled = true;

  bool get isEnabled => _isEnabled;
  bool get isFirebaseAvailable => _isFirebaseAvailable;

  void initialize({required bool isFirebaseAvailable, required bool enabled}) {
    _isFirebaseAvailable = isFirebaseAvailable;
    _isEnabled = enabled;
    if (_isFirebaseAvailable) {
      try {
        _analytics = FirebaseAnalytics.instance;
        _setCollectionState(_isEnabled);
      } catch (e) {
        debugPrint('AnalyticsService init error: $e');
      }
    }
  }

  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    if (_isFirebaseAvailable) {
      await _setCollectionState(enabled);
    }
  }

  Future<void> _setCollectionState(bool enabled) async {
    try {
      await _analytics?.setAnalyticsCollectionEnabled(enabled);
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(enabled);
    } catch (e) {
      debugPrint('Error toggling analytics/crashlytics collection: $e');
    }
  }

  /// Logs item added event. Only categorization and method are sent.
  Future<void> logItemAdded({
    required String method, // 'manual', 'ai_scan', 'barcode'
    required String category,
  }) async {
    if (!_isEnabled || !_isFirebaseAvailable || _analytics == null) return;
    try {
      final safeMethod = (method == 'ai_scan' || method == 'barcode') ? method : 'manual';
      await _analytics!.logEvent(
        name: 'item_added',
        parameters: {
          'method': safeMethod,
          'category': category.trim().toLowerCase(),
        },
      );
    } catch (_) {}
  }

  /// Logs AI scan usage (boolean outcome only).
  Future<void> logAiScanUsed({required bool success}) async {
    if (!_isEnabled || !_isFirebaseAvailable || _analytics == null) return;
    try {
      await _analytics!.logEvent(
        name: 'ai_scan_used',
        parameters: {'success': success ? 1 : 0},
      );
    } catch (_) {}
  }

  /// Logs Barcode scan usage (boolean outcome only).
  Future<void> logBarcodeScanUsed({required bool success}) async {
    if (!_isEnabled || !_isFirebaseAvailable || _analytics == null) return;
    try {
      await _analytics!.logEvent(
        name: 'barcode_scan_used',
        parameters: {'success': success ? 1 : 0},
      );
    } catch (_) {}
  }

  /// Logs when the user opens a reminder notification.
  Future<void> logNotificationOpened() async {
    if (!_isEnabled || !_isFirebaseAvailable || _analytics == null) return;
    try {
      await _analytics!.logEvent(name: 'notification_opened');
    } catch (_) {}
  }

  /// Logs item marked used.
  Future<void> logItemMarkedUsed() async {
    if (!_isEnabled || !_isFirebaseAvailable || _analytics == null) return;
    try {
      await _analytics!.logEvent(name: 'item_marked_used');
    } catch (_) {}
  }

  /// Logs item marked disposed.
  Future<void> logItemMarkedDisposed() async {
    if (!_isEnabled || !_isFirebaseAvailable || _analytics == null) return;
    try {
      await _analytics!.logEvent(name: 'item_marked_disposed');
    } catch (_) {}
  }

  /// Logs completion of onboarding.
  Future<void> logOnboardingCompleted() async {
    if (!_isEnabled || !_isFirebaseAvailable || _analytics == null) return;
    try {
      await _analytics!.logEvent(name: 'onboarding_completed');
    } catch (_) {}
  }

  /// Logs share tapped.
  Future<void> logShareTapped({String type = 'general'}) async {
    if (!_isEnabled || !_isFirebaseAvailable || _analytics == null) return;
    try {
      await _analytics!.logEvent(
        name: 'share_tapped',
        parameters: {'type': type},
      );
    } catch (_) {}
  }

  /// Logs language switch.
  Future<void> logLanguageChanged(String languageCode) async {
    if (!_isEnabled || !_isFirebaseAvailable || _analytics == null) return;
    try {
      await _analytics!.logEvent(
        name: 'language_changed',
        parameters: {'language_code': languageCode},
      );
    } catch (_) {}
  }

  /// Logs data backup exported.
  Future<void> logBackupExported() async {
    if (!_isEnabled || !_isFirebaseAvailable || _analytics == null) return;
    try {
      await _analytics!.logEvent(name: 'backup_exported');
    } catch (_) {}
  }

  /// Logs data backup imported.
  Future<void> logBackupImported() async {
    if (!_isEnabled || !_isFirebaseAvailable || _analytics == null) return;
    try {
      await _analytics!.logEvent(name: 'backup_imported');
    } catch (_) {}
  }
}
