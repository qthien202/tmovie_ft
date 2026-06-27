import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_sizes.dart';
import '../theme/app_typography.dart';

/// Token-styled text input. Wraps [TextField] so search bars / forms across the
/// app share the same look, prefix icon and clear button.
class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hint;
  final IconData? prefixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final TextInputAction? textInputAction;
  final bool autofocus;

  const AppTextField({
    super.key,
    this.controller,
    this.hint,
    this.prefixIcon,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.textInputAction,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: textInputAction,
      autofocus: autofocus,
      style: AppTypography.bodyLarge,
      cursorColor: AppColors.primaryValue,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
        filled: true,
        fillColor: AppColors.surfaceElevated,
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, size: AppSizes.iconMd, color: AppColors.textTertiary),
        suffixIcon: onClear == null
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded, size: AppSizes.iconSm),
                color: AppColors.textTertiary,
                onPressed: onClear,
              ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: const BorderSide(color: AppColors.primaryValue),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
