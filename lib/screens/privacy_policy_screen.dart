import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_card.dart';

/// Official In-App Privacy Policy Screen (Google Play Console Compliant)
/// Explains On-Device Storage, Permissions, AI Vision processing, and user data rights.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const String publicPolicyUrl = 'https://dateora.onrender.com/privacy';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Policy Link',
            onPressed: () {
              Share.share(
                'Dateora Privacy Policy: $publicPolicyUrl',
                subject: 'Dateora Official Privacy Policy',
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg),
        children: [
          // ─── Header Card ───
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF13231B), const Color(0xFF0F1A15)]
                    : [const Color(0xFFE8F5E9), const Color(0xFFF1F8E9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: AppColors.primaryStrong.withOpacity(isDark ? 0.35 : 0.4),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryStrong.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield_rounded, color: AppColors.primaryStrong, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dateora Privacy Commitment',
                            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'Effective: October 2026 • Version 1.0.0',
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
                  'Dateora is built on an offline-first architecture. Your grocery lists, expiry dates, photos, and consumption patterns belong to you and stay on your phone.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    height: 1.5,
                    color: isDark ? Colors.white70 : const Color(0xFF2E3A33),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildPill(Icons.storage_rounded, '100% On-Device DB', isDark),
                    _buildPill(Icons.person_off_outlined, 'No Account Needed', isDark),
                    _buildPill(Icons.block_outlined, 'Zero Ads / No Data Selling', isDark),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ─── Section 1: Data Storage ───
          _buildPolicyCard(
            icon: Icons.smartphone_rounded,
            title: '1. Local Storage & Zero Cloud Tracking',
            content:
                'All item names, expiry dates, purchase dates, categories, quantities, and photos you add are saved locally in the secure SQLite database on your device.\n\nNo accounts, passwords, or phone numbers are ever required to use Dateora.',
            isDark: isDark,
          ),

          const SizedBox(height: AppSpacing.md),

          // ─── Section 2: Permissions ───
          _buildPolicyCard(
            icon: Icons.camera_alt_outlined,
            title: '2. Device Permissions',
            content:
                '• Camera: Used strictly to scan barcodes on packaging and photograph expiration date stamps.\n\n• Storage / Photos: Used only if you choose to pick an existing product photo from your gallery.\n\n• Notifications: Scheduled locally on your device clock to alert you before items expire. No remote push server is involved.',
            isDark: isDark,
          ),

          const SizedBox(height: AppSpacing.md),

          // ─── Section 3: AI Vision ───
          _buildPolicyCard(
            icon: Icons.auto_awesome_rounded,
            title: '3. AI Vision Scanning (Google Gemini)',
            content:
                'When you choose to use the AI packaging scan:\n• Only the selected packaging photo is sent encrypted (HTTPS) to the Google Gemini API to read product and date text.\n• Images are processed transiently in volatile memory and are not stored or used to train public models.\n• You can use Dateora completely without AI via manual entry or barcode scanning anytime.',
            isDark: isDark,
          ),

          const SizedBox(height: AppSpacing.md),

          // ─── Section 4: Barcode Scanning ───
          _buildPolicyCard(
            icon: Icons.qr_code_scanner_rounded,
            title: '4. Barcode Lookup (Open Food Facts & AI)',
            content:
                'Scanning a barcode queries public databases (Open Food Facts or our AI proxy) solely using the numerical code (e.g. 8901030383848) to fetch the public product name and category. No personal identity is attached to barcode queries.',
            isDark: isDark,
          ),

          const SizedBox(height: AppSpacing.md),

          // ─── Section 5: Analytics ───
          _buildPolicyCard(
            icon: Icons.analytics_outlined,
            title: '5. Anonymous Analytics',
            content:
                'If enabled in Settings, anonymous technical metrics (app crashes, device model, Android OS version) are collected via Firebase Analytics to help improve app stability.\n\nNo personal names, photos, or barcodes are ever included. You can disable this anytime in Settings.',
            isDark: isDark,
          ),

          const SizedBox(height: AppSpacing.md),

          // ─── Section 6: Data Deletion ───
          _buildPolicyCard(
            icon: Icons.delete_sweep_rounded,
            title: '6. Data Ownership & Deletion',
            content:
                'You have absolute control over your data:\n• Delete individual items anytime with a swipe.\n• Wipe all data permanently via Settings &rarr; Clear All Data.\n• Uninstalling the app permanently purges all database tables and images from disk.',
            isDark: isDark,
          ),

          const SizedBox(height: AppSpacing.md),

          // ─── Section 7: Children's Privacy ───
          _buildPolicyCard(
            icon: Icons.family_restroom_rounded,
            title: "7. Children's Privacy (COPPA & GDPR-K)",
            content:
                'Dateora does not knowingly collect, solicit, or retain personal data from children under the age of 13 (or 16 in the EU). It is a general audience utility intended for household inventory management.',
            isDark: isDark,
          ),

          const SizedBox(height: AppSpacing.md),

          // ─── Section 8: Public Play Console URL ───
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.link_rounded, color: AppColors.primaryStrong, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Google Play Console Web URL',
                      style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'This official policy is publicly hosted and live for Google Play Console submission at:',
                  style: TextStyle(fontSize: 12.5, height: 1.4),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          publicPolicyUrl,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryStrong,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        tooltip: 'Copy Link',
                        onPressed: () {
                          Clipboard.setData(const ClipboardData(text: publicPolicyUrl));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Privacy Policy URL copied to clipboard!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // ─── Section 9: Developer Contact ───
          _buildPolicyCard(
            icon: Icons.mail_outline_rounded,
            title: '8. Developer Contact',
            content:
                'Developer: Tushal Jadhav\nApplication: Dateora (Smart Expiry Tracker)\nSupport Email: tushaljadhav.dev@gmail.com\nWebsite: https://dateora.onrender.com',
            isDark: isDark,
          ),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildPill(IconData icon, String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryStrong.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.primaryStrong.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primaryStrong),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryStrong,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyCard({
    required IconData icon,
    required String title,
    required String content,
    required bool isDark,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primaryStrong),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: AppTextStyles.bodyMedium.copyWith(
              height: 1.5,
              fontSize: 13,
              color: isDark ? AppColors.darkTextMuted : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}
