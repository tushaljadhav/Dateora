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
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ItemsProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Map active items by date string (YYYY-MM-DD)
    final Map<String, List<Item>> dateMap = {};
    for (final item in provider.activeItems) {
      dateMap.putIfAbsent(item.expiryDate, () => []).add(item);
    }

    final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final selectedItems = dateMap[selectedDateStr] ?? [];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.screenHorizontal,
        title: Text(
          'Calendar View',
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          // Month navigation bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 28),
                  tooltip: 'Previous month',
                  onPressed: _prevMonth,
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_currentMonth),
                  style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, size: 28),
                  tooltip: 'Next month',
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),

          // Days of the week header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                  .map((d) => SizedBox(
                        width: 42,
                        child: Text(
                          d,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          // Calendar Monthly Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
            child: _buildMonthGrid(dateMap),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Divider(
              height: 1,
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),

          // Selected day header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                Text(
                  DateFormat('EEEE, dd MMM').format(_selectedDate),
                  style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '${selectedItems.length} items',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryStrong,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Items expiring on selected day
          Expanded(
            child: selectedItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : AppColors.primarySoft.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.event_available_rounded,
                            size: 36,
                            color: AppColors.primaryStrong,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'No items expiring on this day',
                          style: AppTextStyles.titleSmall.copyWith(
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenHorizontal,
                      vertical: AppSpacing.xs,
                    ),
                    itemCount: selectedItems.length,
                    itemBuilder: (ctx, index) => ItemTile(item: selectedItems[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthGrid(Map<String, List<Item>> dateMap) {
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstWeekday = _currentMonth.weekday % 7; // Sunday = 0

    final totalCells = ((daysInMonth + firstWeekday + 6) ~/ 7) * 7;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalCells,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (context, index) {
        if (index < firstWeekday || index >= firstWeekday + daysInMonth) {
          return const SizedBox.shrink();
        }

        final dayNum = index - firstWeekday + 1;
        final cellDate = DateTime(_currentMonth.year, _currentMonth.month, dayNum);
        final dateStr = DateFormat('yyyy-MM-dd').format(cellDate);

        final isSelected = _selectedDate.year == cellDate.year &&
            _selectedDate.month == cellDate.month &&
            _selectedDate.day == cellDate.day;

        final itemsForDay = dateMap[dateStr] ?? [];

        // Determine status dot color
        Color? dotColor;
        if (itemsForDay.isNotEmpty) {
          final hasExpired = itemsForDay.any((i) => i.evaluateStatus().status == ComputedItemStatus.expired);
          final hasWarning = itemsForDay.any((i) => i.evaluateStatus().status == ComputedItemStatus.expiringSoon);

          if (hasExpired) {
            dotColor = AppColors.statusDanger;
          } else if (hasWarning) {
            dotColor = AppColors.statusWarning;
          } else {
            dotColor = AppColors.statusSafe;
          }
        }

        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _selectedDate = cellDate),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? null
                  : Border.all(color: Colors.transparent),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$dayNum',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.textOnPrimary
                        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                  ),
                ),
                if (dotColor != null) ...[
                  const SizedBox(height: 3),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.textOnPrimary : dotColor,
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
}
