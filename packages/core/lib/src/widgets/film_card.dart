import 'package:flutter/material.dart';
import '../models/film_item.dart';
import '../theme/app_colors.dart';
import 'app_image.dart';

class FilmCard extends StatelessWidget {
  final FilmItem film;
  final VoidCallback? onTap;

  const FilmCard({super.key, required this.film, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AppImage(
              imageUrl: film.fullThumbUrl,
              borderRadius: BorderRadius.circular(8),
              width: double.infinity,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            film.name ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            film.originName ?? '',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (film.episodeCurrent != null)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryValue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                film.episodeCurrent!,
                style: const TextStyle(
                  color: AppColors.primaryValue,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
