import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:core/core.dart';

class FilmInfo extends StatelessWidget {
  final FilmDetail film;

  const FilmInfo({super.key, required this.film});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            film.name ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (film.originName != null && film.originName!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              film.originName!,
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (film.year != null) _InfoChip(label: '${film.year}'),
              if (film.quality != null) _InfoChip(label: film.quality!),
              if (film.lang != null) _InfoChip(label: film.lang!),
              if (film.time != null && film.time!.isNotEmpty)
                _InfoChip(label: film.time!),
              if (film.episodeCurrent != null)
                _InfoChip(label: film.episodeCurrent!),
            ],
          ),
          if (film.category != null && film.category!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: film.category!.map((cat) {
                return Chip(
                  label: Text(
                    cat.name ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: AppColors.surfaceColor,
                  side: BorderSide.none,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
          if (film.director != null && film.director!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Đạo diễn: ${film.director!.join(", ")}',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
          ],
          if (film.actor != null && film.actor!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Diễn viên: ${film.actor!.join(", ")}',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (film.content != null && film.content!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Nội dung',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            HtmlWidget(
              film.content!,
              textStyle: TextStyle(color: Colors.grey[300], fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
