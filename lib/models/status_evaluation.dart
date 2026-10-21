import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum ComputedItemStatus {
  expired,
  expiringSoon,
  safe,
}

class StatusEvaluation {
  final ComputedItemStatus status;
  final String label;
  final int daysLeft;
  final String relativeText;
  final Color badgeBg;
  final Color textColor;
  final Color borderColor;
  final IconData icon;

  const StatusEvaluation({
    required this.status,
    required this.label,
    required this.daysLeft,
    required this.relativeText,
    required this.badgeBg,
    required this.textColor,
    required this.borderColor,
    required this.icon,
  });

  Color get color => textColor;

  static DateTime normalizeToStartOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime parseDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      }
      return DateTime.parse(dateStr);
    } catch (_) {
      return DateTime.now();
    }
  }

  static int getDaysUntilExpiry(String expiryDateStr, [DateTime? refDate]) {
    final target = normalizeToStartOfDay(parseDate(expiryDateStr));
    final now = normalizeToStartOfDay(refDate ?? DateTime.now());
    return target.difference(now).inDays;
  }

  static StatusEvaluation evaluate(String expiryDateStr, {int windowDays = 7, DateTime? refDate}) {
    final daysLeft = getDaysUntilExpiry(expiryDateStr, refDate);

    if (daysLeft < 0) {
      final absDays = daysLeft.abs();
      return StatusEvaluation(
        status: ComputedItemStatus.expired,
        label: 'Expired',
        daysLeft: daysLeft,
        relativeText: absDays == 1 ? 'Expired yesterday' : 'Expired $absDays days ago',
        badgeBg: AppColors.statusDangerBg,
        textColor: AppColors.statusDanger,
        borderColor: AppColors.statusDanger.withOpacity(0.3),
        icon: Icons.error_outline,
      );
    }

    if (daysLeft == 0) {
      return StatusEvaluation(
        status: ComputedItemStatus.expiringSoon,
        label: 'Expires Today',
        daysLeft: 0,
        relativeText: 'Expires today',
        badgeBg: AppColors.statusWarningBg,
        textColor: AppColors.statusWarning,
        borderColor: AppColors.statusWarning.withOpacity(0.35),
        icon: Icons.access_time,
      );
    }

    if (daysLeft == 1) {
      return StatusEvaluation(
        status: ComputedItemStatus.expiringSoon,
        label: 'Expires Tomorrow',
        daysLeft: 1,
        relativeText: 'Expires tomorrow',
        badgeBg: AppColors.statusWarningBg,
        textColor: AppColors.statusWarning,
        borderColor: AppColors.statusWarning.withOpacity(0.35),
        icon: Icons.access_time,
      );
    }

    if (daysLeft <= windowDays) {
      return StatusEvaluation(
        status: ComputedItemStatus.expiringSoon,
        label: 'In $daysLeft days',
        daysLeft: daysLeft,
        relativeText: 'Expires in $daysLeft days',
        badgeBg: AppColors.statusWarningBg,
        textColor: AppColors.statusWarning,
        borderColor: AppColors.statusWarning.withOpacity(0.35),
        icon: Icons.access_time,
      );
    }

    // Safe (Teal-green tone, distinct from brand green)
    return StatusEvaluation(
      status: ComputedItemStatus.safe,
      label: 'Safe',
      daysLeft: daysLeft,
      relativeText: 'Expires in $daysLeft days',
      badgeBg: AppColors.statusSafeBg,
      textColor: AppColors.statusSafe,
      borderColor: AppColors.statusSafe.withOpacity(0.35),
      icon: Icons.check_circle_outline,
    );
  }
}
