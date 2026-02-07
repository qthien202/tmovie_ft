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
    this.childAspectRatio = 0.55,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: films.length,
      itemBuilder: (context, index) {
        final film = films[index];
        return FilmCard(film: film, onTap: () => onFilmTap?.call(film));
      },
    );
  }

  /// Sliver version for use in CustomScrollView
  static Widget asSliver({
    required List<FilmItem> films,
    void Function(FilmItem film)? onFilmTap,
    int crossAxisCount = 3,
    double childAspectRatio = 0.55,
  }) {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        final film = films[index];
        return FilmCard(film: film, onTap: () => onFilmTap?.call(film));
      }, childCount: films.length),
    );
  }
}
