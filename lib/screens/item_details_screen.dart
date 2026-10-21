import 'dart:io';
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
import '../widgets/primary_button.dart';
import '../widgets/status_pill.dart';
import 'edit_item_screen.dart';

class ItemDetailsScreen extends StatelessWidget {
  final String itemId;

  const ItemDetailsScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ItemsProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Search in active or history items
    Item? item;
    try {
      item = provider.activeItems.firstWhere((i) => i.id == itemId);
    } catch (_) {
      try {
        item = provider.historyItems.firstWhere((i) => i.id == itemId);
      } catch (_) {
        item = null;
      }
    }

    if (item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Item Details')),
        body: Center(
          child: Text(
            'Item not found or has been removed.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.lightTextMuted),
          ),
        ),
      );
    }

    final status = item.evaluateStatus();
    final cat = CategoryModel.getById(item.category);
    final hasPhoto = item.photoUri != null && File(item.photoUri!).existsSync();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Item Details',
          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit item',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditItemScreen(item: item!),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.statusDanger),
            tooltip: 'Delete item',
            onPressed: () => _confirmDelete(context, item!),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
          vertical: AppSpacing.md,
        ),
        children: [
          // Hero Photo / Visual Card
          if (hasPhoto)
            AppCard(
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: Hero(
                  tag: 'item_photo_${item.id}',
                  child: Image.file(
                    File(item.photoUri!),
                    height: 240,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            )
          else
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: Hero(
                  tag: 'item_photo_${item.id}',
                  child: CategoryBadge(categoryId: item.category, size: 84),
                ),
              ),
            ),

          const SizedBox(height: AppSpacing.md),

          // Header Info Card: Name, Category, Status Pill
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: AppTextStyles.titleLarge.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(cat.icon, size: 16, color: cat.color),
                              const SizedBox(width: 6),
                              Text(
                                cat.name,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    StatusPill(evaluation: status),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Expiry & Countdown Card
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                _buildInfoRow(
                  context,
                  icon: Icons.calendar_month_outlined,
                  iconColor: AppColors.primaryStrong,
                  label: 'Expiry Date',
                  value: item.expiryDate,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Divider(
                    height: 1,
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                _buildInfoRow(
                  context,
                  icon: Icons.timer_outlined,
                  iconColor: status.color,
                  label: 'Countdown',
                  value: status.relativeText,
                  valueColor: status.color,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Additional Metadata Card (Quantity, Storage, Reminders, Notes)
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                if (item.quantity != null) ...[
                  _buildInfoRow(
                    context,
                    icon: Icons.inventory_2_outlined,
                    iconColor: AppColors.primaryStrong,
                    label: 'Quantity',
                    value: '${item.quantity} ${item.unit ?? ''}'.trim(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Divider(
                      height: 1,
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                ],
                if (item.location != null && item.location!.isNotEmpty) ...[
                  _buildInfoRow(
                    context,
                    icon: Icons.place_outlined,
                    iconColor: AppColors.primaryStrong,
                    label: 'Storage Location',
                    value: item.location!,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Divider(
                      height: 1,
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                ],
                _buildInfoRow(
                  context,
                  icon: Icons.notifications_active_outlined,
                  iconColor: AppColors.primaryStrong,
                  label: 'Alert Schedule',
                  value: item.reminderOffsets
                      .map((o) => o == 0 ? 'On expiry' : '$o days before')
                      .join(', '),
                ),
                if (item.notes != null && item.notes!.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Divider(
                      height: 1,
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  _buildInfoRow(
                    context,
                    icon: Icons.notes_outlined,
                    iconColor: AppColors.primaryStrong,
                    label: 'Notes',
                    value: item.notes!,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Mark Outcome Actions
          if (item.isActive) ...[
            Text(
              'Mark Item Outcome',
              style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _buildActionPill(
                    context,
                    label: 'Used',
                    icon: Icons.check_circle_outline,
                    onTap: () => _markStatus(context, item!, 'used'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildActionPill(
                    context,
                    label: 'Disposed',
                    icon: Icons.delete_sweep_outlined,
                    isDestructive: true,
                    onTap: () => _markStatus(context, item!, 'disposed'),
                  ),
                ),
              ],
            ),
          ] else ...[
            PrimaryButton(
              text: 'Restore to Active Tracking',
              icon: Icons.restore_rounded,
              onPressed: () => _restoreItem(context, item!),
            ),
          ],

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: valueColor ??
                  (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionPill(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return OutlinedButton.icon(
      icon: Icon(
        icon,
        size: 16,
        color: isDestructive
            ? AppColors.statusDanger
            : (isDark ? AppColors.primary : AppColors.primaryStrong),
      ),
      label: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w700,
          color: isDestructive
              ? AppColors.statusDanger
              : (isDark ? AppColors.primary : AppColors.primaryDark),
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(
          color: isDestructive
              ? AppColors.statusDanger.withOpacity(0.5)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
      ),
      onPressed: onTap,
    );
  }

  void _confirmDelete(BuildContext context, Item item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusDanger,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = Provider.of<ItemsProvider>(context, listen: false);
              await provider.deleteItem(item);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Deleted "${item.name}"')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _markStatus(BuildContext context, Item item, String status) async {
    final provider = Provider.of<ItemsProvider>(context, listen: false);
    await provider.markItemStatus(item, status);
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primaryStrong,
          content: Text('Marked "${item.name}" as $status'),
        ),
      );
    }
  }

  void _restoreItem(BuildContext context, Item item) async {
    final provider = Provider.of<ItemsProvider>(context, listen: false);
    await provider.restoreItem(item);
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primaryStrong,
          content: Text('Restored "${item.name}" to active list'),
        ),
      );
    }
  }
}
