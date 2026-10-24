import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../models/item.dart';
import '../providers/items_provider.dart';
import '../services/analytics_service.dart';
import '../services/savings_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_card.dart';

class BachatScreen extends StatefulWidget {
  const BachatScreen({super.key});

  @override
  State<BachatScreen> createState() => _BachatScreenState();
}

class _BachatScreenState extends State<BachatScreen> {
  final GlobalKey _shareCardKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _shareSavingsImage(MonthlySavings currentMonth, AppLocalizations l10n) async {
    setState(() => _isSharing = true);
    try {
      final boundary = _shareCardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/dateora_savings_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      final amountStr = currentMonth.savedAmount.toStringAsFixed(0);
      final shareText = l10n.bachatShareText(amountStr);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: shareText,
      );

      AnalyticsService.instance.logShareTapped(type: 'savings');
    } catch (e) {
      debugPrint('Share savings error: $e');
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final itemsProvider = context.watch<ItemsProvider>();

    // Combine active and history items to calculate complete savings history
    final allItems = <Item>[...itemsProvider.activeItems, ...itemsProvider.historyItems];
    final last6Months = SavingsService.calculateLastNMonths(allItems, monthCount: 6);
    final currentMonth = last6Months.first;
    final currentLocale = Localizations.localeOf(context).toString();
    final monthFormat = DateFormat.MMMM(currentLocale);
    final currentMonthName = monthFormat.format(DateTime(currentMonth.year, currentMonth.month));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.bachatScreenTitle,
          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
          vertical: AppSpacing.md,
        ),
        children: [
          // 1. Honest disclaimer card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primarySoft.withOpacity(isDark ? 0.2 : 0.6),
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.primaryStrong, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.bachatEstimatedNotice,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 2. Beautiful Shareable Bachat Card (Inside RepaintBoundary)
          RepaintBoundary(
            key: _shareCardKey,
            child: Container(
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
                  color: AppColors.primary.withOpacity(isDark ? 0.4 : 0.25),
                  width: 1.5,
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
                            child: const Icon(Icons.savings_rounded, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.appName,
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryStrong,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$currentMonthName ${currentMonth.year}',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryStrong,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Large Saved Number
                  Text(
                    l10n.homeBachatSaved,
                    style: AppTextStyles.caption.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${currentMonth.savedAmount.toStringAsFixed(0)}',
                    style: AppTextStyles.display.copyWith(
                      color: AppColors.statusSafe,
                      fontWeight: FontWeight.w900,
                      fontSize: 34,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Two column stats: Wasted & Items Used
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.bachatTotalWasted,
                              style: AppTextStyles.caption.copyWith(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹${currentMonth.wastedAmount.toStringAsFixed(0)}',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: currentMonth.wastedAmount > 0
                                    ? AppColors.statusDanger
                                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.bachatItemsUsed,
                              style: AppTextStyles.caption.copyWith(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${currentMonth.usedCount}',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: AppColors.primaryStrong,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Text(
                    l10n.bachatCardTagline,
                    style: AppTextStyles.caption.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 3. Share Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSharing ? null : () => _shareSavingsImage(currentMonth, l10n),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryStrong,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
              icon: _isSharing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.share_rounded, size: 20),
              label: Text(
                l10n.bachatShareButton,
                style: AppTextStyles.button.copyWith(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // 4. Last 6 Months Breakdown (Simple bar list, no heavy chart library)
          Text(
            l10n.bachatMonthlyHistory,
            style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.md),

          ...last6Months.map((m) {
            final monthName = monthFormat.format(DateTime(m.year, m.month));
            final totalMoney = m.savedAmount + m.wastedAmount;
            final double savedFraction = totalMoney > 0 ? (m.savedAmount / totalMoney) : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$monthName ${m.year}',
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '${m.usedCount} ${l10n.homeBachatUsedItems}',
                        style: AppTextStyles.caption.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Saved vs Wasted Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: 8,
                      width: double.infinity,
                      color: isDark ? Colors.white12 : Colors.black12,
                      child: Row(
                        children: [
                          if (savedFraction > 0)
                            Expanded(
                              flex: (savedFraction * 100).toInt(),
                              child: Container(color: AppColors.statusSafe),
                            ),
                          if (totalMoney > 0 && savedFraction < 1.0)
                            Expanded(
                              flex: ((1.0 - savedFraction) * 100).toInt(),
                              child: Container(color: AppColors.statusDanger),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Money summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.statusSafe,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${l10n.homeBachatSaved}: ₹${m.savedAmount.toStringAsFixed(0)}',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.statusSafe,
                            ),
                          ),
                        ],
                      ),
                      if (m.wastedAmount > 0)
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.statusDanger,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${l10n.homeBachatWasted}: ₹${m.wastedAmount.toStringAsFixed(0)}',
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.statusDanger,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
        ],
      ),
    );
  }
}
