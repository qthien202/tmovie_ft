import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tv_design_system.dart';

/// A reusable focus-aware button for TV D-pad navigation.
///
/// Supports icon-only (circular) and icon+label (rounded rect) variants.
/// Shows white-on-focus visual feedback with scale animation.
class TvFocusButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onPressed;
  final double size;
  final bool isPrimary;
  final bool autofocus;

  const TvFocusButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.label,
    this.size = 52,
    this.isPrimary = false,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasLabel = label != null;
    final radius = hasLabel
        ? TvDesignSystem.radiusMd
        : TvDesignSystem.radiusFull;

    return Focus(
      autofocus: autofocus,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter)) {
          onPressed();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;
          final backgroundColor = hasFocus
              ? (isPrimary ? TvDesignSystem.primary : Colors.white)
              : Colors.white.withValues(alpha: 0.1);
          final contentColor = hasFocus
              ? (isPrimary ? Colors.white : Colors.black)
              : Colors.white;

          return AnimatedScale(
            scale: hasFocus ? 1.05 : 1.0,
            duration: TvDesignSystem.durationFast,
            curve: TvDesignSystem.curveFluid,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Material(
                color: backgroundColor,
                child: InkWell(
                  onTap: onPressed,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: hasLabel
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, color: contentColor, size: 24),
                              const SizedBox(width: 12),
                              Text(
                                label!.toUpperCase(),
                                style: TextStyle(
                                  color: contentColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          )
                        : Icon(icon, color: contentColor, size: 24),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
