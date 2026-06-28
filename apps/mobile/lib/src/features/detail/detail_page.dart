import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:detail/detail.dart';
import 'package:media_library/media_library.dart';
import 'widgets/film_info.dart';
import 'widgets/episodes_rail.dart';

class DetailPage extends ConsumerStatefulWidget {
  final String slug;
  final String? name;

  const DetailPage({super.key, required this.slug, this.name});

  @override
  ConsumerState<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends ConsumerState<DetailPage> {
  late ScrollController _scrollController;
  bool _showStickyCTA = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    _scrollController.addListener(() {
      final showCTA = _scrollController.offset > 450;
      if (showCTA != _showStickyCTA) {
        setState(() => _showStickyCTA = showCTA);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Whether the episode rail is worth showing (a series with >1 playable
  /// episode). Single-episode films just use the hero's "Xem ngay".
  bool _hasMultipleEpisodes(FilmDetail film) {
    final eps = film.episodes;
    if (eps == null || eps.isEmpty) return false;
    for (final s in eps) {
      if ((s.serverData?.length ?? 0) > 1) return true;
    }
    return false;
  }

  String? _findVideoUrl(FilmDetail film) {
    final episodes = film.episodes;
    if (episodes == null || episodes.isEmpty) return null;
    for (final episode in episodes) {
      final serverData = episode.serverData;
      if (serverData == null) continue;
      for (final data in serverData) {
        final url = data.linkM3u8 ?? data.linkEmbed;
        if (url != null && url.isNotEmpty) return url;
      }
    }
    return null;
  }

  void _onPlayTap(FilmDetail film) {
    final videoUrl = _findVideoUrl(film);
    if (videoUrl != null) {
      final ep = film.episodes!.first.serverData!.first;

      // Lưu lịch sử xem
      final repo = ref.read(historyRepositoryProvider);
      repo.addHistory(
        WatchHistoryEntry(
          slug: film.slug ?? '',
          name: film.name ?? '',
          originName: film.originName,
          thumbUrl: film.fullThumbUrl,
          episode: ep.name,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      ref.invalidate(watchHistoryProvider);

      context.push(
        '/player',
        extra: {
          'videoUrl': videoUrl,
          'filmName': film.name ?? '',
          'episode': ep.name ?? '',
          'slug': film.slug ?? '',
          'episodes': film.episodes ?? [],
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phim này chưa có link phát'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(filmDetailProvider(widget.slug));

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: detailAsync.when(
        data: (response) {
          final film = response.data?.item;
          if (film == null) {
            return Center(
              child: Text(
                'Không tìm thấy phim',
                style: AppTypography.bodyLarge,
              ),
            );
          }

          return Stack(
            children: [
              // Main Scroll Content (hero lives in the SliverAppBar)
              CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Immersive hero — no tab bar; the page flows as one scroll.
                  SliverAppBar(
                    expandedHeight: MediaQuery.sizeOf(context).height * 0.66,
                    pinned: true,
                    stretch: true,
                    backgroundColor: AppColors.backgroundColor,
                    elevation: 0,
                    leadingWidth: 70,
                    leading: _buildGlassBackButton(),
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.parallax,
                      stretchModes: const [StretchMode.zoomBackground],
                      background: _buildHero(film),
                    ),
                  ),

                  // Flowing content: episodes rail → cast / gallery / synopsis.
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 120),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_hasMultipleEpisodes(film)) ...[
                            const SizedBox(height: AppSpacing.xl),
                            EpisodesRail(
                              episodes: film.episodes ?? [],
                              filmName: film.name ?? '',
                              slug: film.slug ?? '',
                              thumbUrl: film.fullThumbUrl,
                              onEpisodeTap: (ep) {
                                final repo = ref.read(
                                  historyRepositoryProvider,
                                );
                                repo.addHistory(
                                  WatchHistoryEntry(
                                    slug: film.slug ?? '',
                                    name: film.name ?? '',
                                    originName: film.originName,
                                    thumbUrl: film.fullThumbUrl,
                                    episode: ep.name,
                                    timestamp:
                                        DateTime.now().millisecondsSinceEpoch,
                                  ),
                                );
                                ref.invalidate(watchHistoryProvider);
                              },
                            ),
                          ],
                          FilmInfo(film: film),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // 3. Floating Interactive CTA
              if (_findVideoUrl(film) != null) _buildStickyCTA(film),
            ],
          );
        },
        loading: () => const FilmDetailSkeleton(),
        error: (e, s) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Có lỗi xảy ra', style: AppTypography.titleMedium),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Thử lại',
                onPressed: () =>
                    ref.invalidate(filmDetailProvider(widget.slug)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassBackButton() {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Center(
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => context.pop(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(FilmDetail film) async {
    final slug = film.slug ?? '';
    final isFav = ref.read(isFavoriteProvider(slug)).valueOrNull ?? false;
    final repo = ref.read(favoritesRepositoryProvider);
    if (isFav) {
      await repo.removeFavorite(slug);
    } else {
      await repo.addFavorite(
        WatchHistoryEntry(
          slug: slug,
          name: film.name ?? '',
          originName: film.originName,
          thumbUrl: film.fullThumbUrl,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }
    ref.invalidate(isFavoriteProvider(slug));
    ref.invalidate(favoritesProvider);
  }

  Widget _buildHero(FilmDetail film) {
    final hasVideo = _findVideoUrl(film) != null;
    final genres = (film.category ?? []).take(3).toList();

    return Stack(
      fit: StackFit.expand,
      children: [
        // Full-bleed artwork
        AppImage(imageUrl: film.fullThumbUrl, boxFit: BoxFit.cover),
        // Cinematic scrim: darken top a touch, deep fade into the page.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.38, 0.70, 1.0],
              colors: [
                Color(0x59000000),
                Color(0x00000000),
                Color(0xDD0A0C0C),
                AppColors.backgroundColor,
              ],
            ),
          ),
        ),
        // Floating title + meta + primary action.
        Positioned(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: 28,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (genres.isNotEmpty) ...[
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final g in genres) _HeroGenreChip(label: g.name ?? ''),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Text(
                film.name ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.displayLarge.copyWith(
                  fontSize: 30,
                  height: 1.05,
                  shadows: const [
                    Shadow(
                      color: Colors.black87,
                      offset: Offset(0, 2),
                      blurRadius: 16,
                    ),
                  ],
                ),
              ),
              if ((film.originName ?? '').isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  film.originName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              _HeroMetaLine(film: film),
              const SizedBox(height: AppSpacing.lg),
              _buildHeroActions(film, hasVideo),
            ],
          ),
        ),
      ],
    );
  }

  /// Primary "Xem ngay" CTA + favorite, the cinematic call-to-action row.
  Widget _buildHeroActions(FilmDetail film, bool hasVideo) {
    final slug = film.slug ?? '';
    final isFav = ref.watch(isFavoriteProvider(slug)).valueOrNull ?? false;

    final favBtn = _HeroSquareAction(
      icon: isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
      label: 'Thích',
      active: isFav,
      onTap: () => _toggleFavorite(film),
    );

    if (!hasVideo) {
      return Row(children: [favBtn]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: _PlayCtaButton(onTap: () => _onPlayTap(film))),
        const SizedBox(width: AppSpacing.md),
        favBtn,
      ],
    );
  }

  Widget _buildStickyCTA(FilmDetail film) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      curve: Curves.fastOutSlowIn,
      bottom: _showStickyCTA ? 24 : -120,
      left: 16,
      right: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: AppImage(
                    imageUrl: film.fullThumbUrl,
                    width: 50,
                    height: 50,
                    boxFit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        film.name ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        film.episodeCurrent ?? 'Mới nhất',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _StickyFavorite(film: film, onToggle: () => _toggleFavorite(film)),
                const SizedBox(width: AppSpacing.sm),
                AppButton(
                  label: 'Xem ngay',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () => _onPlayTap(film),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small teal-tinted genre chip used in the hero.
class _HeroGenreChip extends StatelessWidget {
  final String label;
  const _HeroGenreChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Big gradient "Xem ngay" call-to-action.
class _PlayCtaButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PlayCtaButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.primaryValue,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.play_arrow_rounded,
                color: AppColors.onPrimary,
                size: 28,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Xem ngay',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Glassy square action (favorite) beside the hero CTA.
class _HeroSquareAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _HeroSquareAction({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          width: 60,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: active
                  ? AppColors.primaryValue
                  : Colors.white.withValues(alpha: 0.22),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: active ? AppColors.primaryValue : Colors.white,
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: active ? AppColors.primaryValue : Colors.white70,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Favorite heart for the collapsed sticky CTA.
class _StickyFavorite extends ConsumerWidget {
  final FilmDetail film;
  final VoidCallback onToggle;
  const _StickyFavorite({required this.film, required this.onToggle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav =
        ref.watch(isFavoriteProvider(film.slug ?? '')).valueOrNull ?? false;
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Icon(
          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: isFav ? AppColors.primaryValue : Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

/// "★ 8.3 · 2026 · HD · Phụ đề · Tập 3" — dot-separated meta for the hero.
class _HeroMetaLine extends StatelessWidget {
  final FilmDetail film;
  const _HeroMetaLine({required this.film});

  @override
  Widget build(BuildContext context) {
    final rating = film.tmdb?.voteAverage ?? film.imdb?.voteAverage;
    final parts = <Widget>[];

    if (rating != null && rating > 0) {
      parts.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, color: AppColors.rating, size: 16),
            const SizedBox(width: 3),
            Text(
              rating.toStringAsFixed(1),
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.rating,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }
    if (film.year != null) parts.add(_text('${film.year}'));
    if ((film.quality ?? '').isNotEmpty) parts.add(_text(film.quality!));
    if (film.lang?.contains('Vietsub') == true) parts.add(_text('Phụ đề'));
    if ((film.episodeCurrent ?? '').isNotEmpty) {
      parts.add(_text(film.episodeCurrent!));
    }

    final children = <Widget>[];
    for (var i = 0; i < parts.length; i++) {
      if (i > 0) {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              '·',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
        );
      }
      children.add(parts[i]);
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }

  Widget _text(String s) => Text(
    s,
    style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
  );
}
