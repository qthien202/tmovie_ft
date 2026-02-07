import 'package:flutter/material.dart';
import '../models/film_item.dart';
import 'film_card.dart';

class FilmGrid extends StatelessWidget {
  final List<FilmItem> films;
  final void Function(FilmItem film)? onFilmTap;
  final int crossAxisCount;
  final double childAspectRatio;

  const FilmGrid({
    super.key,
    required this.films,
    this.onFilmTap,
    this.crossAxisCount = 3,
    this.childAspectRatio = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: films.length,
      itemBuilder: (context, index) {
        final film = films[index];
        return FilmCard(film: film, onTap: () => onFilmTap?.call(film));
      },
    );
  }
}
