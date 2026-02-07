import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';

class FilmCarousel extends StatefulWidget {
  final List<FilmItem> films;
  const FilmCarousel({super.key, required this.films});

  @override
  State<FilmCarousel> createState() => _FilmCarouselState();
}

class _FilmCarouselState extends State<FilmCarousel> {
  int _activeIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        CarouselSlider.builder(
          itemCount: widget.films.length,
          itemBuilder: (context, index, realIndex) {
            final film = widget.films[index];
            return InkWell(
              onTap: () => context.push('/detail/${film.slug}'),
              child: AppImage(
                imageUrl: film.fullThumbUrl,
                boxFit: BoxFit.fill,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
              ),
            );
          },
          options: CarouselOptions(
            aspectRatio: 18 / 24,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 7),
            viewportFraction: 1,
            onPageChanged: (index, reason) {
              setState(() => _activeIndex = index);
            },
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.55,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.films.isNotEmpty &&
                  widget.films[_activeIndex].episodeCurrent != 'Trailer')
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  onPressed: () => context.push(
                    '/detail/${widget.films[_activeIndex].slug}',
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                      Text('Xem ngay', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              const SizedBox(width: 15),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                onPressed: () => context.push(
                  '/detail/${widget.films[_activeIndex].slug}',
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: Colors.white, size: 20),
                    SizedBox(width: 5),
                    Text('Chi tiết', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
