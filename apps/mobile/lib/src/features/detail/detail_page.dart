import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:detail/detail.dart';
import 'package:media_library/media_library.dart';
import 'widgets/film_info.dart';
import 'widgets/episode_selector.dart';

class DetailPage extends ConsumerStatefulWidget {
  final String slug;
  final String? name;

  const DetailPage({super.key, required this.slug, this.name});

  @override
  ConsumerState<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends ConsumerState<DetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  bool _showStickyCTA = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController = ScrollController();

    _scrollController.addListener(() {
      final showCTA = _scrollController.offset > 450;
      if (showCTA != _showStickyCTA) {
        setState(() => _showStickyCTA = showCTA);
      }
    });

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
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
                  // App Bar with Poster & Tab Selection
                  SliverAppBar(
                    expandedHeight: MediaQuery.sizeOf(context).height * 0.62,
                    pinned: true,
                    stretch: true,
                    backgroundColor: AppColors.backgroundColor,
                    elevation: 0,
                    leadingWidth: 70,
                    leading: _buildGlassBackButton(),
                    actions: [_buildFavoriteButton(film)],
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.pin,
                      stretchModes: const [StretchMode.zoomBackground],
                      background: _buildHero(film),
                    ),
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(70),
                      child: _buildGlassTabBar(),
                    ),
                  ),

                  // Content Sliver (Switches based on Tab)
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 120),
                    sliver: SliverToBoxAdapter(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _tabController.index == 0
                            ? FilmInfo(film: film)
                            : EpisodeSelector(
                                episodes: film.episodes ?? [],
                                filmName: film.name ?? '',
                                slug: film.slug ?? '',
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

  Widget _buildFavoriteButton(FilmDetail film) {
    final slug = film.slug ?? '';
    final isFavAsync = ref.watch(isFavoriteProvider(slug));

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Center(
        child: GestureDetector(
          onTap: () async {
            final isFav = isFavAsync.valueOrNull ?? false;
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
          },
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Center(
                  child: isFavAsync.when(
                    data: (isFav) => Icon(
                      isFav
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFav ? AppColors.primaryValue : Colors.white,
                      size: 20,
                    ),
                    loading: () => const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white54,
                      ),
                    ),
                    error: (_, _) => const Icon(
                      Icons.favorite_border_rounded,
                      color: Colors.white54,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(FilmDetail film) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Full-bleed artwork
        AppImage(imageUrl: film.fullThumbUrl, boxFit: BoxFit.cover),
        // Scrim for legibility + fade into the page
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.45, 0.78, 1.0],
              colors: [
                Color(0x66000000),
                Color(0x00000000),
                Color(0xCC0A0C0C),
                AppColors.backgroundColor,
              ],
            ),
          ),
        ),
        // Floating title + meta + primary action (clears the tab bar)
        Positioned(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: 78,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          film.name ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.displayLarge.copyWith(
                            fontSize: 28,
                            height: 1.05,
                            shadows: const [
                              Shadow(
                                color: Colors.black54,
                                offset: Offset(0, 2),
                                blurRadius: 12,
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
                      ],
                    ),
                  ),
                  if (_findVideoUrl(film) != null) ...[
                    const SizedBox(width: AppSpacing.md),
                    HeroCircleButton(
                      icon: Icons.play_arrow_rounded,
                      primary: true,
                      size: 52,
                      iconSize: 28,
                      onTap: () => _onPlayTap(film),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _HeroMetaLine(film: film),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGlassTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.surfaceColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primaryValue,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              labelColor: AppColors.primaryValue,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: AppTypography.labelMedium,
              unselectedLabelStyle: AppTypography.labelMedium,
              tabs: const [
                Tab(text: 'Thông tin'),
                Tab(text: 'Tập phim'),
              ],
            ),
          ),
        ),
      ),
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
                const SizedBox(width: AppSpacing.md),
                AppButton(label: 'Xem ngay', onPressed: () => _onPlayTap(film)),
              ],
            ),
          ),
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
