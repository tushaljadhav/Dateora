import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/photo_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class PhotoPickerSheet extends StatelessWidget {
  final String? currentPhotoPath;

  const PhotoPickerSheet({
    super.key,
    this.currentPhotoPath,
  });

  /// Displays the modal sheet and returns the captured/selected photo path, or null.
  static Future<String?> show(
    BuildContext context, {
    String? currentPhotoPath,
  }) {
    return showModalBottomSheet<String?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => PhotoPickerSheet(
        currentPhotoPath: currentPhotoPath,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.modal)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Attach Product Photo',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Photos stay strictly offline on your device',
              style: AppTextStyles.caption.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Camera Option
            _buildOption(
              context,
              icon: Icons.camera_alt_outlined,
              title: 'Take Photo',
              subtitle: 'Open camera to capture product & expiry',
              onTap: () async {
                final navigator = Navigator.of(context);
                final path = await PhotoService.captureOrPickPhoto(
                  context: context,
                  source: ImageSource.camera,
                  currentPhotoPath: currentPhotoPath,
                );
                navigator.pop(path);
              },
            ),

            const SizedBox(height: AppSpacing.sm),

            // Gallery Option
            _buildOption(
              context,
              icon: Icons.photo_library_outlined,
              title: 'Choose from Gallery',
              subtitle: 'Select an existing image from your library',
              onTap: () async {
                final navigator = Navigator.of(context);
                final path = await PhotoService.captureOrPickPhoto(
                  context: context,
                  source: ImageSource.gallery,
                  currentPhotoPath: currentPhotoPath,
                );
                navigator.pop(path);
              },
            ),

            if (currentPhotoPath != null) ...[
              const SizedBox(height: AppSpacing.sm),
              _buildOption(
                context,
                icon: Icons.delete_outline,
                title: 'Remove Current Photo',
                subtitle: 'Detach photo from this item',
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context, '__remove__');
                },
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final color = isDestructive ? AppColors.statusDanger : AppColors.primaryStrong;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: isDestructive ? AppColors.statusDanger : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.55),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
