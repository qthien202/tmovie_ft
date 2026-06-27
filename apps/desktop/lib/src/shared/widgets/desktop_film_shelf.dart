import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'desktop_film_card.dart';

class DesktopFilmShelf extends StatelessWidget {
  final String title;
  final List<FilmItem> items;
  final Function(FilmItem) onFilmTap;
  final VoidCallback? onSeeAll;

  const DesktopFilmShelf({
    super.key,
    required this.title,
    required this.items,
    required this.onFilmTap,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(80, 24, 32, 14),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
        ),
        // Horizontal scroll
        SizedBox(
          height: 280,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 80),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              return DesktopFilmCard(
                film: items[index],
                onTap: () => onFilmTap(items[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}
