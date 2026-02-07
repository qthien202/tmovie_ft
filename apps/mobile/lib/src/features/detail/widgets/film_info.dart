import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:core/core.dart';

class FilmInfo extends StatelessWidget {
  final FilmDetail film;

  const FilmInfo({super.key, required this.film});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tên phim chính
          Text(
            film.name ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          if (film.originName != null && film.originName!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              film.originName!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Chips thông tin kiểu Glassmorphism
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (film.year != null) _GlassChip(label: '${film.year}'),
                if (film.quality != null) _GlassChip(label: film.quality!),
                if (film.lang != null) _GlassChip(label: film.lang!),
                if (film.time != null && film.time!.isNotEmpty)
                  _GlassChip(label: film.time!),
                if (film.episodeCurrent != null)
                  _GlassChip(label: film.episodeCurrent!),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Thể loại
          if (film.category != null && film.category!.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: film.category!.map((cat) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    cat.name ?? '',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 24),

          // Meta info (Đạo diễn, Diễn viên)
          _MetaRow(
            label: 'Đạo diễn',
            value: film.director?.join(", ") ?? 'Đang cập nhật',
          ),
          const SizedBox(height: 8),
          _MetaRow(
            label: 'Diễn viên',
            value: film.actor?.join(", ") ?? 'Đang cập nhật',
          ),

          if (film.content != null && film.content!.isNotEmpty) ...[
            const SizedBox(height: 32),
            const Text(
              'Nội dung phim',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            HtmlWidget(
              film.content!,
              textStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 15,
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  final String label;
  const _GlassChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
