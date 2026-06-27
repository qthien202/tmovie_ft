import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';

/// Full-bleed cinematic hero (Apple TV+ / Netflix 2025 style): the active
/// film's artwork fills the top of the screen edge-to-edge, with the title,
/// meta line and actions floating over a gradient scrim. Swipeable + autoplay.
class CinematicHero extends StatefulWidget {
  final List<FilmItem> films;
  final bool autoPlay;
  final ValueChanged<FilmItem>? onActiveFilmChanged;

  /// Extra space below the floating content so it clears a pinned tab bar that
  /// the artwork bleeds behind.
  final double contentBottomInset;

  const CinematicHero({
    super.key,
    required this.films,
    this.autoPlay = true,
    this.onActiveFilmChanged,
    this.contentBottomInset = AppSpacing.lg,
  });

  @override
  State<CinematicHero> createState() => _CinematicHeroState();
}

class _CinematicHeroState extends State<CinematicHero> {
  final PageController _controller = PageController();
  int _active = 0;
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    if (widget.films.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onActiveFilmChanged?.call(widget.films[_active]);
      });
    }
    _restartAutoPlay();
  }

  @override
  void didUpdateWidget(covariant CinematicHero old) {
    super.didUpdateWidget(old);
    if (old.autoPlay != widget.autoPlay) _restartAutoPlay();
  }

  void _restartAutoPlay() {
    _autoTimer?.cancel();
    if (!widget.autoPlay || widget.films.length < 2) return;
    _autoTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_active + 1) % widget.films.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.films.isEmpty) return const SizedBox();

    return GestureDetector(
      // Tap anywhere on the hero → open the active film's detail.
      onTap: () => context.push('/detail/${widget.films[_active].slug}'),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Full-bleed artwork pager
          PageView.builder(
            controller: _controller,
            itemCount: widget.films.length,
            onPageChanged: (i) {
              setState(() => _active = i);
              widget.onActiveFilmChanged?.call(widget.films[i]);
              _restartAutoPlay();
            },
            itemBuilder: (context, index) {
              final film = widget.films[index];
              return AppImage(
                imageUrl: film.fullThumbUrl,
                boxFit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              );
            },
          ),

          // 2. Scrims: top (status bar legibility) + bottom (text legibility)
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.35, 0.72, 1.0],
                    colors: [
                      Color(0x99000000),
                      Color(0x00000000),
                      Color(0xCC0A0C0C),
                      AppColors.backgroundColor,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Floating content (title + play + dots under play)
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: widget.contentBottomInset,
            child: _HeroContent(
              film: widget.films[_active],
              count: widget.films.length,
              active: _active,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroContent extends StatelessWidget {
  final FilmItem film;
  final int count;
  final int active;
  const _HeroContent({
    required this.film,
    required this.count,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    film.name ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.displayLarge.copyWith(
                      fontSize: 28,
                      height: 1.05,
                      shadows: const [
                        Shadow(
                          color: Colors.black54,
                          offset: Offset(0, 2),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                  if ((film.originName ?? '').isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      film.originName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                HeroCircleButton(
                  icon: Icons.play_arrow_rounded,
                  primary: true,
                  size: 52,
                  iconSize: 28,
                  onTap: () => context.push('/detail/${film.slug}'),
                ),
                if (count > 1) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _Dots(count: count, active: active),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _MetaLine(film: film),
      ],
    );
  }
}

/// "★ 8.3 · 2026 · HD · Tập 3" — dot-separated meta, Apple TV+ style.
class _MetaLine extends StatelessWidget {
  final FilmItem film;
  const _MetaLine({required this.film});

  @override
  Widget build(BuildContext context) {
    final rating = film.tmdb?.voteAverage ?? film.imdb?.voteAverage;
    final parts = <Widget>[];

    if (rating != null && rating > 0) {
      parts.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, color: AppColors.rating, size: 16),
            const SizedBox(width: 3),
            Text(
              rating.toStringAsFixed(1),
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.rating,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }
    if (film.year != null) parts.add(_text('${film.year}'));
    if ((film.quality ?? '').isNotEmpty) parts.add(_text(film.quality!));
    if (film.lang?.contains('Vietsub') == true) parts.add(_text('Phụ đề'));
    if ((film.episodeCurrent ?? '').isNotEmpty) {
      parts.add(_text(film.episodeCurrent!));
    }

    final children = <Widget>[];
    for (var i = 0; i < parts.length; i++) {
      if (i > 0) children.add(_dot());
      children.add(parts[i]);
    }

    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }

  Widget _text(String s) => Text(
    s,
    style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
  );

  Widget _dot() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
    child: Text(
      '·',
      style: AppTypography.labelMedium.copyWith(color: AppColors.textTertiary),
    ),
  );
}

class _Dots extends StatelessWidget {
  final int count;
  final int active;
  const _Dots({required this.count, required this.active});

  @override
  Widget build(BuildContext context) {
    const maxDots = 6;
    final shown = count > maxDots ? maxDots : count;
    final activeShown = active < shown ? active : shown - 1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(shown, (i) {
        final isActive = i == activeShown;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isActive ? 14 : 5,
          height: 5,
          margin: const EdgeInsets.only(left: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2.5),
            color: isActive
                ? Colors.white
                : Colors.white.withValues(alpha: 0.4),
          ),
        );
      }),
    );
  }
}
