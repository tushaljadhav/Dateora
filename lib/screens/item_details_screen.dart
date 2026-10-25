import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../models/item.dart';
import '../models/status_evaluation.dart';
import '../providers/items_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_card.dart';
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 64, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Item not found or has been removed.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final status = item.evaluateStatus();
    final cat = CategoryModel.getById(item.category);
    final isAssetPhoto = item.photoUri != null && item.photoUri!.startsWith('assets/');
    final hasFilePhoto = item.photoUri != null && !isAssetPhoto && File(item.photoUri!).existsSync();
    final hasPhoto = isAssetPhoto || hasFilePhoto;

    // Format expiry date cleanly
    DateTime? parsedExpiry;
    try {
      parsedExpiry = DateTime.parse(item.expiryDate);
    } catch (_) {}
    final formattedExpiry = parsedExpiry != null
        ? DateFormat('dd MMM yyyy (EEEE)').format(parsedExpiry)
        : item.expiryDate;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Product Details',
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
          // 1. Hero Card (Photo or Emerald Gradient Hero)
          _buildHeroCard(context, item, cat, status, hasPhoto, isDark),

          const SizedBox(height: AppSpacing.md),

          // 2. Expiry & Countdown Metric Capsules
          _buildExpiryMetricBlock(context, item, status, formattedExpiry, isDark),

          const SizedBox(height: AppSpacing.md),

          // 3. Specifications & Metadata Card
          _buildSpecsCard(context, item, cat, isDark),

          const SizedBox(height: AppSpacing.xl),

          // 4. Action Buttons
          if (item.isActive) ...[
            Text(
              'Mark Item Outcome',
              style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle_rounded, size: 20),
                      label: const Text(
                        'Mark as Used',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      onPressed: () => _markStatus(context, item!, 'used'),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: AppColors.statusDanger.withOpacity(0.6),
                        width: 1.2,
                      ),
                      backgroundColor: isDark
                          ? AppColors.statusDanger.withOpacity(0.12)
                          : AppColors.statusDangerBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.statusDanger),
                    label: const Text(
                      'Disposed',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.statusDanger,
                        fontSize: 14,
                      ),
                    ),
                    onPressed: () => _markStatus(context, item!, 'disposed'),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.button),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                icon: const Icon(Icons.restore_rounded, size: 20),
                label: const Text(
                  'Restore to Active Tracking',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                onPressed: () => _restoreItem(context, item!),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  // 1. Hero Card
  Widget _buildHeroCard(
    BuildContext context,
    Item item,
    CategoryModel cat,
    StatusEvaluation status,
    bool hasPhoto,
    bool isDark,
  ) {
    if (hasPhoto) {
      final isAsset = item.photoUri != null && item.photoUri!.startsWith('assets/');
      return Container(
        height: 240,
        decoration: BoxDecoration(
          borderRadius: AppRadius.cardRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: AppRadius.cardRadius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: 'item_photo_${item.id}',
                child: isAsset
                    ? Image.asset(
                        item.photoUri!,
                        fit: BoxFit.cover,
                      )
                    : Image.file(
                        File(item.photoUri!),
                        fit: BoxFit.cover,
                      ),
              ),
              // Top & bottom gradient scrims
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black45,
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black87,
                    ],
                    stops: [0.0, 0.25, 0.55, 1.0],
                  ),
                ),
              ),
              // Top pills: Category badge + Status pill
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: Colors.white24, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat.icon, size: 14, color: Colors.white),
                          const SizedBox(width: 5),
                          Text(
                            cat.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    StatusPill(evaluation: status),
                  ],
                ),
              ),
              // Bottom: Item Name
              Positioned(
                left: 16,
                right: 16,
                bottom: 14,
                child: Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(
                        color: Colors.black87,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // No Photo: Bachat Gradient Hero
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF132E27), const Color(0xFF0F172A)]
              : [const Color(0xFFEFFDF5), Colors.white],
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cat.color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: cat.color.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(cat.icon, size: 14, color: cat.color),
                    const SizedBox(width: 5),
                    Text(
                      cat.name,
                      style: TextStyle(
                        color: cat.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              StatusPill(evaluation: status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: cat.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cat.color.withOpacity(0.3), width: 1.2),
                ),
                child: Center(
                  child: Icon(cat.icon, size: 30, color: cat.color),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  item.name,
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. Expiry & Countdown Metric Block
  Widget _buildExpiryMetricBlock(
    BuildContext context,
    Item item,
    StatusEvaluation status,
    String formattedExpiry,
    bool isDark,
  ) {
    DateTime? parsed;
    try {
      parsed = DateTime.parse(item.expiryDate);
    } catch (_) {}
    final cleanDateStr = parsed != null ? DateFormat('dd MMM yyyy').format(parsed) : item.expiryDate;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Left: Expiry Date Box
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.primarySoft.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.event_available_rounded, size: 15, color: AppColors.primaryStrong),
                          const SizedBox(width: 5),
                          Text(
                            'Expiry Date',
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cleanDateStr,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Right: Countdown Box
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: status.color.withOpacity(isDark ? 0.16 : 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: status.color.withOpacity(0.35),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.hourglass_top_rounded, size: 15, color: status.color),
                          const SizedBox(width: 5),
                          Text(
                            'Remaining',
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: status.color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        status.relativeText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: status.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Day description subtitle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface.withOpacity(0.6) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    formattedExpiry,
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. Specifications & Metadata Card (Title on top-left, details underneath)
  Widget _buildSpecsCard(
    BuildContext context,
    Item item,
    CategoryModel cat,
    bool isDark,
  ) {
    final hasPrice = item.price != null;
    final hasQuantity = item.quantity != null;
    final hasLocation = item.location != null && item.location!.isNotEmpty;
    final hasReminders = item.reminderOffsets.isNotEmpty;
    final hasNotes = item.notes != null && item.notes!.isNotEmpty;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primaryStrong),
              const SizedBox(width: 6),
              Text(
                'Product Details',
                style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Price & Quantity in a balanced Row if both exist
          if (hasPrice && hasQuantity) ...[
            Row(
              children: [
                Expanded(
                  child: _buildMiniSpecBlock(
                    isDark: isDark,
                    icon: Icons.currency_rupee_rounded,
                    iconColor: AppColors.statusSafe,
                    iconBgColor: AppColors.statusSafe.withOpacity(0.14),
                    title: 'Price / Value',
                    content: Text(
                      '₹${item.price! % 1 == 0 ? item.price!.toInt() : item.price!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.statusSafe,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMiniSpecBlock(
                    isDark: isDark,
                    icon: Icons.inventory_2_outlined,
                    iconColor: const Color(0xFF3B82F6),
                    iconBgColor: const Color(0xFF3B82F6).withOpacity(0.14),
                    title: 'Quantity',
                    content: Text(
                      '${item.quantity} ${item.unit ?? ''}'.trim(),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            if (hasPrice)
              _buildFullWidthSpecBlock(
                isDark: isDark,
                icon: Icons.currency_rupee_rounded,
                iconColor: AppColors.statusSafe,
                iconBgColor: AppColors.statusSafe.withOpacity(0.14),
                title: 'Price / Value',
                content: Text(
                  '₹${item.price! % 1 == 0 ? item.price!.toInt() : item.price!.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.statusSafe,
                  ),
                ),
              ),
            if (hasQuantity)
              _buildFullWidthSpecBlock(
                isDark: isDark,
                icon: Icons.inventory_2_outlined,
                iconColor: const Color(0xFF3B82F6),
                iconBgColor: const Color(0xFF3B82F6).withOpacity(0.14),
                title: 'Quantity',
                content: Text(
                  '${item.quantity} ${item.unit ?? ''}'.trim(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  ),
                ),
              ),
          ],

          // Storage Location: Title on top-left, full details underneath!
          if (hasLocation)
            _buildFullWidthSpecBlock(
              isDark: isDark,
              icon: Icons.place_outlined,
              iconColor: const Color(0xFFF59E0B),
              iconBgColor: const Color(0xFFF59E0B).withOpacity(0.14),
              title: 'Storage Location',
              content: Text(
                item.location!,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                ),
              ),
            ),

          // Alert Schedule: Title on top-left, pills underneath!
          if (hasReminders)
            _buildFullWidthSpecBlock(
              isDark: isDark,
              icon: Icons.notifications_active_outlined,
              iconColor: const Color(0xFF8B5CF6),
              iconBgColor: const Color(0xFF8B5CF6).withOpacity(0.14),
              title: 'Alert Schedule',
              content: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: item.reminderOffsets.map((offset) {
                  final text = offset == 0 ? 'On expiry day' : '$offset days before';
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: const Color(0xFF8B5CF6).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.alarm_rounded, size: 13, color: Color(0xFF8B5CF6)),
                        const SizedBox(width: 4),
                        Text(
                          text,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF8B5CF6),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

          // Notes Section: Title on top-left, full readable text underneath!
          if (hasNotes)
            _buildFullWidthSpecBlock(
              isDark: isDark,
              icon: Icons.notes_outlined,
              iconColor: AppColors.primaryStrong,
              iconBgColor: AppColors.primaryStrong.withOpacity(0.14),
              title: 'Notes',
              content: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  item.notes!,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : const Color(0xFF334155),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Full-width spec block: Icon & Title on top-left, details underneath
  Widget _buildFullWidthSpecBlock({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required Widget content,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: iconColor),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }

  // Compact mini spec block for 2-column items (Price / Quantity)
  Widget _buildMiniSpecBlock({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required Widget content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          content,
        ],
      ),
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
