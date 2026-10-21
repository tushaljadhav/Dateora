import 'package:flutter/material.dart';
import 'dart:io';
import '../models/item.dart';
import '../models/category_model.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_card.dart';
import 'category_badge.dart';
import 'status_pill.dart';
import '../screens/item_details_screen.dart';

class ItemTile extends StatelessWidget {
  final Item item;

  const ItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final status = item.evaluateStatus();
    final cat = CategoryModel.getById(item.category);
    final theme = Theme.of(context);

    final hasPhoto = item.photoUri != null && File(item.photoUri!).existsSync();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.itemGap),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => ItemDetailsScreen(itemId: item.id),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
        },
        child: Row(
          children: [
            // Photo thumbnail with Hero animation or CategoryBadge
            Hero(
              tag: 'item_hero_${item.id}',
              child: hasPhoto
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Image.file(
                        File(item.photoUri!),
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                      ),
                    )
                  : CategoryBadge(categoryId: item.category, size: 52),
            ),

            const SizedBox(width: AppSpacing.md),

            // Item Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppTextStyles.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        cat.name,
                        style: AppTextStyles.caption.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      if (item.location != null && item.location!.isNotEmpty) ...[
                        Text(
                          ' • ${item.location}',
                          style: AppTextStyles.caption.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.45),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    status.relativeText,
                    style: AppTextStyles.caption.copyWith(
                      color: status.textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            // Status Pill & Expiry Date
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusPill(evaluation: status, compact: true),
                const SizedBox(height: 6),
                Text(
                  item.expiryDate,
                  style: AppTextStyles.caption.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.45),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
