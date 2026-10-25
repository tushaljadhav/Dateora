import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/item.dart';
import '../models/status_evaluation.dart';
import '../providers/items_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/item_tile.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime? _selectedDate; // null means show ALL items for the current month

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
      _selectedDate = null; // Automatically shows all items of the new month
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
      _selectedDate = null; // Automatically shows all items of the new month
    });
  }

  void _resetToToday() {
    final now = DateTime.now();
    setState(() {
      _currentMonth = DateTime(now.year, now.month, 1);
      _selectedDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ItemsProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();
    final isCurrentMonth = _currentMonth.year == now.year && _currentMonth.month == now.month;

    // Normalize raw expiry dates (YYYY-MM-DD or ISO8601) to YYYY-MM-DD
    String normalizeDate(String raw) {
      try {
        final d = DateTime.parse(raw);
        return DateFormat('yyyy-MM-dd').format(d);
      } catch (_) {
        return raw.length >= 10 ? raw.substring(0, 10) : raw;
      }
    }

    // Map active items by normalized date string (YYYY-MM-DD)
    final Map<String, List<Item>> dateMap = {};
    for (final item in provider.activeItems) {
      final key = normalizeDate(item.expiryDate);
      dateMap.putIfAbsent(key, () => []).add(item);
    }

    // Filter active items belonging to _currentMonth, sorted by date
    final monthItems = provider.activeItems.where((item) {
      try {
        final d = DateTime.parse(item.expiryDate);
        return d.year == _currentMonth.year && d.month == _currentMonth.month;
      } catch (_) {
        return false;
      }
    }).toList()
      ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

    // Stats for the current month
    final expiredCount = monthItems
        .where((i) => i.evaluateStatus().status == ComputedItemStatus.expired)
        .length;
    final warningCount = monthItems
        .where((i) => i.evaluateStatus().status == ComputedItemStatus.expiringSoon)
        .length;
    final safeCount = monthItems.length - expiredCount - warningCount;

    // Determine items to display in the list below
    final List<Item> displayedItems;
    if (_selectedDate != null) {
      final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      displayedItems = (dateMap[selectedDateStr] ?? [])..sort((a, b) => a.name.compareTo(b.name));
    } else {
      displayedItems = monthItems;
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.screenHorizontal,
        title: Text(
          'Expiry Calendar',
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w800),
        ),
        actions: [
          if (!isCurrentMonth)
            TextButton.icon(
              icon: const Icon(Icons.today_rounded, size: 16),
              label: const Text('Today', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryStrong,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onPressed: _resetToToday,
            )
          else
            IconButton(
              icon: const Icon(Icons.today_rounded),
              tooltip: 'Current month',
              onPressed: _resetToToday,
            ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Unified Premium Calendar Container
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
                vertical: AppSpacing.xs,
              ),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
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
                  children: [
                    // Month navigation row
                    _buildMonthNavHeader(isDark),

                    const SizedBox(height: AppSpacing.sm),

                    // Symmetrical Weekdays row (7 equal columns)
                    _buildWeekdaysRow(isDark),

                    const SizedBox(height: 6),

                    // Calendar Monthly Grid
                    _buildMonthGrid(dateMap, isDark),
                  ],
                ),
              ),
            ),
          ),

          // Month Overview Metric Capsules
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
                vertical: 4,
              ),
              child: Row(
                children: [
                  _buildOverviewChip(
                    label: '${monthItems.length} Total',
                    color: AppColors.primaryStrong,
                    bgColor: AppColors.primaryStrong.withOpacity(0.12),
                  ),
                  if (warningCount > 0) ...[
                    const SizedBox(width: 6),
                    _buildOverviewChip(
                      label: '$warningCount Soon',
                      color: AppColors.statusWarning,
                      bgColor: AppColors.statusWarning.withOpacity(0.14),
                    ),
                  ],
                  if (expiredCount > 0) ...[
                    const SizedBox(width: 6),
                    _buildOverviewChip(
                      label: '$expiredCount Expired',
                      color: AppColors.statusDanger,
                      bgColor: AppColors.statusDanger.withOpacity(0.14),
                    ),
                  ],
                  if (safeCount > 0) ...[
                    const SizedBox(width: 6),
                    _buildOverviewChip(
                      label: '$safeCount Safe',
                      color: AppColors.statusSafe,
                      bgColor: AppColors.statusSafe.withOpacity(0.12),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 4),
          ),

          // Section Header for Items List
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Icon(
                    _selectedDate != null ? Icons.event_note_rounded : Icons.view_list_rounded,
                    size: 18,
                    color: AppColors.primaryStrong,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedDate != null
                          ? 'Expiring on ${DateFormat('EEE, dd MMM').format(_selectedDate!)}'
                          : 'Expiring in ${DateFormat('MMMM yyyy').format(_currentMonth)}',
                      style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w800),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_selectedDate != null) ...[
                    InkWell(
                      onTap: () => setState(() => _selectedDate = null),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryStrong.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: AppColors.primaryStrong.withOpacity(0.3),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.refresh_rounded, size: 12, color: AppColors.primaryStrong),
                            SizedBox(width: 4),
                            Text(
                              'Show Full Month',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryStrong,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${displayedItems.length} ${displayedItems.length == 1 ? "item" : "items"}',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryStrong,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // List of expiring items or Empty State
          if (displayedItems.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                                : [const Color(0xFFEFFDF5), Colors.white],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.verified_rounded,
                          size: 40,
                          color: AppColors.primaryStrong,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        _selectedDate != null
                            ? 'No products expiring on this day'
                            : 'No products expiring in ${DateFormat('MMMM yyyy').format(_currentMonth)}',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _selectedDate != null
                            ? 'Tap "Show Full Month" to view everything expiring in ${DateFormat('MMMM').format(_currentMonth)}'
                            : 'All your items are safe or tracked for other months.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption.copyWith(
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
                vertical: AppSpacing.xs,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, index) => ItemTile(item: displayedItems[index]),
                  childCount: displayedItems.length,
                ),
              ),
            ),

          // Bottom padding so last card is never hidden by navigation bar
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  // 1. Month Navigation Header inside the Card
  Widget _buildMonthNavHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryStrong.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                size: 20,
                color: AppColors.primaryStrong,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              DateFormat('MMMM yyyy').format(_currentMonth),
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : AppColors.primaryDark,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        Row(
          children: [
            InkWell(
              onTap: _prevMonth,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: const Icon(Icons.chevron_left_rounded, size: 20),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: _nextMonth,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: const Icon(Icons.chevron_right_rounded, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 2. Weekdays Header Row with perfect 7-column alignment
  Widget _buildWeekdaysRow(bool isDark) {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Row(
      children: days.asMap().entries.map((entry) {
        final idx = entry.key;
        final d = entry.value;
        final isWeekend = idx == 0 || idx == 6;

        return Expanded(
          child: Center(
            child: Text(
              d,
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isWeekend
                    ? AppColors.primaryStrong.withOpacity(0.85)
                    : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // 3. Monthly Grid with pill badges for item counts
  Widget _buildMonthGrid(Map<String, List<Item>> dateMap, bool isDark) {
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstWeekday = _currentMonth.weekday % 7; // Sunday = 0

    final totalCells = ((daysInMonth + firstWeekday + 6) ~/ 7) * 7;
    final now = DateTime.now();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalCells,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 5,
        crossAxisSpacing: 5,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, index) {
        if (index < firstWeekday || index >= firstWeekday + daysInMonth) {
          return const SizedBox.shrink();
        }

        final dayNum = index - firstWeekday + 1;
        final cellDate = DateTime(_currentMonth.year, _currentMonth.month, dayNum);
        final dateStr = DateFormat('yyyy-MM-dd').format(cellDate);

        final isSelected = _selectedDate != null &&
            _selectedDate!.year == cellDate.year &&
            _selectedDate!.month == cellDate.month &&
            _selectedDate!.day == cellDate.day;

        final isToday = now.year == cellDate.year &&
            now.month == cellDate.month &&
            now.day == cellDate.day;

        final itemsForDay = dateMap[dateStr] ?? [];

        // Determine dominant status color
        Color? statusColor;
        if (itemsForDay.isNotEmpty) {
          final hasExpired = itemsForDay.any((i) => i.evaluateStatus().status == ComputedItemStatus.expired);
          final hasWarning = itemsForDay.any((i) => i.evaluateStatus().status == ComputedItemStatus.expiringSoon);

          if (hasExpired) {
            statusColor = AppColors.statusDanger;
          } else if (hasWarning) {
            statusColor = AppColors.statusWarning;
          } else {
            statusColor = AppColors.statusSafe;
          }
        }

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              if (_selectedDate != null &&
                  _selectedDate!.year == cellDate.year &&
                  _selectedDate!.month == cellDate.month &&
                  _selectedDate!.day == cellDate.day) {
                _selectedDate = null; // Toggle back to all items in month
              } else {
                _selectedDate = cellDate;
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected
                  ? null
                  : (itemsForDay.isNotEmpty
                      ? (statusColor?.withOpacity(isDark ? 0.2 : 0.12) ?? Colors.transparent)
                      : (isToday
                          ? AppColors.primaryStrong.withOpacity(0.08)
                          : Colors.transparent)),
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? null
                  : (isToday
                      ? Border.all(color: AppColors.primaryStrong, width: 1.5)
                      : (itemsForDay.isNotEmpty
                          ? Border.all(color: (statusColor ?? AppColors.primary).withOpacity(0.4), width: 1)
                          : null)),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$dayNum',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected || isToday || itemsForDay.isNotEmpty
                        ? FontWeight.w900
                        : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isToday
                            ? AppColors.primaryStrong
                            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                  ),
                ),
                if (itemsForDay.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  if (itemsForDay.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : statusColor,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        '${itemsForDay.length}',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? AppColors.primaryStrong : Colors.white,
                          height: 1.1,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewChip({
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
