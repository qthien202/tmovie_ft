import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tv_design_system.dart';

/// A generic focus wrapper for TV D-pad navigation.
///
/// Handles the common pattern of Focus + KeyEvent + AnimatedScale
/// that is used throughout the TV app.
class TvFocusWrapper extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget Function(BuildContext context, bool hasFocus) builder;
  final double focusedScale;
  final bool autofocus;
  final FocusNode? focusNode;
  final ValueChanged<bool>? onFocusChange;

  const TvFocusWrapper({
    super.key,
    this.onTap,
    required this.builder,
    this.focusedScale = 1.1,
    this.autofocus = false,
    this.focusNode,
    this.onFocusChange,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      autofocus: autofocus,
      onFocusChange: onFocusChange,
      onKeyEvent: onTap != null
          ? (node, event) {
              if (event is KeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.select ||
                      event.logicalKey == LogicalKeyboardKey.enter)) {
                onTap!();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            }
          : null,
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;
          return AnimatedScale(
            scale: hasFocus ? focusedScale : 1.0,
            duration: TvDesignSystem.durationFast,
            curve: TvDesignSystem.curveFluid,
            child: builder(context, hasFocus),
          );
        },
      ),
    );
  }
}
