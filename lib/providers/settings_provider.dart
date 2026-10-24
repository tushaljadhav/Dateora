import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/analytics_service.dart';

class SettingsProvider with ChangeNotifier {
  static const _secureStorageKey = 'gemini_api_key';
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  ThemeMode _themeMode = ThemeMode.light;
  Locale? _locale;
  bool _notificationsEnabled = true;
  bool _weeklySummaryEnabled = true;
  bool _analyticsEnabled = true;
  int _defaultReminderOffset = 3;
  String _dailyNotificationTime = '09:00';
  bool _onboardingCompleted = false;

  // AI Security & Privacy State
  String _geminiApiKey = '';
  bool _aiScanEnabled = true;
  bool _aiConsentGiven = false;
  int _dailyScanCount = 0;
  String _lastScanDate = '';
  String _aiTransportMode = 'direct'; // 'direct' or 'proxy'
  String _proxyBaseUrl = '';

  ThemeMode get themeMode => _themeMode;
  Locale? get locale => _locale;
  String get languageCode => _locale?.languageCode ?? 'system';
  bool get notificationsEnabled => _notificationsEnabled;
  bool get weeklySummaryEnabled => _weeklySummaryEnabled;
  bool get analyticsEnabled => _analyticsEnabled;
  int get defaultReminderOffset => _defaultReminderOffset;
  String get dailyNotificationTime => _dailyNotificationTime;
  bool get onboardingCompleted => _onboardingCompleted;

  // AI getters
  String get geminiApiKey => _geminiApiKey;
  bool get hasGeminiApiKey => _geminiApiKey.isNotEmpty;
  bool get aiScanEnabled => _aiScanEnabled;
  bool get aiConsentGiven => _aiConsentGiven;
  int get dailyScanCount => _dailyScanCount;
  String get aiTransportMode => _aiTransportMode;
  String get proxyBaseUrl => _proxyBaseUrl;

  /// Returns masked API key (showing only last 4 chars, e.g. ••••••••••••3A9F)
  String get maskedGeminiApiKey {
    if (_geminiApiKey.isEmpty) return 'Not configured';
    if (_geminiApiKey.length <= 4) return '••••';
    final last4 = _geminiApiKey.substring(_geminiApiKey.length - 4);
    return '••••••••••••$last4';
  }

  /// Whether a custom API key was set
  bool get isKeyFromEnvironment => false;

  SettingsProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Theme (Defaults to Light mode by default)
    final themeStr = prefs.getString('theme_mode') ?? 'light';
    if (themeStr == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (themeStr == 'system') {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.light;
    }

    // Language
    final langStr = prefs.getString('app_language') ?? 'system';
    if (langStr == 'hi') {
      _locale = const Locale('hi');
    } else if (langStr == 'mr') {
      _locale = const Locale('mr');
    } else if (langStr == 'en') {
      _locale = const Locale('en');
    } else {
      _locale = null; // system default
    }

    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    _weeklySummaryEnabled = prefs.getBool('weekly_summary_enabled') ?? true;
    _analyticsEnabled = prefs.getBool('analytics_enabled') ?? true;
    _defaultReminderOffset = prefs.getInt('default_reminder_offset') ?? 3;
    _dailyNotificationTime = prefs.getString('daily_notification_time') ?? '09:00';
    _onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

    // 2. AI Privacy & Daily Scan Limits
    _aiScanEnabled = prefs.getBool('ai_scan_enabled') ?? true;
    _aiConsentGiven = prefs.getBool('ai_consent_given') ?? false;
    _aiTransportMode = prefs.getString('ai_transport_mode') ?? 'direct';
    _proxyBaseUrl = prefs.getString('ai_proxy_base_url') ?? '';

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _lastScanDate = prefs.getString('ai_last_scan_date') ?? todayStr;
    if (_lastScanDate != todayStr) {
      _dailyScanCount = 0;
      await prefs.setString('ai_last_scan_date', todayStr);
      await prefs.setInt('ai_daily_scan_count', 0);
    } else {
      _dailyScanCount = prefs.getInt('ai_daily_scan_count') ?? 0;
    }

    // 3. ONE-TIME MIGRATION: SharedPreferences -> flutter_secure_storage
    await _migrateLegacyKey(prefs);

    // 4. Resolve API key if stored previously in secure storage
    final secureKey = await _secureStorage.read(key: _secureStorageKey);
    _geminiApiKey = secureKey?.trim() ?? '';

    notifyListeners();
  }

  /// Migrates any legacy plain-text key from SharedPreferences to flutter_secure_storage
  Future<void> _migrateLegacyKey(SharedPreferences prefs) async {
    try {
      if (prefs.containsKey('gemini_api_key')) {
        final legacyKey = prefs.getString('gemini_api_key');
        if (legacyKey != null && legacyKey.trim().isNotEmpty) {
          await _secureStorage.write(
            key: _secureStorageKey,
            value: legacyKey.trim(),
          );
        }
        // Delete permanently from unencrypted SharedPreferences
        await prefs.remove('gemini_api_key');
      }
    } catch (_) {
      // Secure storage fallback protection
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    String val = 'system';
    if (mode == ThemeMode.light) val = 'light';
    if (mode == ThemeMode.dark) val = 'dark';
    await prefs.setString('theme_mode', val);
  }

  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final langStr = locale?.languageCode ?? 'system';
    await prefs.setString('app_language', langStr);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
  }

  Future<void> setWeeklySummaryEnabled(bool enabled) async {
    _weeklySummaryEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('weekly_summary_enabled', enabled);
  }

  Future<void> setAnalyticsEnabled(bool enabled) async {
    _analyticsEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('analytics_enabled', enabled);
    await AnalyticsService.instance.setEnabled(enabled);
  }

  Future<void> setDefaultReminderOffset(int offset) async {
    _defaultReminderOffset = offset;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('default_reminder_offset', offset);
  }

  Future<void> setDailyNotificationTime(String time) async {
    _dailyNotificationTime = time;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('daily_notification_time', time);
  }

  Future<void> completeOnboarding() async {
    _onboardingCompleted = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
  }

  // ─── AI Settings Actions ───

  /// Saves the user's Gemini API key to flutter_secure_storage.
  Future<void> setGeminiApiKey(String key) async {
    final clean = key.trim();
    _geminiApiKey = clean;
    notifyListeners();

    if (clean.isEmpty) {
      await _secureStorage.delete(key: _secureStorageKey);
    } else {
      await _secureStorage.write(key: _secureStorageKey, value: clean);
    }
  }

  /// Enables or disables AI scanning feature.
  Future<void> setAiScanEnabled(bool enabled) async {
    _aiScanEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ai_scan_enabled', enabled);
  }

  /// Stores user consent for sending packaging photos to Gemini AI.
  Future<void> setAiConsentGiven(bool consent) async {
    _aiConsentGiven = consent;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ai_consent_given', consent);
  }

  /// Revokes and clears user AI consent.
  Future<void> clearAiConsent() async {
    _aiConsentGiven = false;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ai_consent_given');
  }

  /// Increments local daily scan counter.
  Future<void> incrementDailyScanCount() async {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();

    if (_lastScanDate != todayStr) {
      _lastScanDate = todayStr;
      _dailyScanCount = 1;
    } else {
      _dailyScanCount++;
    }

    notifyListeners();
    await prefs.setString('ai_last_scan_date', _lastScanDate);
    await prefs.setInt('ai_daily_scan_count', _dailyScanCount);
  }

  /// Configures transport mode ('direct' or 'proxy')
  Future<void> setAiTransportMode(String mode, {String? proxyUrl}) async {
    _aiTransportMode = mode;
    if (proxyUrl != null) _proxyBaseUrl = proxyUrl;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_transport_mode', _aiTransportMode);
    if (proxyUrl != null) await prefs.setString('ai_proxy_base_url', _proxyBaseUrl);
  }
}
