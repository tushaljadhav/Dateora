import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';

/// Shows a custom, modern, luxury Dateora date picker dialog
Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  return showDialog<DateTime>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => AppDatePickerDialog(
      initialDate: initialDate,
      firstDate: firstDate ?? DateTime.now().subtract(const Duration(days: 365)),
      lastDate: lastDate ?? DateTime.now().add(const Duration(days: 3650)),
    ),
  );
}

class AppDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const AppDatePickerDialog({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<AppDatePickerDialog> createState() => _AppDatePickerDialogState();
}

class _AppDatePickerDialogState extends State<AppDatePickerDialog> {
  late DateTime _selectedDate;
  late DateTime _displayMonth;
  bool _isSelectingYear = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _displayMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
  }

  void _prevMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    final dateFormatted = DateFormat('dd MMMM yyyy').format(_selectedDate);
    final dayOfWeek = DateFormat('EEEE').format(_selectedDate);
    final daysLeft = _selectedDate.difference(DateTime(now.year, now.month, now.day)).inDays;

    final Color badgeColor;
    final String countdownText;
    if (daysLeft < 0) {
      badgeColor = AppColors.statusDanger;
      countdownText = 'Expired ${-daysLeft}d ago';
    } else if (daysLeft == 0) {
      badgeColor = AppColors.statusDanger;
      countdownText = 'Expires today';
    } else if (daysLeft <= 3) {
      badgeColor = AppColors.statusWarning;
      countdownText = '$daysLeft days left';
    } else {
      badgeColor = AppColors.statusSafe;
      countdownText = '$daysLeft days left';
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF132E27), const Color(0xFF0F172A)]
                  : [const Color(0xFFEFFDF5), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primary.withOpacity(isDark ? 0.35 : 0.25),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.12),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Top Header Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.primaryStrong.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.edit_calendar_rounded,
                        color: AppColors.primaryStrong,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Select Expiry Date',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.black.withOpacity(0.04),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Selected Date Preview Banner (High-contrast emerald capsule)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(isDark ? 0.3 : 0.25),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dateFormatted,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : AppColors.primaryDark,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Text(
                                  dayOfWeek,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '•',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withOpacity(0.14),
                                    borderRadius: BorderRadius.circular(AppRadius.pill),
                                  ),
                                  child: Text(
                                    countdownText,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: badgeColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 3. Month & Year Controls + Year Switcher Toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => setState(() => _isSelectingYear = !_isSelectingYear),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _isSelectingYear
                              ? AppColors.primaryStrong.withOpacity(0.16)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: _isSelectingYear
                                ? AppColors.primaryStrong
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat('MMMM yyyy').format(_displayMonth),
                              style: AppTextStyles.titleSmall.copyWith(
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : AppColors.primaryDark,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _isSelectingYear
                                  ? Icons.arrow_drop_up_rounded
                                  : Icons.arrow_drop_down_rounded,
                              size: 20,
                              color: AppColors.primaryStrong,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!_isSelectingYear)
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
                ),
              ),

              const SizedBox(height: 8),

              // 4. Body: Either Year Grid or Month Calendar Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _isSelectingYear
                    ? _buildYearPicker(isDark)
                    : Column(
                        children: [
                          _buildWeekdaysRow(isDark),
                          const SizedBox(height: 6),
                          _buildCalendarDaysGrid(isDark, now),
                        ],
                      ),
              ),

              const SizedBox(height: 16),

              // 5. Bottom Action Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: BorderSide(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.button),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
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
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.button),
                            ),
                          ),
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text(
                            'Confirm Date',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                          ),
                          onPressed: () => Navigator.pop(context, _selectedDate),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Weekdays Row (Symmetrical 7 columns)
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

  // Calendar Days Grid
  Widget _buildCalendarDaysGrid(bool isDark, DateTime now) {
    final daysInMonth = DateTime(_displayMonth.year, _displayMonth.month + 1, 0).day;
    final firstWeekday = _displayMonth.weekday % 7; // Sunday = 0
    final totalCells = ((daysInMonth + firstWeekday + 6) ~/ 7) * 7;

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
        final cellDate = DateTime(_displayMonth.year, _displayMonth.month, dayNum);

        final isSelected = _selectedDate.year == cellDate.year &&
            _selectedDate.month == cellDate.month &&
            _selectedDate.day == cellDate.day;

        final isToday = now.year == cellDate.year &&
            now.month == cellDate.month &&
            now.day == cellDate.day;

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _selectedDate = cellDate;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
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
                  : (isToday
                      ? AppColors.primaryStrong.withOpacity(0.1)
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? null
                  : (isToday
                      ? Border.all(color: AppColors.primaryStrong, width: 1.4)
                      : null),
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
            child: Center(
              child: Text(
                '$dayNum',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected || isToday ? FontWeight.w900 : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (isToday
                          ? AppColors.primaryStrong
                          : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Quick Year Picker Grid (Allows jumping to future years instantly)
  Widget _buildYearPicker(bool isDark) {
    final currentYear = DateTime.now().year;
    final years = List.generate(12, (index) => currentYear - 1 + index);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: years.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.1,
      ),
      itemBuilder: (context, index) {
        final yr = years[index];
        final isSelectedYear = _displayMonth.year == yr;

        return InkWell(
          borderRadius: BorderRadius.circular(AppRadius.button),
          onTap: () {
            setState(() {
              _displayMonth = DateTime(yr, _displayMonth.month, 1);
              _isSelectingYear = false;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              gradient: isSelectedYear
                  ? const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelectedYear
                  ? null
                  : (isDark ? AppColors.darkSurface : AppColors.lightBg),
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(
                color: isSelectedYear
                    ? Colors.transparent
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
            ),
            child: Center(
              child: Text(
                '$yr',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelectedYear ? FontWeight.w900 : FontWeight.w600,
                  color: isSelectedYear
                      ? Colors.white
                      : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
