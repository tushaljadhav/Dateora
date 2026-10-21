import 'package:flutter/material.dart';
import '../models/status_evaluation.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';

class StatusPill extends StatelessWidget {
  final StatusEvaluation evaluation;
  final bool compact;

  const StatusPill({
    super.key,
    required this.evaluation,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: evaluation.badgeBg,
        borderRadius: AppRadius.pillRadius,
        border: Border.all(color: evaluation.borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            evaluation.icon,
            size: compact ? 12 : 14,
            color: evaluation.textColor,
          ),
          const SizedBox(width: 4),
          Text(
            evaluation.label,
            style: AppTextStyles.caption.copyWith(
              color: evaluation.textColor,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
