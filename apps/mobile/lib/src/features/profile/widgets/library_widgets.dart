import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';

/// Large collapsing app bar shared by the History & Favorites library pages.
class LibraryAppBar extends StatelessWidget {
  final String title;
  final int count;
  final String unit;
  const LibraryAppBar({
    super.key,
    required this.title,
    required this.count,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: AppColors.backgroundColor,
      surfaceTintColor: Colors.transparent,
      pinned: true,
      expandedHeight: 132,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textPrimary,
          size: AppSizes.iconSm,
        ),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(
          left: AppSpacing.lg,
          bottom: AppSpacing.md,
        ),
        expandedTitleScale: 1.6,
        title: Text(
          title,
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x260FA3A3), AppColors.backgroundColor],
            ),
          ),
          alignment: Alignment.topRight,
          padding: const EdgeInsets.only(top: 64, right: AppSpacing.lg),
          child: count > 0
              ? Text(
                  '$count $unit',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class LibraryEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const LibraryEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 76, color: AppColors.border),
        const SizedBox(height: AppSpacing.xl),
        Text(title, style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium,
          ),
        ),
      ],
    );
  }
}
