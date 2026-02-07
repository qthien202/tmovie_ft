import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:core/core.dart';

class FilmInfo extends ConsumerWidget {
  final FilmDetail film;

  const FilmInfo({super.key, required this.film});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slug = film.slug ?? '';
    final peoplesAsync = ref.watch(filmPeoplesProvider(slug));
    final imagesAsync = ref.watch(filmImagesProvider(slug));

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

          // Chips thông tin + điểm TMDB/IMDB
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (film.tmdb?.voteAverage != null &&
                    film.tmdb!.voteAverage! > 0)
                  _RatingChip(
                    label: 'TMDB',
                    score: film.tmdb!.voteAverage!,
                  ),
                if (film.imdb?.voteAverage != null &&
                    film.imdb!.voteAverage! > 0)
                  _RatingChip(
                    label: 'IMDB',
                    score: film.imdb!.voteAverage!,
                  ),
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

          // Cast Section
          peoplesAsync.when(
            data: (res) {
              final peoples = res.data?.peoples ?? [];
              final actors = peoples
                  .where((p) => p.knownForDepartment == 'Acting')
                  .toList();
              final directors = peoples
                  .where((p) => p.knownForDepartment == 'Directing')
                  .toList();
              final profileSizes = res.data?.profileSizes;

              if (actors.isEmpty && directors.isEmpty) {
                return _buildFallbackMeta();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (directors.isNotEmpty) ...[
                    _MetaRow(
                      label: 'Đạo diễn',
                      value: directors.map((d) => d.name ?? '').join(', '),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (actors.isNotEmpty) ...[
                    const Text(
                      'Diễn viên',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 130,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: actors.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                          return _ActorCard(
                            person: actors[index],
                            profileBaseUrl: profileSizes?.w185 ?? '',
                          );
                        },
                      ),
                    ),
                  ],
                ],
              );
            },
            loading: () => _buildFallbackMeta(),
            error: (_, __) => _buildFallbackMeta(),
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

          // Image Gallery Section
          imagesAsync.when(
            data: (res) {
              final images = res.data?.images ?? [];
              final backdrops =
                  images.where((img) => img.type == 'backdrop').toList();
              final backdropBaseUrl =
                  res.data?.imageSizes?.backdrop?.w780 ?? '';

              if (backdrops.isEmpty) return const SizedBox();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  const Text(
                    'Hình ảnh',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 160,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: backdrops.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final img = backdrops[index];
                        final imageUrl =
                            '$backdropBaseUrl${img.filePath ?? ''}';
                        return GestureDetector(
                          onTap: () => _showFullImage(
                            context,
                            '${res.data?.imageSizes?.backdrop?.original ?? ''}${img.filePath ?? ''}',
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: AppImage(
                              imageUrl: imageUrl,
                              width: 280,
                              height: 160,
                              boxFit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackMeta() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetaRow(
          label: 'Đạo diễn',
          value: film.director?.join(", ") ?? 'Đang cập nhật',
        ),
        const SizedBox(height: 8),
        _MetaRow(
          label: 'Diễn viên',
          value: film.actor?.join(", ") ?? 'Đang cập nhật',
        ),
      ],
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AppImage(
                imageUrl: imageUrl,
                boxFit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RatingChip extends StatelessWidget {
  final String label;
  final double score;
  const _RatingChip({required this.label, required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
          const SizedBox(width: 4),
          Text(
            '$label ${score.toStringAsFixed(1)}',
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
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

class _ActorCard extends StatelessWidget {
  final FilmPerson person;
  final String profileBaseUrl;
  const _ActorCard({required this.person, required this.profileBaseUrl});

  @override
  Widget build(BuildContext context) {
    final hasProfile =
        person.profilePath != null && person.profilePath!.isNotEmpty;
    final imageUrl = hasProfile ? '$profileBaseUrl${person.profilePath}' : '';

    return SizedBox(
      width: 80,
      child: Column(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            child: hasProfile
                ? ClipOval(
                    child: AppImage(
                      imageUrl: imageUrl,
                      width: 70,
                      height: 70,
                      boxFit: BoxFit.cover,
                    ),
                  )
                : Icon(
                    Icons.person_rounded,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 30,
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            person.name ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (person.character != null && person.character!.isNotEmpty)
            Text(
              person.character!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 10,
              ),
            ),
        ],
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
