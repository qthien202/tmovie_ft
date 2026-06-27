import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_sizes.dart';
import '../theme/app_typography.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }

enum AppButtonSize { sm, md, lg }

/// Shared button for the whole app. Prefer this over raw Material buttons so
/// every screen gets the same shape, sizing, loading and disabled behaviour.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool loading;
  final bool expanded;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.icon,
    this.loading = false,
    this.expanded = false,
  });

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.md,
    this.icon,
    this.loading = false,
    this.expanded = false,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.md,
    this.icon,
    this.loading = false,
    this.expanded = false,
  }) : variant = AppButtonVariant.ghost;

  double get _height => switch (size) {
        AppButtonSize.sm => 36,
        AppButtonSize.md => 44,
        AppButtonSize.lg => 52,
      };

  double get _hPad => switch (size) {
        AppButtonSize.sm => 12,
        AppButtonSize.md => 20,
        AppButtonSize.lg => 24,
      };

  double get _iconSize =>
      size == AppButtonSize.sm ? AppSizes.iconSm : AppSizes.iconMd;

  TextStyle get _textStyle =>
      size == AppButtonSize.sm ? AppTypography.labelMedium : AppTypography.labelLarge;

  ({Color bg, Color fg, BorderSide side}) get _colors => switch (variant) {
        AppButtonVariant.primary => (
            bg: AppColors.primaryValue,
            fg: AppColors.onPrimary,
            side: BorderSide.none,
          ),
        AppButtonVariant.secondary => (
            bg: AppColors.surfaceElevated,
            fg: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.border),
          ),
        AppButtonVariant.ghost => (
            bg: Colors.transparent,
            fg: AppColors.primaryValue,
            side: BorderSide.none,
          ),
        AppButtonVariant.danger => (
            bg: AppColors.error,
            fg: Colors.white,
            side: BorderSide.none,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final c = _colors;
    final disabled = onPressed == null || loading;

    final child = loading
        ? SizedBox(
            height: _iconSize,
            width: _iconSize,
            child: CircularProgressIndicator(strokeWidth: 2, color: c.fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: _iconSize, color: c.fg),
                const SizedBox(width: 8),
              ],
              Text(label, style: _textStyle.copyWith(color: c.fg)),
            ],
          );

    final button = Material(
      color: disabled ? c.bg.withValues(alpha: 0.5) : c.bg,
      borderRadius: AppRadius.brMd,
      child: InkWell(
        onTap: disabled ? null : onPressed,
        borderRadius: AppRadius.brMd,
        child: Container(
          height: _height,
          padding: EdgeInsets.symmetric(horizontal: _hPad),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: AppRadius.brMd,
            border: Border.fromBorderSide(c.side),
          ),
          child: child,
        ),
      ),
    );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
