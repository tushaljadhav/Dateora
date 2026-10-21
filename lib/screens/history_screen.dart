import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../models/item.dart';
import '../providers/items_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_card.dart';
import '../widgets/category_badge.dart';
import '../widgets/empty_state.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ItemsProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final usedItems = provider.historyItems.where((i) => i.status == 'used').toList();
    final disposedItems = provider.historyItems.where((i) => i.status == 'disposed').toList();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.screenHorizontal,
        title: Text(
          'History & Archives',
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w800),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primaryStrong,
              indicatorWeight: 3,
              labelColor: AppColors.primaryStrong,
              unselectedLabelColor: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              labelStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
              unselectedLabelStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500),
              tabs: [
                Tab(text: 'Used (${usedItems.length})'),
                Tab(text: 'Disposed (${disposedItems.length})'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHistoryList(usedItems, 'No items marked as used yet'),
          _buildHistoryList(disposedItems, 'No items marked as disposed yet'),
        ],
      ),
    );
  }

  Widget _buildHistoryList(List<Item> items, String emptyMessage) {
    if (items.isEmpty) {
      return Center(
        child: EmptyState(
          icon: Icons.history_rounded,
          title: 'Empty Category',
          message: emptyMessage,
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.md,
      ),
      itemCount: items.length,
      itemBuilder: (ctx, index) {
        final item = items[index];
        final cat = CategoryModel.getById(item.category);

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                CategoryBadge(categoryId: item.category, size: 46),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${cat.name} • Expired ${item.expiryDate}',
                        style: AppTextStyles.caption.copyWith(
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.restore_rounded, size: 16),
                  label: const Text('Restore'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    side: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                  onPressed: () async {
                    final provider = Provider.of<ItemsProvider>(context, listen: false);
                    await provider.restoreItem(item);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.primaryStrong,
                          content: Text('Restored "${item.name}" to active items'),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
