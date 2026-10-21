import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/items_provider.dart';
import '../services/photo_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/item_tile.dart';
import '../widgets/section_header.dart';
import 'add_item_screen.dart';

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

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.screenHorizontal,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getGreeting(),
              style: AppTextStyles.caption.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.55),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Dateora',
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Smart AI Scanner',
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
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    onTap: () => _launchSmartScanner(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(
                          color: AppColors.primaryStrong.withOpacity(0.25),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryStrong.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              color: AppColors.primaryStrong,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Smart AI Scanner',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Snap photo to auto-detect name & expiry date',
                                  style: AppTextStyles.caption.copyWith(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.primaryStrong,
                              borderRadius: BorderRadius.circular(20),
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
                        title: 'Total Items',
                        count: provider.totalCount,
                        color: AppColors.primaryStrong,
                        bgColor: isDark ? AppColors.darkCard : AppColors.primarySoft,
                        icon: Icons.inventory_2_outlined,
                        onTap: () => onNavigateTab(1, 'all'),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      _buildStatCard(
                        context,
                        title: 'Expiring Soon',
                        count: provider.expiringSoonCount,
                        color: AppColors.statusWarning,
                        bgColor: isDark ? AppColors.darkCard : AppColors.statusWarningBg,
                        icon: Icons.access_time_rounded,
                        onTap: () => onNavigateTab(1, 'expiring_soon'),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      _buildStatCard(
                        context,
                        title: 'Expired',
                        count: provider.expiredCount,
                        color: AppColors.statusDanger,
                        bgColor: isDark ? AppColors.darkCard : AppColors.statusDangerBg,
                        icon: Icons.error_outline_rounded,
                        onTap: () => onNavigateTab(1, 'expired'),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.sectionGap),

                  // Section Header: Attention Needed
                  SectionHeader(
                    title: 'Attention Needed',
                    subtitle: 'Items requiring priority action',
                    actionText: provider.totalCount > 0 ? 'View All' : null,
                    onAction: () => onNavigateTab(1, 'all'),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  if (provider.totalCount == 0)
                    EmptyState(
                      imageAsset: 'assets/illustrations/empty_basket.png',
                      icon: Icons.eco_rounded,
                      title: 'Start Tracking Your Pantry',
                      message:
                          'Add items from your fridge, bathroom or medicine cabinet to get alerted before they expire.',
                      buttonText: 'Add First Item',
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
                            'Everything is fresh!',
                            style: AppTextStyles.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'No items are expiring in the upcoming alert window.',
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
    return Expanded(
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
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
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
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
