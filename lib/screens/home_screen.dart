import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/item.dart';
import '../providers/items_provider.dart';
import '../services/photo_service.dart';
import '../services/savings_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/item_tile.dart';
import '../widgets/section_header.dart';
import 'add_item_screen.dart';
import 'bachat_screen.dart';

class HomeScreen extends StatelessWidget {
  final Function(int tabIndex, String? filter) onNavigateTab;

  const HomeScreen({super.key, required this.onNavigateTab});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 17) return 'Good Afternoon 🌤️';
    return 'Good Evening 🌙';
  }

  Future<void> _launchSmartScanner(BuildContext context) async {
    final path = await PhotoService.captureOrPickPhoto(
      context: context,
      source: ImageSource.camera,
    );
    if (path != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddItemScreen(
            initialPhotoPath: path,
            autoTriggerAiScan: true,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ItemsProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final expiringSoon = provider.expiringSoonItems;
    final l10n = AppLocalizations.of(context);

    final allItems = <Item>[...provider.activeItems, ...provider.historyItems];
    final now = DateTime.now();
    final thisMonthSavings = SavingsService.calculateMonthSavings(allItems, year: now.year, month: now.month);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.screenHorizontal,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n != null ? '${l10n.homeGreeting} 👋' : _getGreeting(),
              style: AppTextStyles.caption.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.55),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              l10n?.appName ?? 'Dateora',
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l10n?.itemAiScanner ?? 'Smart AI Scanner',
            icon: const Icon(Icons.auto_awesome_rounded, color: AppColors.primaryStrong),
            onPressed: () => _launchSmartScanner(context),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: provider.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryStrong),
              ),
            )
          : RefreshIndicator(
              color: AppColors.primaryStrong,
              onRefresh: () => provider.loadItems(),
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                  vertical: AppSpacing.md,
                ),
                children: [
                  // AI Smart Scanner banner
                  InkWell(
                    borderRadius: AppRadius.cardRadius,
                    onTap: () => _launchSmartScanner(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [AppColors.darkCard, AppColors.darkSurface]
                              : [const Color(0xFFF0FDF4), Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: AppRadius.cardRadius,
                        border: Border.all(
                          color: AppColors.primaryStrong.withOpacity(isDark ? 0.35 : 0.25),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryStrong.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF22C55E), AppColors.primaryStrong],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryStrong.withOpacity(0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n?.itemAiScanner ?? 'Smart AI Scanner',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l10n?.onboardingDesc3 ?? 'Snap photo to auto-detect name & expiry date',
                                  style: AppTextStyles.caption.copyWith(
                                    fontSize: 11.5,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryStrong,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryStrong.withOpacity(0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.camera_alt_rounded, size: 13, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'Scan',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),
                  // Three Stat Cards
                  Row(
                    children: [
                      _buildStatCard(
                        context,
                        title: l10n?.homeActiveItems ?? 'Total Items',
                        count: provider.totalCount,
                        color: AppColors.primaryStrong,
                        bgColor: isDark ? AppColors.darkCard : AppColors.primarySoft,
                        icon: Icons.inventory_2_outlined,
                        onTap: () => onNavigateTab(1, 'all'),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      _buildStatCard(
                        context,
                        title: l10n?.homeExpiringSoon ?? 'Expiring Soon',
                        count: provider.expiringSoonCount,
                        color: AppColors.statusWarning,
                        bgColor: isDark ? AppColors.darkCard : AppColors.statusWarningBg,
                        icon: Icons.access_time_rounded,
                        onTap: () => onNavigateTab(1, 'expiring_soon'),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      _buildStatCard(
                        context,
                        title: l10n?.homeExpired ?? 'Expired',
                        count: provider.expiredCount,
                        color: AppColors.statusDanger,
                        bgColor: isDark ? AppColors.darkCard : AppColors.statusDangerBg,
                        icon: Icons.error_outline_rounded,
                        onTap: () => onNavigateTab(1, 'expired'),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Bachat Card (Task 4)
                  InkWell(
                    borderRadius: AppRadius.cardRadius,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BachatScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
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
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.savings_rounded, color: Colors.white, size: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n?.homeBachatTitle ?? 'Bachat Tracker',
                                    style: AppTextStyles.titleSmall.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryStrong,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryStrong.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Details',
                                      style: AppTextStyles.caption.copyWith(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryStrong,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.primaryStrong),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.statusSafe.withOpacity(isDark ? 0.15 : 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.statusSafe.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n?.homeBachatSaved ?? 'Saved',
                                        style: AppTextStyles.caption.copyWith(
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '₹${thisMonthSavings.savedAmount.toStringAsFixed(0)}',
                                        style: AppTextStyles.titleMedium.copyWith(
                                          color: AppColors.statusSafe,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 17,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.statusDanger.withOpacity(isDark ? 0.15 : 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.statusDanger.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n?.homeBachatWasted ?? 'Wasted',
                                        style: AppTextStyles.caption.copyWith(
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '₹${thisMonthSavings.wastedAmount.toStringAsFixed(0)}',
                                        style: AppTextStyles.titleMedium.copyWith(
                                          color: thisMonthSavings.wastedAmount > 0
                                              ? AppColors.statusDanger
                                              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 17,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryStrong.withOpacity(isDark ? 0.15 : 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.primaryStrong.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n?.bachatItemsUsed ?? 'Used',
                                        style: AppTextStyles.caption.copyWith(
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${thisMonthSavings.usedCount}',
                                        style: AppTextStyles.titleMedium.copyWith(
                                          color: AppColors.primaryStrong,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 17,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 12,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l10n?.homeBachatEstimated ?? 'Estimated based on entered prices',
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 11,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sectionGap),

                  // Section Header: Attention Needed
                  SectionHeader(
                    title: l10n?.homeExpiringSoonSection ?? 'Attention Needed',
                    subtitle: l10n?.homeSubtitle ?? 'Items requiring priority action',
                    actionText: provider.totalCount > 0 ? (l10n?.homeViewAll ?? 'View All') : null,
                    onAction: () => onNavigateTab(1, 'all'),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  if (provider.totalCount == 0)
                    EmptyState(
                      imageAsset: 'assets/illustrations/empty_basket.png',
                      icon: Icons.eco_rounded,
                      title: l10n?.itemsEmptyTitle ?? 'Start Tracking Your Pantry',
                      message: l10n?.itemsEmptySubtitle ??
                          'Add items from your fridge, bathroom or medicine cabinet to get alerted before they expire.',
                      buttonText: l10n?.homeAddNewItem ?? 'Add First Item',
                      onButtonPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AddItemScreen()),
                        );
                      },
                    )
                  else if (expiringSoon.isEmpty)
                    AppCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.xxl,
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : AppColors.statusSafeBg,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 32,
                              color: AppColors.statusSafe,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            l10n?.homeNoExpiringSoon ?? 'Everything is fresh!',
                            style: AppTextStyles.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n?.homeNoExpiringSoonSubtitle ?? 'No items are expiring in the upcoming alert window.',
                            style: AppTextStyles.caption.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ...expiringSoon.map((item) => ItemTile(item: item)),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required int count,
    required Color color,
    required Color bgColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: AppCard(
        onTap: onTap,
        color: isDark ? AppColors.darkCard : color.withOpacity(0.04),
        border: Border.all(
          color: color.withOpacity(isDark ? 0.35 : 0.22),
          width: 1.2,
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
