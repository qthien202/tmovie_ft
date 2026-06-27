import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Circular action used over cinematic hero artwork (Apple TV+ / immersive
/// streaming 2025-2026).
///
/// * [primary] → a crisp solid-white disc with a dark teal glyph: the clean,
///   high-contrast "play" treatment used by premium streamers.
/// * otherwise → a frosted-glass disc that blurs the backdrop, for secondary
///   actions that should stay subtle.
class HeroCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  /// Diameter of the circle.
  final double size;
  final double iconSize;

  /// Optional caption rendered under the circle.
  final String? label;

  /// Primary actions use the solid-white treatment.
  final bool primary;

  const HeroCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 56,
    this.iconSize = 26,
    this.label,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final circle = primary ? _primaryDisc() : _frosted();

    final tappable = Material(
      type: MaterialType.transparency,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: circle,
      ),
    );

    if (label == null) return tappable;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        tappable,
        const SizedBox(height: AppSpacing.xs),
        Text(
          label!,
          style: AppTypography.labelSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            shadows: const [Shadow(color: Colors.black54, blurRadius: 6)],
          ),
        ),
      ],
    );
  }

  /// Solid white disc with a black glyph — crisp and premium.
  Widget _primaryDisc() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFE6EAEA)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      // Optical centering: the play triangle's visual mass sits left.
      child: Padding(
        padding: EdgeInsets.only(
          left: icon == Icons.play_arrow_rounded ? 3 : 0,
        ),
        child: Icon(icon, color: Colors.black, size: iconSize),
      ),
    );
  }

  /// Frosted-glass disc that blurs the artwork behind it.
  Widget _frosted() {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.40),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.26),
                  Colors.white.withValues(alpha: 0.07),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.40),
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: iconSize,
              shadows: const [Shadow(color: Colors.black38, blurRadius: 8)],
            ),
          ),
        ),
      ),
    );
  }
}
