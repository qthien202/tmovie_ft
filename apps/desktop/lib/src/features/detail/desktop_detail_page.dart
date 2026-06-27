import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:detail/detail.dart';
import 'package:media_library/media_library.dart';
import '../../shared/desktop_design_system.dart';

class DesktopDetailPage extends ConsumerWidget {
  final String slug;
  const DesktopDetailPage({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(filmDetailProvider(slug));
    final isFavAsync = ref.watch(isFavoriteProvider(slug));

    return Scaffold(
      backgroundColor: Colors.black,
      body: detailAsync.when(
        data: (response) {
          final film = response.data?.item;
          if (film == null) {
            return const Center(
              child: Text('Phim không tồn tại',
                  style: TextStyle(color: Colors.white38)),
            );
          }
          return _DetailContent(
            film: film,
            isFavAsync: isFavAsync,
            slug: slug,
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: DS.primary),
        ),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  color: Colors.white.withValues(alpha: 0.15), size: 48),
              const SizedBox(height: 16),
              const Text('Lỗi kết nối',
                  style: TextStyle(color: Colors.white38)),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => ref.invalidate(filmDetailProvider(slug)),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailContent extends ConsumerWidget {
  final FilmDetail film;
  final AsyncValue<bool> isFavAsync;
  final String slug;

  const _DetailContent({
    required this.film,
    required this.isFavAsync,
    required this.slug,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episodes = film.episodes ?? [];
    final List<ServerData> allEps =
        episodes.isNotEmpty ? episodes.first.serverData ?? [] : [];

    return Stack(
      children: [
        // Blur background
        Positioned.fill(
          child: AppImage(
              imageUrl: film.fullThumbUrl, boxFit: BoxFit.cover),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ),
        ),

        // Content
        CustomScrollView(
          slivers: [
            // Hero section
            SliverToBoxAdapter(
              child: SizedBox(
                height: 460,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppImage(
                        imageUrl: film.fullThumbUrl,
                        boxFit: BoxFit.cover),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.black.withValues(alpha: 0.9),
                            Colors.black.withValues(alpha: 0.5),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.95),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5],
                        ),
                      ),
                    ),

                    // Back button
                    Positioned(
                      top: 16,
                      left: 16,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter:
                              ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Material(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: () => context.pop(),
                              borderRadius: BorderRadius.circular(12),
                              child: const SizedBox(
                                width: 44,
                                height: 44,
                                child: Icon(Icons.arrow_back_rounded,
                                    color: Colors.white, size: 22),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Film info
                    Positioned(
                      left: 80,
                      bottom: 40,
                      right: 80,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Poster
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: DS.primary.withValues(alpha: 0.2),
                                  blurRadius: 25,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: SizedBox(
                                width: 160,
                                height: 240,
                                child: AppImage(
                                  imageUrl: film.fullPosterUrl,
                                  boxFit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 28),
                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  film.name ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (film.originName != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    film.originName!,
                                    style: TextStyle(
                                      color: Colors.white
                                          .withValues(alpha: 0.5),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (film.year != null)
                                      _tag('${film.year}'),
                                    if (film.episodeCurrent != null)
                                      _tag(film.episodeCurrent!),
                                    if (film.quality != null)
                                      _tag(film.quality!,
                                          highlight: true),
                                    if (film.lang != null)
                                      _tag(film.lang!),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    if (allEps.isNotEmpty)
                                      _playButton(context, allEps),
                                    const SizedBox(width: 12),
                                    _favButton(context, ref),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Description
            if (film.content != null && film.content!.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(80, 28, 80, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nội dung',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _stripHtml(film.content!),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                          height: 1.6,
                        ),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),

            // Episodes
            if (episodes.isNotEmpty)
              ...episodes.map((server) {
                final eps = server.serverData ?? [];
                if (eps.isEmpty) {
                  return const SliverToBoxAdapter(
                      child: SizedBox.shrink());
                }
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(80, 28, 80, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          server.serverName ?? 'Server',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: eps.map((ep) {
                            return _episodeChip(context, ep, eps);
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                );
              }),

            const SliverToBoxAdapter(child: SizedBox(height: 60)),
          ],
        ),
      ],
    );
  }

  Widget _playButton(
      BuildContext context, List<ServerData> allEps) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final ep = allEps.first;
          context.push('/player', extra: {
            'videoUrl': ep.linkM3u8 ?? '',
            'filmName': film.name ?? '',
            'episode': ep.name ?? 'Tập 1',
            'slug': slug,
            'episodes': film.episodes ?? [],
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_arrow_rounded,
                  color: Colors.black, size: 20),
              SizedBox(width: 8),
              Text(
                'Xem phim',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _favButton(BuildContext context, WidgetRef ref) {
    final isFav = isFavAsync.valueOrNull ?? false;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final favRepo = ref.read(favoritesRepositoryProvider);
          if (isFav) {
            await favRepo.removeFavorite(slug);
          } else {
            await favRepo.addFavorite(WatchHistoryEntry(
              slug: slug,
              name: film.name ?? '',
              originName: film.originName,
              thumbUrl: film.posterUrl,
            ));
          }
          ref.invalidate(isFavoriteProvider(slug));
          ref.invalidate(favoritesProvider);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isFav
                  ? Colors.redAccent.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isFav
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: isFav ? Colors.redAccent : Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                isFav ? 'Đã thích' : 'Yêu thích',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _episodeChip(
      BuildContext context, ServerData ep, List<ServerData> eps) {
    return Material(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () {
          context.push('/player', extra: {
            'videoUrl': ep.linkM3u8 ?? '',
            'filmName': film.name ?? '',
            'episode': ep.name ?? '',
            'slug': slug,
            'episodes': film.episodes ?? [],
          });
        },
        borderRadius: BorderRadius.circular(10),
        hoverColor: DS.primary.withValues(alpha: 0.15),
        child: Container(
          constraints: const BoxConstraints(minWidth: 60),
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Text(
            ep.name ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _tag(String text, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: highlight
            ? DS.primary.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlight
              ? DS.primary.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: highlight ? DS.primary : Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .trim();
  }
}
