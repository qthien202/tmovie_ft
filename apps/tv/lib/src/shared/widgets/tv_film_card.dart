import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:core/core.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import '../tv_design_system.dart';

class TvFilmCard extends StatefulWidget {
  final FilmItem film;
  final VoidCallback onTap;
  final Function(bool)? onFocusChange;
  final double width;
  final double aspectRatio;

  final bool? isFocused; // Manual override
  final bool canRequestFocus;
  final bool showBorder;
  final bool showShadow;

  const TvFilmCard({
    super.key,
    required this.film,
    required this.onTap,
    this.onFocusChange,
    this.width = 280,
    this.aspectRatio = 16 / 9,
    this.isFocused,
    this.canRequestFocus = true,
    this.showBorder = true,
    this.showShadow = true,
  });

  @override
  State<TvFilmCard> createState() => _TvFilmCardState();
}

class _TvFilmCardState extends State<TvFilmCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = widget.width.isInfinite
            ? constraints.maxWidth
            : widget.width;
        final thumbHeight = availableWidth / widget.aspectRatio;

        final isCardFocused = widget.isFocused ?? _isFocused;

        return Focus(
          canRequestFocus: widget.canRequestFocus,
          onFocusChange: (hasFocus) {
            setState(() => _isFocused = hasFocus);
            widget.onFocusChange?.call(hasFocus);
          },
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent &&
                (event.logicalKey == LogicalKeyboardKey.select ||
                    event.logicalKey == LogicalKeyboardKey.enter)) {
              widget.onTap();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedScale(
              scale: isCardFocused ? 1.08 : 1.0,
              duration: TvDesignSystem.durationFast,
              curve: TvDesignSystem.curveFluid,
              child: SizedBox(
                width: availableWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Thumbnail area with border
                    AnimatedContainer(
                      duration: TvDesignSystem.durationFast,
                      width: availableWidth,
                      height: thumbHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          TvDesignSystem.radiusLg,
                        ),
                        boxShadow: isCardFocused && widget.showShadow
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                              ]
                            : [],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl:
                                (widget.film.posterUrl != null &&
                                    widget.film.posterUrl!.isNotEmpty)
                                ? widget.film.fullPosterUrl
                                : widget.film.fullThumbUrl,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.high,
                            placeholder: (context, url) => Container(
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                            errorWidget: (context, url, error) =>
                                CachedNetworkImage(
                                  imageUrl: widget.film.fullThumbUrl,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) =>
                                      const Icon(
                                        Icons.movie_outlined,
                                        color: Colors.white24,
                                      ),
                                ),
                          ),
                          // Premium border overlay when focused
                          if (isCardFocused && widget.showBorder)
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  TvDesignSystem.radiusLg,
                                ),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4.0,
                                ),
                              ),
                            ),
                          _buildBadges(isCardFocused),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Film Details Below Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.film.name ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isCardFocused
                                  ? Colors.white
                                  : Colors.white70,
                              fontSize: 18,
                              fontWeight: isCardFocused
                                  ? FontWeight.w900
                                  : FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.film.originName ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isCardFocused
                                  ? Colors.white.withValues(alpha: 0.6)
                                  : Colors.white.withValues(alpha: 0.3),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadges(bool isFocused) {
    return Stack(
      children: [
        // Top-Left: Quality and Rating
        Positioned(
          top: 8,
          left: 8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.film.quality != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: TvDesignSystem.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.film.quality!.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              if (widget.film.tmdb?.voteAverage != null &&
                  widget.film.tmdb!.voteAverage! > 0) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0xffFFD700).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xffFFD700),
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        widget.film.tmdb!.voteAverage!.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Color(0xffFFD700),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        // Top-Right: Episode and Year
        Positioned(
          top: 8,
          right: 8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (widget.film.episodeCurrent != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    widget.film.episodeCurrent!.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (widget.film.year != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${widget.film.year}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
