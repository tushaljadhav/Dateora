import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_card.dart';

/// Official In-App Privacy Policy Screen (Google Play Console Compliant)
/// Executive, clean, professional legal document layout.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const String publicPolicyUrl = 'https://dateora.onrender.com/privacy';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 20),
            tooltip: 'Share Policy Link',
            onPressed: () {
              Share.share(
                'Dateora Official Privacy Policy: $publicPolicyUrl',
                subject: 'Dateora Privacy Policy',
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        children: [
          // ─── Executive Header Card ───
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primaryStrong.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'D',
                          style: TextStyle(
                            color: AppColors.primaryStrong,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dateora Smart Expiry Tracker',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                          Text(
                            'Official Privacy & Data Protection Policy',
                            style: AppTextStyles.caption.copyWith(
                              color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Text(
                  'Dateora is built on an offline-first architecture. Your grocery lists, expiry dates, photos, and consumption patterns belong entirely to you and stay on your device.',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.55,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFeatureChip(Icons.storage_outlined, '100% On-Device DB', isDark),
                    _buildFeatureChip(Icons.person_outline, 'No Account Needed (v1.0)', isDark),
                    _buildFeatureChip(Icons.shield_outlined, 'Zero Data Brokering', isDark),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // ─── Section 1: Local Storage ───
          _buildLegalCard(
            sectionNumber: '1',
            title: 'Overview & Account Roadmap',
            content:
                'Dateora is an offline-first mobile application. All items, expiration dates, purchase dates, categories, quantities, and photos are saved locally in the secure SQLite database on your device.\n\n• Current Release (v1.0): No mandatory accounts, passwords, or phone numbers are required to track expiry dates.\n\n• Future Cloud & Subscription Roadmap: In upcoming updates, as Dateora introduces multi-device cloud synchronization, family sharing, and premium subscription tiers, users will have the option to create a secure account (via email or OAuth) to manage their subscriptions. Cloud data will be encrypted and users can permanently delete their account and cloud data anytime.',
            isDark: isDark,
          ),

          const SizedBox(height: AppSpacing.md),

          // ─── Section 2: Permissions ───
          _buildLegalCard(
            sectionNumber: '2',
            title: 'Android Permissions & Justifications',
            content:
                '• Camera (CAMERA): Requested only when scanning barcodes on packaging or capturing an expiration date stamp.\n\n• Photos / Storage: Used solely if you choose to attach an existing product photo from your device storage.\n\n• Notifications (POST_NOTIFICATIONS): Scheduled locally on the operating system clock to warn you before items expire. No remote push server tracking is involved.',
            isDark: isDark,
          ),

          const SizedBox(height: AppSpacing.md),

          // ─── Section 3: AI Vision ───
          _buildLegalCard(
            sectionNumber: '3',
            title: 'AI Vision Scanning & Data Handling',
            content:
                'When you choose to tap "Scan Packaging with AI":\n• Only the selected packaging photo is sent encrypted (HTTPS/TLS 1.3) to the Google Gemini API to extract text and dates.\n• Images are processed transiently in volatile memory and are not stored or used to train public models.\n• You can use Dateora completely offline via manual entry or barcode scanning without ever using AI scanning.',
            isDark: isDark,
          ),

          const SizedBox(height: AppSpacing.md),

          // ─── Section 4: Barcodes ───
          _buildLegalCard(
            sectionNumber: '4',
            title: 'Barcode Lookup (Open Food Facts & AI)',
            content:
                'Scanning a barcode queries public databases (Open Food Facts or our AI proxy) solely using the numerical code (e.g. 8901030383848) to fetch the public product name and category. No personal identity is attached to barcode queries.',
            isDark: isDark,
          ),

          const SizedBox(height: AppSpacing.md),

          // ─── Section 5: Analytics ───
          _buildLegalCard(
            sectionNumber: '5',
            title: 'Anonymous Technical Analytics',
            content:
                'If enabled in Settings, anonymous technical metrics (app crashes, device model, Android OS version) are collected via Firebase Analytics to help improve app stability.\n\nNo personal names, photos, or barcodes are ever included. You can disable this anytime via Settings.',
            isDark: isDark,
          ),

          const SizedBox(height: AppSpacing.md),

          // ─── Section 6: Data Deletion ───
          _buildLegalCard(
            sectionNumber: '6',
            title: 'Data Ownership & Deletion Rights',
            content:
                'You have absolute control over your data:\n• Delete individual items anytime with a swipe.\n• Wipe all data permanently via Settings &rarr; Clear All Data.\n• Uninstalling the app permanently purges all database tables and images from disk.',
            isDark: isDark,
          ),

          const SizedBox(height: AppSpacing.md),

          // ─── Section 7: Children's Privacy ───
          _buildLegalCard(
            sectionNumber: '7',
            title: "Children's Privacy (COPPA Compliance)",
            content:
                'Dateora is a household utility application intended for general audiences. We do not knowingly solicit, collect, or store personal information from children under the age of 13 (or under 16 in the European Union).',
            isDark: isDark,
          ),

          const SizedBox(height: AppSpacing.md),

          // ─── Section 8: Google Play Console Live URL ───
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.public_rounded, color: AppColors.primaryStrong, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Google Play Console Web URL',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Official live public URL required for Google Play Console submission:',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          publicPolicyUrl,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                            color: AppColors.primaryStrong,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(const ClipboardData(text: publicPolicyUrl));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Privacy Policy URL copied to clipboard!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryStrong.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.copy_rounded, size: 16, color: AppColors.primaryStrong),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // ─── Section 9: Developer Contact ───
          _buildLegalCard(
            sectionNumber: '8',
            title: 'Developer Contact & Inquiries',
            content:
                'Developer: Tushal Jadhav\nApplication: Dateora — Smart Expiry Tracker\nSupport Email: tushaljadhav123@gmail.com\nOfficial Website: https://dateora.onrender.com',
            isDark: isDark,
          ),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primaryStrong),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalCard({
    required String sectionNumber,
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
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Center(
                  child: Text(
                    sectionNumber,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryStrong,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(
              height: 1.55,
              fontSize: 12.8,
              color: isDark ? AppColors.darkTextMuted : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}
