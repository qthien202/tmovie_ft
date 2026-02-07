import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';

class FilmCarousel extends StatefulWidget {
  final List<FilmItem> films;
  final Function(FilmItem)? onActiveFilmChanged;
  final bool autoPlay;

  const FilmCarousel({
    super.key,
    required this.films,
    this.onActiveFilmChanged,
    this.autoPlay = true,
  });

  @override
  State<FilmCarousel> createState() => _FilmCarouselState();
}

class _FilmCarouselState extends State<FilmCarousel> {
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    // Notify initial film
    if (widget.films.isNotEmpty && widget.onActiveFilmChanged != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onActiveFilmChanged!(widget.films[_activeIndex]);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.films.isEmpty) return const SizedBox();

    return Column(
      children: [
        const SizedBox(height: 35),
        CarouselSlider.builder(
          itemCount: widget.films.length,
          itemBuilder: (context, index, realIndex) {
            final film = widget.films[index];
            final isCenter = index == _activeIndex;
            return AnimatedOpacity(
              duration: const Duration(milliseconds: 400),
              opacity: isCenter ? 1.0 : 0.4,
              child: Transform.scale(
                scale: isCenter ? 1.0 : 0.75,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      if (isCenter)
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.8),
                          blurRadius: 25,
                          spreadRadius: 1,
                        ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 2 / 3,
                      child: AppImage(
                        imageUrl: film.fullPosterUrl,
                        boxFit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
          options: CarouselOptions(
            height: MediaQuery.of(context).size.height * 0.34,
            autoPlay: widget.autoPlay,
            autoPlayInterval: const Duration(seconds: 7),
            viewportFraction: 0.52,
            enlargeCenterPage: false,
            onPageChanged: (index, reason) {
              setState(() => _activeIndex = index);
              widget.onActiveFilmChanged?.call(widget.films[index]);
            },
          ),
        ),
        // Film Details Section
        _FilmInfoSection(film: widget.films[_activeIndex]),
        const SizedBox(height: 20),
        // Page Indicator (Dots)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.films.length > 12 ? 12 : widget.films.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _activeIndex == index ? 20 : 6,
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: _activeIndex == index
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FilmInfoSection extends StatelessWidget {
  final FilmItem film;
  const _FilmInfoSection({required this.film});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            film.name ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
              shadows: [
                Shadow(
                  color: Colors.black54,
                  offset: Offset(0, 4),
                  blurRadius: 10,
                ),
              ],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            film.originName ?? '',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  onPressed: () => context.push('/detail/${film.slug}'),
                  label: 'Xem Phim',
                  icon: Icons.play_arrow_rounded,
                  color: Colors.white.withValues(alpha: 0.9),
                  textColor: Colors.black,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  onPressed: () => context.push('/detail/${film.slug}'),
                  label: 'Thông tin',
                  icon: Icons.info_outline_rounded,
                  color: Colors.white.withValues(alpha: 0.12),
                  textColor: Colors.white,
                  isOutline: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Tags: Quality • Lang • Episode • Year
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _TagItem(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (film.quality?.toUpperCase() != 'HD') ...[
                      const Text(
                        'HD ',
                        style: TextStyle(
                          color: Color(0xffFFD700),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    Text(
                      film.quality ?? '4K',
                      style: TextStyle(
                        color: film.quality?.toUpperCase() == 'HD'
                            ? const Color(0xffFFD700)
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              _TagItem(
                text: film.lang?.contains('Vietsub') == true ? 'SUB' : 'TM',
              ),
              if (film.episodeCurrent != null &&
                  film.episodeCurrent!.isNotEmpty)
                _TagItem(text: film.episodeCurrent),
              _TagItem(text: '${film.year ?? 2025}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final bool isOutline;

  const _ActionButton({
    required this.onPressed,
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    this.isOutline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            border: isOutline
                ? Border.all(color: Colors.white.withValues(alpha: 0.15))
                : null,
            boxShadow: [
              if (!isOutline)
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: 24),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagItem extends StatelessWidget {
  final String? text;
  final Widget? child;

  const _TagItem({this.text, this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child:
          child ??
          Text(
            text!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
    );
  }
}
