import 'package:flutter/material.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final Border? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = color ?? theme.cardTheme.color;

    Widget content = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
      child: child,
    );

    if (onTap != null) {
      content = InkWell(
        borderRadius: AppRadius.cardRadius,
        onTap: onTap,
        child: content,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: AppRadius.cardRadius,
        border: border ?? Border.all(color: theme.colorScheme.outline, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: content,
      ),
    );
  }
}
