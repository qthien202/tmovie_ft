import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:detail/detail.dart';

class FilmInfo extends ConsumerWidget {
  final FilmDetail film;

  const FilmInfo({super.key, required this.film});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slug = film.slug ?? '';
    final peoplesAsync = ref.watch(filmPeoplesProvider(slug));
    final imagesAsync = ref.watch(filmImagesProvider(slug));

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thời lượng (các meta khác đã hiển thị ở hero)
          if (film.time != null && film.time!.isNotEmpty) ...[
            Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: AppSizes.iconSm,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(film.time!, style: AppTypography.bodyMedium),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Thể loại
          if (film.category != null && film.category!.isNotEmpty)
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: film.category!.map((cat) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryValue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: AppColors.primaryValue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    cat.name ?? '',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primaryValue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: AppSpacing.xl),

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
                    Text('Diễn viên', style: AppTypography.titleLarge),
                    const SizedBox(height: AppSpacing.md),
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

          // Image Gallery Section
          imagesAsync.when(
            data: (res) {
              final images = res.data?.images ?? [];
              final backdrops = images
                  .where((img) => img.type == 'backdrop')
                  .toList();
              final backdropBaseUrl =
                  res.data?.imageSizes?.backdrop?.w780 ?? '';

              if (backdrops.isEmpty) return const SizedBox();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.xxl),
                  Text('Hình ảnh', style: AppTypography.titleLarge),
                  const SizedBox(height: AppSpacing.md),
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

          if (film.content != null && film.content!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxl),
            Text('Nội dung phim', style: AppTypography.titleLarge),
            const SizedBox(height: AppSpacing.md),
            HtmlWidget(
              film.content!,
              textStyle: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ],
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
              child: AppImage(imageUrl: imageUrl, boxFit: BoxFit.contain),
            ),
          ),
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
