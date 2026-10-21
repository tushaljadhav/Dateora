import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';

class CategoryChip extends StatelessWidget {
  final CategoryModel category;
  final bool isSelected;
  final ValueChanged<bool>? onSelected;

  const CategoryChip({
    super.key,
    required this.category,
    required this.isSelected,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isSelected
        ? (isDark ? AppColors.darkCard : AppColors.primarySoft)
        : (isDark ? AppColors.darkSurface : Colors.white);

    final borderColor = isSelected
        ? AppColors.primaryStrong
        : theme.colorScheme.outline;

    final textColor = isSelected
        ? (isDark ? AppColors.primary : AppColors.textOnPrimary)
        : theme.colorScheme.onSurface;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onSelected != null ? () => onSelected!(!isSelected) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: borderColor, width: isSelected ? 1.6 : 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              category.icon,
              size: 16,
              color: isSelected ? AppColors.primaryStrong : category.color,
            ),
            const SizedBox(width: 6),
            Text(
              category.name,
              style: AppTextStyles.caption.copyWith(
                color: textColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
