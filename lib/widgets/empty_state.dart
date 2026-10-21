import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'primary_button.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String? imageAsset;
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const EmptyState({
    super.key,
    required this.icon,
    this.imageAsset,
    required this.title,
    required this.message,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.xxl,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imageAsset != null)
              Container(
                height: 120,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Image.asset(
                  imageAsset!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => _buildIconCircle(isDark),
                ),
              )
            else
              _buildIconCircle(isDark),

            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.65),
              ),
              textAlign: TextAlign.center,
            ),
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                text: buttonText!,
                onPressed: onButtonPressed,
                icon: Icons.add_rounded,
                width: 220,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIconCircle(bool isDark) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.primarySoft,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.primary.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 38,
          color: AppColors.primaryStrong,
        ),
      ),
    );
  }
}
