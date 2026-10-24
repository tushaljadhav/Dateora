import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../providers/items_provider.dart';
import '../providers/settings_provider.dart';
import '../services/ai_expiry_scan_service.dart';
import '../services/analytics_service.dart';
import '../services/export_service.dart';
import '../services/notification_service.dart';
import '../services/permission_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_card.dart';
import 'privacy_policy_screen.dart';

// ignore: constant_identifier_names
const String PLAY_STORE_URL = 'https://play.google.com/store/apps/details?id=com.dateora.dateora';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Live Permission States
  bool _cameraGranted = false;
  bool _photosGranted = false;
  bool _notifGranted = false;
  bool _isSchedulingTestNotif = false;

  @override
  void initState() {
    super.initState();
    _refreshPermissions();
  }

  Future<void> _refreshPermissions() async {
    final camera = await PermissionService.isCameraGranted();
    final photos = await PermissionService.isPhotosGranted();
    final notif = await PermissionService.isNotificationGranted();
    if (mounted) {
      setState(() {
        _cameraGranted = camera;
        _photosGranted = photos;
        _notifGranted = notif;
      });
    }
  }

  Future<void> _grantAllPermissions() async {
    await PermissionService.requestAllPermissions();
    await _refreshPermissions();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.primaryStrong,
          content: Text('Permissions checked and updated!'),
        ),
      );
    }
  }

  Future<void> _requestSinglePermission(String type) async {
    if (type == 'camera') {
      await PermissionService.requestCamera();
    } else if (type == 'photos') {
      await PermissionService.requestPhotos();
    } else if (type == 'notifications') {
      await PermissionService.requestNotification();
    }
    await _refreshPermissions();
  }

  Future<void> _scheduleTestNotification() async {
    final notifGranted = await PermissionService.isNotificationGranted();
    if (!notifGranted) {
      final req = await NotificationService.instance.requestPermissions();
      await _refreshPermissions();
      if (!req) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.statusDanger,
              content: Text('Notification permission is required. Please enable it in Settings.'),
            ),
          );
        }
        return;
      }
    }

    setState(() => _isSchedulingTestNotif = true);
    try {
      await NotificationService.instance.scheduleTestNotification(delaySeconds: 10);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryStrong,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 4),
            content: const Row(
              children: [
                Icon(Icons.alarm_on_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Test alert scheduled! Check notifications in 10 seconds.',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.statusDanger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Text(
              'Test notification could not be scheduled: $e',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSchedulingTestNotif = false);
    }
  }

  void _exportJson() async {
    await ExportService.exportData();
    AnalyticsService.instance.logBackupExported();
  }

  void _importJson() async {
    final result = await ExportService.importData();
    if (!mounted) return;
    if (result['success'] == true) {
      final itemsProvider = Provider.of<ItemsProvider>(context, listen: false);
      await itemsProvider.loadItems();
      AnalyticsService.instance.logBackupImported();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primaryStrong,
          content: Text('Imported ${result['count']} items successfully!'),
        ),
      );
    } else if (result['cancelled'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.statusDanger,
          content: Text('Import failed: ${result['error']}'),
        ),
      );
    }
  }

  void _tellAFriend(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final text = l10n != null
        ? l10n.settingsTellAFriendShareText(PLAY_STORE_URL)
        : 'Never let groceries or medicines expire again! Track expiry dates with Dateora: $PLAY_STORE_URL';
    await Share.share(text);
    AnalyticsService.instance.logShareTapped(type: 'invite');
  }

  Future<void> _updateLanguage(SettingsProvider settings, Locale? locale) async {
    await settings.setLocale(locale);
    AnalyticsService.instance.logLanguageChanged(locale?.languageCode ?? 'system');
    if (!mounted) return;
    final itemsProvider = Provider.of<ItemsProvider>(context, listen: false);
    final langCode = locale?.languageCode;

    // Reschedule item reminders with localized strings
    for (final item in itemsProvider.activeItems) {
      await NotificationService.instance.scheduleItemReminders(
        item,
        dailyNotificationTime: settings.dailyNotificationTime,
        localeCode: langCode,
      );
    }

    // Reschedule weekly summary if enabled
    if (settings.weeklySummaryEnabled) {
      await NotificationService.instance.scheduleWeeklySummaryNotification(
        itemsProvider.activeItems,
        dailyNotificationTime: settings.dailyNotificationTime,
        localeCode: langCode,
      );
    }
  }

  void _confirmDeleteAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Data?'),
        content: const Text(
          'This will permanently delete all your items, history and notifications from this device. Are you sure?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusDanger,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              await DatabaseHelper.instance.clearAllData();
              if (!mounted) return;
              final itemsProvider = Provider.of<ItemsProvider>(context, listen: false);
              await itemsProvider.loadItems();
              messenger.showSnackBar(
                const SnackBar(content: Text('All local data cleared.')),
              );
            },
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  void _showApiKeyBottomSheet(SettingsProvider settings) {
    final keyController = TextEditingController(text: settings.geminiApiKey);
    bool isTesting = false;
    String? statusMessage;
    bool isSuccess = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final isDark = Theme.of(modalCtx).brightness == Brightness.dark;
          final bottomInset = MediaQuery.of(modalCtx).viewInsets.bottom;

          return Container(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryStrong.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.key_rounded, color: AppColors.primaryStrong, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Google Gemini API Key',
                            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Direct fast scan (1-2s) via Google AI Studio',
                            style: AppTextStyles.caption.copyWith(
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Cloud proxy sleep hone par AI slow ho jata hai. Google AI Studio se apni free Gemini API key lekar yahan set karein. Direct scanning 1-2 second mein hoti hai:',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: keyController,
                  decoration: InputDecoration(
                    hintText: 'AIzaSy...',
                    labelText: 'Gemini API Key',
                    prefixIcon: const Icon(Icons.vpn_key_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: keyController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setModalState(() => keyController.clear()),
                          )
                        : null,
                  ),
                ),
                if (statusMessage != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        isSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                        size: 16,
                        color: isSuccess ? AppColors.statusSuccess : AppColors.statusDanger,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          statusMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSuccess ? AppColors.statusSuccess : AppColors.statusDanger,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: isTesting
                            ? null
                            : () async {
                                final key = keyController.text.trim();
                                if (key.isEmpty) {
                                  setModalState(() {
                                    statusMessage = 'Pehle API key enter karein.';
                                    isSuccess = false;
                                  });
                                  return;
                                }
                                setModalState(() {
                                  isTesting = true;
                                  statusMessage = 'Testing connection with Google...';
                                  isSuccess = false;
                                });
                                final res = await GeminiExpiryScanService.testApiKey(key);
                                setModalState(() {
                                  isTesting = false;
                                  isSuccess = res['success'] == true;
                                  statusMessage = res['message']?.toString();
                                });
                              },
                        child: isTesting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Test Key'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryStrong,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          final key = keyController.text.trim();
                          await settings.setGeminiApiKey(key);
                          if (!mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.primaryStrong,
                              content: Text(key.isNotEmpty
                                  ? 'Gemini API key saved! Direct fast scan active.'
                                  : 'API key cleared. Using cloud proxy.'),
                            ),
                          );
                        },
                        child: const Text('Save Key', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.screenHorizontal,
        title: Text(
          l10n?.settingsTitle ?? 'Settings',
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
          vertical: AppSpacing.md,
        ),
        children: [
          // ─── 1. App Header Hero Card (Matching Bachat Aesthetic) ───
          _buildAppHeaderHero(isDark),

          const SizedBox(height: AppSpacing.lg),

          // ─── 2. Appearance & Theme ───
          _buildSectionHeader(Icons.palette_outlined, l10n?.settingsTheme ?? 'Theme Mode'),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: _buildThemeOptionCard(
                    mode: ThemeMode.system,
                    title: l10n?.settingsThemeSystem ?? (settings.locale?.languageCode == 'hi' ? 'सिस्टम' : settings.locale?.languageCode == 'mr' ? 'सिस्टीम' : 'System'),
                    subtitle: settings.locale?.languageCode == 'hi' || settings.locale?.languageCode == 'mr' ? 'ऑटो' : 'Auto',
                    isSelected: settings.themeMode == ThemeMode.system,
                    onTap: () => settings.setThemeMode(ThemeMode.system),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildThemeOptionCard(
                    mode: ThemeMode.light,
                    title: l10n?.settingsThemeLight ?? 'Light',
                    subtitle: settings.locale?.languageCode == 'hi' ? 'दिन' : settings.locale?.languageCode == 'mr' ? 'दिवस' : 'Day',
                    isSelected: settings.themeMode == ThemeMode.light,
                    onTap: () => settings.setThemeMode(ThemeMode.light),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildThemeOptionCard(
                    mode: ThemeMode.dark,
                    title: l10n?.settingsThemeDark ?? 'Dark',
                    subtitle: settings.locale?.languageCode == 'hi' ? 'रात' : settings.locale?.languageCode == 'mr' ? 'रात्र' : 'Night',
                    isSelected: settings.themeMode == ThemeMode.dark,
                    onTap: () => settings.setThemeMode(ThemeMode.dark),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ─── 3. Language Selection (Clean Symmetrical 2x2 Grid) ───
          _buildSectionHeader(Icons.translate_rounded, l10n?.settingsLanguage ?? 'Language'),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildLanguageTile(
                        label: 'English',
                        subtitle: 'Default',
                        isSelected: settings.locale?.languageCode == 'en',
                        onTap: () => _updateLanguage(settings, const Locale('en')),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildLanguageTile(
                        label: 'हिंदी',
                        subtitle: 'Hindi',
                        isSelected: settings.locale?.languageCode == 'hi',
                        onTap: () => _updateLanguage(settings, const Locale('hi')),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildLanguageTile(
                        label: 'मराठी',
                        subtitle: 'Marathi',
                        isSelected: settings.locale?.languageCode == 'mr',
                        onTap: () => _updateLanguage(settings, const Locale('mr')),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildLanguageTile(
                        label: 'System',
                        subtitle: 'Auto-detect',
                        isSelected: settings.locale == null,
                        onTap: () => _updateLanguage(settings, null),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ─── 4. Device Access & Permissions ───
          _buildSectionHeader(Icons.security_rounded, 'Device Permissions'),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'System Access Status',
                        style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _grantAllPermissions,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primaryStrong.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.sync_rounded, size: 13, color: AppColors.primaryDark),
                            const SizedBox(width: 4),
                            Text(
                              'Check All',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _buildPermissionRow(
                  icon: Icons.camera_alt_outlined,
                  name: 'Camera Access',
                  desc: 'Used for barcode scanning and AI packaging photos',
                  isGranted: _cameraGranted,
                  onRequest: () => _requestSinglePermission('camera'),
                  isDark: isDark,
                ),
                Divider(height: 18, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                _buildPermissionRow(
                  icon: Icons.photo_library_outlined,
                  name: 'Photos & Gallery',
                  desc: 'Pick existing packaging images stored on device',
                  isGranted: _photosGranted,
                  onRequest: () => _requestSinglePermission('photos'),
                  isDark: isDark,
                ),
                Divider(height: 18, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                _buildPermissionRow(
                  icon: Icons.notifications_none_rounded,
                  name: 'Expiry Notifications',
                  desc: 'Fires timely reminders before items expire',
                  isGranted: _notifGranted,
                  onRequest: () => _requestSinglePermission('notifications'),
                  isDark: isDark,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ─── 5. Notifications Section ───
          _buildSectionHeader(Icons.notifications_active_outlined, l10n?.settingsSectionNotifications ?? 'Notifications & Alerts'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                  secondary: _buildIconBadge(Icons.alarm_on_rounded, isDark),
                  title: Text(l10n?.settingsNotificationsEnable ?? 'Expiry Reminders', style: AppTextStyles.titleSmall),
                  subtitle: Text(l10n?.settingsNotificationsSubtitle ?? 'Receive offline alerts before items expire', style: AppTextStyles.caption),
                  activeColor: AppColors.primaryStrong,
                  value: settings.notificationsEnabled,
                  onChanged: (val) => settings.setNotificationsEnabled(val),
                ),
                Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                  secondary: _buildIconBadge(Icons.calendar_month_outlined, isDark),
                  title: Text(l10n?.settingsWeeklySummary ?? 'Weekly Sunday Summary', style: AppTextStyles.titleSmall),
                  subtitle: Text(
                    l10n?.settingsWeeklySummarySubtitle ?? 'Summary of items expiring this week at 9:00 AM',
                    style: AppTextStyles.caption,
                  ),
                  activeColor: AppColors.primaryStrong,
                  value: settings.weeklySummaryEnabled,
                  onChanged: (val) async {
                    await settings.setWeeklySummaryEnabled(val);
                    if (!mounted) return;
                    final items = Provider.of<ItemsProvider>(context, listen: false).activeItems;
                    if (val) {
                      await NotificationService.instance.scheduleWeeklySummaryNotification(
                        items,
                        dailyNotificationTime: settings.dailyNotificationTime,
                        localeCode: settings.locale?.languageCode,
                      );
                    } else {
                      await NotificationService.instance.cancelWeeklySummaryNotification();
                    }
                  },
                ),
                Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                  leading: _buildIconBadge(Icons.access_time_rounded, isDark),
                  title: Text(l10n?.settingsReminderTime ?? 'Daily Alert Time', style: AppTextStyles.titleSmall),
                  subtitle: Text('Notifications fire daily at ${settings.dailyNotificationTime}', style: AppTextStyles.caption),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primaryStrong.withOpacity(0.2)),
                    ),
                    child: Text(
                      settings.dailyNotificationTime,
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  onTap: () async {
                    final parts = settings.dailyNotificationTime.split(':');
                    final initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: initial,
                      builder: (ctx, child) {
                        return Theme(
                          data: Theme.of(ctx).copyWith(
                            colorScheme: Theme.of(ctx).colorScheme.copyWith(
                                  primary: AppColors.primaryStrong,
                                  onPrimary: Colors.white,
                                ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      final str =
                          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                      settings.setDailyNotificationTime(str);
                    }
                  },
                ),
                Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                  leading: _buildIconBadge(Icons.send_to_mobile_rounded, isDark),
                  title: const Text('Send Test Notification', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text(
                    'Schedules a sample alert in 10 seconds to verify alarms work',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: _isSchedulingTestNotif
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primaryStrong.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.timer_outlined, size: 14, color: AppColors.primaryDark),
                              const SizedBox(width: 4),
                              Text(
                                'Test Alert',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                  onTap: _isSchedulingTestNotif ? null : _scheduleTestNotification,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ─── 5.1. AI Vision & Scanner ───
          _buildSectionHeader(Icons.auto_awesome_rounded, 'AI Vision & Scanner'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                  secondary: _buildIconBadge(Icons.document_scanner_outlined, isDark),
                  title: Text('AI Packaging Autofill', style: AppTextStyles.titleSmall),
                  subtitle: Text(
                    'Extract product name, expiry date, and details from package photos',
                    style: AppTextStyles.caption,
                  ),
                  activeColor: AppColors.primaryStrong,
                  value: settings.aiScanEnabled,
                  onChanged: (val) => settings.setAiScanEnabled(val),
                ),
                Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                  leading: _buildIconBadge(Icons.key_rounded, isDark),
                  title: Text('Google Gemini API Key', style: AppTextStyles.titleSmall),
                  subtitle: Text(
                    settings.hasGeminiApiKey
                        ? 'Direct Fast Mode (${settings.maskedGeminiApiKey})'
                        : 'Using Dateora Cloud Proxy (Tap to set your key)',
                    style: AppTextStyles.caption,
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: settings.hasGeminiApiKey ? AppColors.statusSuccessBg : AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: settings.hasGeminiApiKey
                            ? AppColors.statusSuccess.withOpacity(0.4)
                            : AppColors.primaryStrong.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      settings.hasGeminiApiKey ? 'Direct' : 'Configure',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: settings.hasGeminiApiKey ? AppColors.statusSuccess : AppColors.primaryDark,
                      ),
                    ),
                  ),
                  onTap: () => _showApiKeyBottomSheet(settings),
                ),
                Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                  leading: _buildIconBadge(Icons.bolt_rounded, isDark),
                  title: Text('Daily Scans', style: AppTextStyles.titleSmall),
                  subtitle: Text(
                    '${settings.dailyScanCount} scan(s) performed today',
                    style: AppTextStyles.caption,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ─── 6. Local Data & Backup ───
          _buildSectionHeader(Icons.save_rounded, 'Backup & Storage'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                  leading: _buildIconBadge(Icons.upload_file_rounded, isDark),
                  title: Text(l10n?.settingsExportData ?? 'Export Backup File', style: AppTextStyles.titleSmall),
                  subtitle: Text(l10n?.settingsExportSubtitle ?? 'Export all items into an offline JSON file', style: AppTextStyles.caption),
                  trailing: const Icon(Icons.share_outlined, size: 20),
                  onTap: _exportJson,
                ),
                Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                  leading: _buildIconBadge(Icons.download_rounded, isDark),
                  title: Text(l10n?.settingsImportData ?? 'Import Backup File', style: AppTextStyles.titleSmall),
                  subtitle: Text(l10n?.settingsImportSubtitle ?? 'Restore items from a previous backup file', style: AppTextStyles.caption),
                  trailing: const Icon(Icons.folder_open_outlined, size: 20),
                  onTap: _importJson,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ─── 7. Privacy & Anonymous Usage Data ───
          _buildSectionHeader(Icons.shield_rounded, l10n?.settingsSectionPrivacy ?? 'Privacy & Community'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                  secondary: _buildIconBadge(Icons.analytics_outlined, isDark),
                  title: Text(l10n?.settingsAnalyticsToggle ?? 'Help improve Dateora', style: AppTextStyles.titleSmall),
                  subtitle: Text(
                    l10n?.settingsAnalyticsSubtitle ??
                        'Share anonymous usage data to help us fix issues. No names or private data are ever sent.',
                    style: AppTextStyles.caption,
                  ),
                  activeColor: AppColors.primaryStrong,
                  value: settings.analyticsEnabled,
                  onChanged: (val) => settings.setAnalyticsEnabled(val),
                ),
                Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                  leading: _buildIconBadge(Icons.share_rounded, isDark),
                  title: Text(l10n?.settingsTellAFriend ?? 'Tell a Friend', style: AppTextStyles.titleSmall),
                  subtitle: Text(
                    l10n?.settingsTellAFriendSubtitle ?? 'Share Dateora with family and friends',
                    style: AppTextStyles.caption,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () => _tellAFriend(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ─── 8. About Dateora ───
          _buildSectionHeader(Icons.info_outline_rounded, l10n?.settingsSectionAbout ?? 'About Dateora'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                  leading: _buildIconBadge(Icons.verified_rounded, isDark),
                  title: const Text('Dateora', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Version 1.0.0 (Build 1) • Smart Expiry Tracker', style: TextStyle(fontSize: 12)),
                ),
                Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                  leading: _buildIconBadge(Icons.lock_outline_rounded, isDark),
                  title: const Text('Offline Architecture', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('All photos, item names & dates stay on your phone.', style: TextStyle(fontSize: 12)),
                ),
                Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                  leading: _buildIconBadge(Icons.policy_outlined, isDark),
                  title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Google Play compliant policy • Data & permissions', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ─── 9. Danger Zone ───
          _buildSectionHeader(Icons.warning_amber_rounded, 'Danger Zone', isDestructive: true),
          AppCard(
            color: isDark ? AppColors.statusDanger.withOpacity(0.08) : const Color(0xFFFEF2F2),
            border: Border.all(
              color: AppColors.statusDanger.withOpacity(0.3),
              width: 1.2,
            ),
            padding: EdgeInsets.zero,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.statusDanger.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete_forever_rounded, color: AppColors.statusDanger, size: 20),
              ),
              title: Text(
                'Delete All Data',
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.statusDanger,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                'Permanently wipe all local items, history and images',
                style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.statusDanger),
              onTap: _confirmDeleteAll,
            ),
          ),

          const SizedBox(height: 60),
        ],
      ),
    );
  }

  // ─── Helper Widgets ───

  Widget _buildAppHeaderHero(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF132E27), const Color(0xFF0F172A)]
              : [AppColors.primarySoft, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: AppColors.primary.withOpacity(isDark ? 0.35 : 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryStrong],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryStrong.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.eco_rounded, color: Colors.white, size: 28),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Dateora',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryStrong.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'v1.0.0',
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryStrong,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Smart Offline Expiry & Bachat Tracker',
                      style: AppTextStyles.caption.copyWith(
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface.withOpacity(0.5) : Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shield_outlined, size: 14, color: AppColors.primaryStrong),
                const SizedBox(width: 6),
                Text(
                  '100% Offline • Data Stored On Your Device',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOptionCard({
    required ThemeMode mode,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final selectedBg = isDark
        ? AppColors.primaryDark.withOpacity(0.28)
        : AppColors.primarySoft;
    final unselectedBg = isDark ? AppColors.darkSurface : AppColors.lightBg;
    final borderColor = isSelected
        ? AppColors.primaryStrong
        : (isDark ? AppColors.darkBorder : AppColors.lightBorder);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : unselectedBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryStrong.withOpacity(0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildThemeMiniPreview(mode, isDark, isSelected),
                const SizedBox(height: 7),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? AppColors.primaryStrong
                          : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    subtitle,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? AppColors.primaryDark
                          : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                    ),
                  ),
                ),
              ],
            ),
            if (isSelected)
              Positioned(
                top: -2,
                right: 2,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryStrong,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.check_rounded, size: 11, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeMiniPreview(ThemeMode mode, bool isDark, bool isSelected) {
    switch (mode) {
      case ThemeMode.system:
        return Container(
          width: 46,
          height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryStrong.withOpacity(0.4)
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    color: const Color(0xFFF8FAFC),
                    padding: const EdgeInsets.only(top: 4, left: 3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 10,
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppColors.primaryStrong,
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        ),
                        const SizedBox(height: 2.5),
                        Container(
                          width: 14,
                          height: 2,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(width: 1, color: isDark ? Colors.white24 : Colors.black12),
                Expanded(
                  child: Container(
                    color: const Color(0xFF0F172A),
                    padding: const EdgeInsets.only(top: 4, left: 3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 10,
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppColors.primaryStrong,
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        ),
                        const SizedBox(height: 2.5),
                        Container(
                          width: 14,
                          height: 2,
                          decoration: BoxDecoration(
                            color: const Color(0xFF334155),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

      case ThemeMode.light:
        return Container(
          width: 46,
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryStrong.withOpacity(0.4)
                  : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 12,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.primaryStrong,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                  const Icon(Icons.wb_sunny_rounded, size: 8, color: Color(0xFFF59E0B)),
                ],
              ),
              const SizedBox(height: 3),
              Container(
                width: 26,
                height: 2.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(height: 2.5),
              Container(
                width: 18,
                height: 2.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        );

      case ThemeMode.dark:
        return Container(
          width: 46,
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryStrong.withOpacity(0.4)
                  : const Color(0xFF334155),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 12,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.primaryStrong,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                  const Icon(Icons.nightlight_round, size: 8, color: Color(0xFF818CF8)),
                ],
              ),
              const SizedBox(height: 3),
              Container(
                width: 26,
                height: 2.5,
                decoration: BoxDecoration(
                  color: const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(height: 2.5),
              Container(
                width: 18,
                height: 2.5,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildLanguageTile({
    required String label,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.card),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primaryDark.withOpacity(0.3) : AppColors.primarySoft)
              : (isDark ? AppColors.darkSurface : AppColors.lightBg),
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryStrong
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? AppColors.primaryStrong : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 10.5,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.primaryStrong),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionRow({
    required IconData icon,
    required String name,
    required String desc,
    required bool isGranted,
    required VoidCallback onRequest,
    required bool isDark,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: isGranted ? null : onRequest,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            _buildIconBadge(icon, isDark),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.titleSmall.copyWith(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isGranted ? AppColors.statusSuccessBg : AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isGranted ? AppColors.statusSuccess.withOpacity(0.3) : AppColors.primaryStrong.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isGranted ? Icons.check_circle_rounded : Icons.lock_open_rounded,
                    size: 12,
                    color: isGranted ? AppColors.statusSuccess : AppColors.primaryDark,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isGranted ? 'Allowed' : 'Grant',
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isGranted ? AppColors.statusSuccess : AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconBadge(IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: AppColors.primaryStrong, size: 20),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, {bool isDestructive = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDestructive
        ? AppColors.statusDanger
        : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted);

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.xs, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            title.toUpperCase(),
            style: AppTextStyles.label.copyWith(
              color: color,
              letterSpacing: 0.8,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
