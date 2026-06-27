import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_elevation.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Consistent surface container. Use for any "card" instead of hand-rolling a
/// Container with its own colour/radius/border.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final bool elevated;
  final bool bordered;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.elevated = false,
    this.bordered = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color ??
            (elevated ? AppColors.surfaceElevated : AppColors.surfaceColor),
        borderRadius: AppRadius.brLg,
        border: bordered ? Border.all(color: AppColors.border) : null,
        boxShadow: elevated ? AppElevation.md : null,
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brLg,
        child: content,
      ),
    );
  }
}
