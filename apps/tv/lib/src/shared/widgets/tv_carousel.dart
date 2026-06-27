import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import '../tv_design_system.dart';

class TvCarousel extends StatefulWidget {
  final List<FilmItem> films;
  final Function(FilmItem)? onFilmTap;
  final Function(FilmItem)? onFilmFocused;

  const TvCarousel({
    super.key,
    required this.films,
    this.onFilmTap,
    this.onFilmFocused,
  });

  @override
  State<TvCarousel> createState() => _TvCarouselState();
}

class _TvCarouselState extends State<TvCarousel> {
  int _activeIndex = 0;
  bool _isFocused = false;
  final CarouselSliderController _controller = CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    if (widget.films.isEmpty) return const SizedBox.shrink();

    return Focus(
      onFocusChange: (hasFocus) {
        setState(() => _isFocused = hasFocus);
        if (hasFocus) {
          widget.onFilmFocused?.call(widget.films[_activeIndex]);
        }
      },
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _controller.previousPage();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _controller.nextPage();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter) {
            widget.onFilmTap?.call(widget.films[_activeIndex]);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.bottomLeft,
            children: [
              CarouselSlider.builder(
                carouselController: _controller,
                itemCount: widget.films.length,
                itemBuilder: (context, index, realIndex) {
                  final film = widget.films[index];
                  return _CarouselItem(
                    film: film,
                    isFocused: _isFocused && _activeIndex == index,
                  );
                },
                options: CarouselOptions(
                  height: 480,
                  viewportFraction: 0.92,
                  enlargeCenterPage: true,
                  enlargeStrategy: CenterPageEnlargeStrategy.zoom,
                  autoPlay: !_isFocused,
                  autoPlayInterval: const Duration(seconds: 10),
                  onPageChanged: (index, reason) {
                    setState(() => _activeIndex = index);
                    if (_isFocused) {
                      widget.onFilmFocused?.call(widget.films[index]);
                    }
                  },
                ),
              ),

              // Premium Indicators
              Positioned(
                bottom: 40,
                right: 80,
                child: AnimatedSmoothIndicator(
                  activeIndex: _activeIndex,
                  count: widget.films.length,
                  effect: ExpandingDotsEffect(
                    dotHeight: 10,
                    dotWidth: 10,
                    activeDotColor: TvDesignSystem.primary,
                    dotColor: Colors.white.withValues(alpha: 0.25),
                    expansionFactor: 4,
                    spacing: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CarouselItem extends StatelessWidget {
  final FilmItem film;
  final bool isFocused;

  const _CarouselItem({required this.film, required this.isFocused});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: TvDesignSystem.durationMedium,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          if (isFocused)
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.3),
              blurRadius: 40,
              spreadRadius: 2,
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AppImage(imageUrl: film.fullPosterUrl, boxFit: BoxFit.cover),

            // Cinematic Multi-layered overlays
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.95),
                    Colors.black.withValues(alpha: 0.45),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 0.9],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.6],
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(56.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (film.quality != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: TvDesignSystem.primary,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: TvDesignSystem.primary.withValues(
                              alpha: 0.5,
                            ),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Text(
                        film.quality!.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Text(
                    film.name?.toUpperCase() ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    film.originName ?? '',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Row(
                    children: [
                      _CarouselButton(
                        icon: Icons.play_arrow_rounded,
                        label: 'XEM NGAY',
                        isFocused: isFocused,
                        isPrimary: true,
                      ),
                      const SizedBox(width: 24),
                      _CarouselButton(
                        icon: Icons.add_rounded,
                        label: 'DANH SÁCH',
                        isPrimary: false,
                        isFocused: isFocused,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // High-intensity focus border
            if (isFocused)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 4),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.3),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CarouselButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final bool isFocused;

  const _CarouselButton({
    required this.icon,
    required this.label,
    this.isPrimary = true,
    required this.isFocused,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
      decoration: BoxDecoration(
        color: isPrimary
            ? (isFocused
                  ? Colors.white
                  : TvDesignSystem.primary.withValues(alpha: 0.8))
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFocused
              ? Colors.white
              : Colors.white.withValues(alpha: 0.12),
          width: 2,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: (isPrimary ? TvDesignSystem.primary : Colors.white)
                      .withValues(alpha: 0.3),
                  blurRadius: 15,
                ),
              ]
            : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isPrimary && isFocused ? Colors.black : Colors.white,
            size: 28,
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: TextStyle(
              color: isPrimary && isFocused ? Colors.black : Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
