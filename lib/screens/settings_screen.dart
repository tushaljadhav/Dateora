import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/database_helper.dart';
import '../providers/items_provider.dart';
import '../providers/settings_provider.dart';
import '../services/export_service.dart';
import '../services/permission_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_card.dart';

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

  void _exportJson() async {
    await ExportService.exportData();
  }

  void _importJson() async {
    final result = await ExportService.importData();
    if (!mounted) return;
    if (result['success'] == true) {
      final itemsProvider = Provider.of<ItemsProvider>(context, listen: false);
      await itemsProvider.loadItems();
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

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.screenHorizontal,
        title: Text(
          'Settings',
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
          vertical: AppSpacing.md,
        ),
        children: [
          // ─── 1. App Header Hero Card ───
          _buildAppHeaderHero(isDark),

          const SizedBox(height: AppSpacing.lg),

          // ─── 2. Appearance & Theme ───
          _buildSectionHeader('APPEARANCE & THEME'),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildIconBadge(Icons.palette_outlined, isDark),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Theme Mode', style: AppTextStyles.titleSmall),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _buildThemeSegmentOption(
                        title: 'System',
                        icon: Icons.brightness_auto_rounded,
                        isSelected: settings.themeMode == ThemeMode.system,
                        onTap: () => settings.setThemeMode(ThemeMode.system),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildThemeSegmentOption(
                        title: 'Light',
                        icon: Icons.light_mode_rounded,
                        isSelected: settings.themeMode == ThemeMode.light,
                        onTap: () => settings.setThemeMode(ThemeMode.light),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildThemeSegmentOption(
                        title: 'Dark',
                        icon: Icons.dark_mode_rounded,
                        isSelected: settings.themeMode == ThemeMode.dark,
                        onTap: () => settings.setThemeMode(ThemeMode.dark),
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
          _buildSectionHeader('DEVICE PERMISSIONS'),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('System Access Status', style: AppTextStyles.titleSmall),
                    InkWell(
                      onTap: _grantAllPermissions,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.refresh_rounded, size: 13, color: AppColors.primaryDark),
                            const SizedBox(width: 4),
                            Text(
                              'Grant All',
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
                  desc: 'Used to photograph expiry dates & packaging labels',
                  isGranted: _cameraGranted,
                  isDark: isDark,
                ),
                Divider(height: 18, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                _buildPermissionRow(
                  icon: Icons.photo_library_outlined,
                  name: 'Photos & Gallery',
                  desc: 'Pick existing product packaging photos offline',
                  isGranted: _photosGranted,
                  isDark: isDark,
                ),
                Divider(height: 18, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                _buildPermissionRow(
                  icon: Icons.notifications_none_rounded,
                  name: 'Expiry Notifications',
                  desc: 'Fires timely reminders before items expire',
                  isGranted: _notifGranted,
                  isDark: isDark,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ─── 5. Notifications Section ───
          _buildSectionHeader('NOTIFICATIONS & ALERTS'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                  secondary: _buildIconBadge(Icons.notifications_active_outlined, isDark),
                  title: Text('Expiry Reminders', style: AppTextStyles.titleSmall),
                  subtitle: Text('Receive alerts before items expire', style: AppTextStyles.caption),
                  activeColor: AppColors.primaryStrong,
                  value: settings.notificationsEnabled,
                  onChanged: (val) => settings.setNotificationsEnabled(val),
                ),
                Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                  leading: _buildIconBadge(Icons.access_time_rounded, isDark),
                  title: Text('Daily Alert Time', style: AppTextStyles.titleSmall),
                  subtitle: Text('Notifications fire at ${settings.dailyNotificationTime}', style: AppTextStyles.caption),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(8),
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
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ─── 6. Local Data & Backup (File) ───
          _buildSectionHeader('BACKUP & RESTORE (FILE)'),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              'Your data stays on this phone. Take a backup before changing phones.',
              style: AppTextStyles.caption.copyWith(
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          ),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                  leading: _buildIconBadge(Icons.file_upload_outlined, isDark),
                  title: Text('Export Backup File', style: AppTextStyles.titleSmall),
                  subtitle: Text('Export an offline JSON backup file', style: AppTextStyles.caption),
                  trailing: const Icon(Icons.share_outlined, size: 20),
                  onTap: _exportJson,
                ),
                Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                  leading: _buildIconBadge(Icons.file_download_outlined, isDark),
                  title: Text('Import JSON File', style: AppTextStyles.titleSmall),
                  subtitle: Text('Restore items from a Dateora backup', style: AppTextStyles.caption),
                  trailing: const Icon(Icons.folder_open_outlined, size: 20),
                  onTap: _importJson,
                ),
                Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.statusDanger.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_forever_rounded, color: AppColors.statusDanger, size: 20),
                  ),
                  title: Text(
                    'Delete All Data',
                    style: AppTextStyles.titleSmall.copyWith(color: AppColors.statusDanger),
                  ),
                  subtitle: Text('Wipe all local items, history and pictures', style: AppTextStyles.caption),
                  onTap: _confirmDeleteAll,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ─── 8. About Dateora ───
          _buildSectionHeader('ABOUT DATEORA'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                  leading: _buildIconBadge(Icons.info_outline_rounded, isDark),
                  title: Text('Dateora', style: AppTextStyles.titleSmall),
                  subtitle: Text('Version 1.0.0 (Build 1) • Smart Expiry Tracker', style: AppTextStyles.caption),
                ),
                Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                  leading: _buildIconBadge(Icons.shield_outlined, isDark),
                  title: Text('Privacy & Security', style: AppTextStyles.titleSmall),
                  subtitle: Text('All data is stored locally on this phone by default.', style: AppTextStyles.caption),
                ),
              ],
            ),
          ),



          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  // ─── Helper Widgets ───

  Widget _buildAppHeaderHero(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.2,
        ),
      ),
      child: Row(
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
                  color: AppColors.primaryStrong.withOpacity(0.25),
                  blurRadius: 10,
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
                      style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'v1.0.0',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Smart Offline Expiry Tracker',
                  style: AppTextStyles.caption.copyWith(
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSegmentOption({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.card),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primaryDark.withOpacity(0.25) : AppColors.primarySoft)
              : (isDark ? AppColors.darkSurface : AppColors.lightBg),
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isSelected ? AppColors.primaryStrong : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.primaryStrong : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: AppTextStyles.caption.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primaryStrong : null,
              ),
            ),
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
    required bool isDark,
  }) {
    return Row(
      children: [
        _buildIconBadge(icon, isDark),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTextStyles.titleSmall.copyWith(fontSize: 13)),
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isGranted ? AppColors.statusSuccessBg : AppColors.statusWarningBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isGranted ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                size: 12,
                color: isGranted ? AppColors.statusSuccess : AppColors.statusWarning,
              ),
              const SizedBox(width: 4),
              Text(
                isGranted ? 'Allowed' : 'Not Allowed',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isGranted ? AppColors.statusSuccess : AppColors.statusWarning,
                ),
              ),
            ],
          ),
        ),
      ],
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

  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.xs),
      child: Text(
        title,
        style: AppTextStyles.label.copyWith(
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
