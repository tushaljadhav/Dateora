import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category_model.dart';
import '../providers/items_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';
import '../widgets/empty_state.dart';
import '../widgets/item_tile.dart';
import 'add_item_screen.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ItemsProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final items = provider.filteredItems;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.screenHorizontal,
        title: Row(
          children: [
            Text(
              'Items',
              style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                '${provider.totalCount}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primaryStrong,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              Icons.tune_rounded,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
            tooltip: 'Sort items',
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
            color: isDark ? AppColors.darkSurface : Colors.white,
            onSelected: (sort) => provider.setSortOption(sort),
            itemBuilder: (ctx) => [
              _buildSortItem('soonest', 'Expiry Date (Soonest first)', provider.sortOption),
              _buildSortItem('recently_added', 'Recently Added', provider.sortOption),
              _buildSortItem('name_asc', 'Name (A–Z)', provider.sortOption),
            ],
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: Column(
        children: [
          // Polished Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
              vertical: AppSpacing.xs,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.button),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => provider.setSearchQuery(val),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search by item name or category...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.primaryStrong,
                    size: 22,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            provider.setSearchQuery('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
              ),
            ),
          ),

          // Horizontal Status Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                _buildStatusPill(
                  label: 'All',
                  value: 'all',
                  current: provider.statusFilter,
                  count: provider.totalCount,
                  onSelect: () => provider.setStatusFilter('all'),
                ),
                const SizedBox(width: AppSpacing.xs),
                _buildStatusPill(
                  label: 'Expiring Soon',
                  value: 'expiring_soon',
                  current: provider.statusFilter,
                  count: provider.expiringSoonCount,
                  onSelect: () => provider.setStatusFilter('expiring_soon'),
                  accentColor: AppColors.statusWarning,
                ),
                const SizedBox(width: AppSpacing.xs),
                _buildStatusPill(
                  label: 'Expired',
                  value: 'expired',
                  current: provider.statusFilter,
                  count: provider.expiredCount,
                  onSelect: () => provider.setStatusFilter('expired'),
                  accentColor: AppColors.statusDanger,
                ),
                const SizedBox(width: AppSpacing.xs),
                _buildStatusPill(
                  label: 'Safe',
                  value: 'safe',
                  current: provider.statusFilter,
                  count: provider.safeCount,
                  onSelect: () => provider.setStatusFilter('safe'),
                  accentColor: AppColors.statusSafe,
                ),
              ],
            ),
          ),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
              vertical: 4,
            ),
            child: Row(
              children: [
                _buildCategoryPill(
                  label: 'All Categories',
                  isSelected: provider.selectedCategory == null,
                  onTap: () => provider.setSelectedCategory(null),
                ),
                const SizedBox(width: AppSpacing.xs),
                ...CategoryModel.presetCategories.map((cat) {
                  final isSelected = provider.selectedCategory == cat.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: _buildCategoryPill(
                      label: cat.name,
                      icon: cat.icon,
                      iconColor: cat.color,
                      isSelected: isSelected,
                      onTap: () => provider.setSelectedCategory(isSelected ? null : cat.id),
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          // Items List View / Empty State
          Expanded(
            child: provider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryStrong),
                    ),
                  )
                : RefreshIndicator(
                    color: AppColors.primaryStrong,
                    onRefresh: () => provider.loadItems(),
                    child: items.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: AppSpacing.xxl),
                              EmptyState(
                                imageAsset: 'assets/illustrations/empty_basket.png',
                                icon: _getEmptyIcon(provider.statusFilter),
                                title: _getEmptyTitle(provider.statusFilter, _searchController.text),
                                message: _getEmptyMessage(provider.statusFilter, _searchController.text),
                                buttonText: provider.totalCount == 0 ? 'Add First Item' : null,
                                onButtonPressed: provider.totalCount == 0
                                    ? () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => const AddItemScreen()),
                                        );
                                      }
                                    : null,
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.screenHorizontal,
                              vertical: AppSpacing.sm,
                            ),
                            itemCount: items.length,
                            itemBuilder: (ctx, index) => ItemTile(item: items[index]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill({
    required String label,
    required String value,
    required String current,
    required int count,
    required VoidCallback onSelect,
    Color? accentColor,
  }) {
    final isSelected = current == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primaryStrong.withOpacity(0.3) : AppColors.primarySoft)
              : (isDark ? AppColors.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryStrong
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (accentColor != null) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? (isDark ? AppColors.primary : AppColors.primaryDark)
                    : (isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '($count)',
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
                color: isSelected
                    ? (isDark ? AppColors.primary : AppColors.primaryDark)
                    : (isDark ? AppColors.darkTextMuted.withOpacity(0.7) : AppColors.lightTextMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPill({
    required String label,
    IconData? icon,
    Color? iconColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primaryStrong.withOpacity(0.25) : AppColors.primarySoft)
              : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryStrong
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isSelected ? AppColors.primaryStrong : iconColor),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? AppColors.primary : AppColors.primaryDark)
                    : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildSortItem(String value, String label, String current) {
    final isSelected = current == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 18,
            color: isSelected
                ? AppColors.primaryStrong
                : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getEmptyIcon(String filter) {
    if (filter == 'expired') return Icons.verified_outlined;
    if (filter == 'expiring_soon') return Icons.sentiment_satisfied_alt_rounded;
    return Icons.search_off_rounded;
  }

  String _getEmptyTitle(String filter, String query) {
    if (query.isNotEmpty) return 'No matching items';
    if (filter == 'expired') return 'No expired items 🎉';
    if (filter == 'expiring_soon') return 'All items are fresh';
    if (filter == 'safe') return 'No items in safe status';
    return 'Your pantry is empty';
  }

  String _getEmptyMessage(String filter, String query) {
    if (query.isNotEmpty) return 'No items found matching "$query". Check your spelling or reset filters.';
    if (filter == 'expired') return 'Great job! None of your tracked items have passed their expiration date.';
    if (filter == 'expiring_soon') return 'None of your tracked items are expiring within your alert window.';
    return 'Tap the + button to add groceries, medicine or cosmetics.';
  }
}
