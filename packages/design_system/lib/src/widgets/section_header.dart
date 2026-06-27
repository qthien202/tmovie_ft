import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_typography.dart';

/// Row title with an optional "see all" action. Use for every shelf/section so
/// headers line up across screens.
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  final String seeAllLabel;

  const SectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
    this.seeAllLabel = 'Xem thêm',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppTypography.titleLarge)),
        if (onSeeAll != null)
          InkWell(
            onTap: onSeeAll,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  Text(
                    seeAllLabel,
                    style: AppTypography.labelMedium
                        .copyWith(color: AppColors.primaryValue),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: AppSizes.iconSm,
                    color: AppColors.primaryValue,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
