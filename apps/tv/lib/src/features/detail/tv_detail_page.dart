import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';

class TvDetailPage extends ConsumerWidget {
  final String slug;

  const TvDetailPage({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(filmDetailProvider(slug));

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: detailAsync.when(
        data: (response) {
          final film = response.data?.item;
          if (film == null) {
            return const Center(
              child: Text('Không tìm thấy phim',
                  style: TextStyle(color: Colors.white)),
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left - poster
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.35,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AppImage(
                      imageUrl: film.fullPosterUrl.isNotEmpty
                          ? film.fullPosterUrl
                          : film.fullThumbUrl,
                      boxFit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              // Right - info + episodes
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        film.name ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (film.originName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          film.originName!,
                          style: TextStyle(
                              color: Colors.grey[400], fontSize: 16),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (film.year != null)
                            _TvChip('${film.year}'),
                          if (film.quality != null)
                            _TvChip(film.quality!),
                          if (film.lang != null) _TvChip(film.lang!),
                          if (film.episodeCurrent != null)
                            _TvChip(film.episodeCurrent!),
                        ],
                      ),
                      if (film.content != null &&
                          film.content!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          _stripHtml(film.content!),
                          style: TextStyle(
                              color: Colors.grey[300], fontSize: 14),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 24),
                      if (film.episodes != null &&
                          film.episodes!.isNotEmpty) ...[
                        const Text(
                          'Danh sách tập',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...film.episodes!.map((ep) {
                          final episodes = ep.serverData ?? [];
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: episodes.map((serverData) {
                              final videoUrl =
                                  serverData.linkM3u8 ?? serverData.linkEmbed ?? '';
                              return Focus(
                                onKeyEvent: (node, event) {
                                  if (event is KeyDownEvent &&
                                      event.logicalKey ==
                                          LogicalKeyboardKey.select &&
                                      videoUrl.isNotEmpty) {
                                    context.push('/player', extra: {
                                      'videoUrl': videoUrl,
                                      'filmName': film.name ?? '',
                                      'episode': serverData.name ?? '',
                                      'slug': slug,
                                    });
                                    return KeyEventResult.handled;
                                  }
                                  return KeyEventResult.ignored;
                                },
                                child: Builder(
                                  builder: (context) {
                                    final hasFocus =
                                        Focus.of(context).hasFocus;
                                    return ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: hasFocus
                                            ? AppColors.primary
                                            : AppColors.surfaceColor,
                                        minimumSize: const Size(80, 44),
                                      ),
                                      onPressed: videoUrl.isEmpty
                                          ? null
                                          : () =>
                                              context.push('/player', extra: {
                                                'videoUrl': videoUrl,
                                                'filmName': film.name ?? '',
                                                'episode':
                                                    serverData.name ?? '',
                                                'slug': slug,
                                              }),
                                      child: Text(
                                        serverData.name ?? '',
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }).toList(),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: ElevatedButton(
            onPressed: () => ref.invalidate(filmDetailProvider(slug)),
            child: const Text('Thử lại'),
          ),
        ),
      ),
    );
  }

  String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
  }
}

class _TvChip extends StatelessWidget {
  final String label;
  const _TvChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }
}
