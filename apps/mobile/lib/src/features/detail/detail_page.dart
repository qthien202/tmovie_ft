import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';
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

  void _onPlayTap(FilmDetail film) {
    if (film.episodes != null &&
        film.episodes!.isNotEmpty &&
        film.episodes!.first.serverData != null &&
        film.episodes!.first.serverData!.isNotEmpty) {
      final ep = film.episodes!.first.serverData!.first;
      final videoUrl = ep.linkM3u8 ?? ep.linkEmbed ?? '';
      if (videoUrl.isNotEmpty) {
        context.push(
          '/player',
          extra: {
            'videoUrl': videoUrl,
            'filmName': film.name ?? '',
            'episode': ep.name ?? '',
            'slug': film.slug ?? '',
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(filmDetailProvider(widget.slug));

    return Scaffold(
      backgroundColor: Colors.black,
      body: detailAsync.when(
        data: (response) {
          final film = response.data?.item;
          if (film == null) {
            return const Center(
              child: Text(
                'Không tìm thấy phim',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return Stack(
            children: [
              // 1. Static Cinematic Background
              Positioned.fill(
                child: AppImage(
                  imageUrl: film.fullThumbUrl,
                  boxFit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.black.withValues(alpha: 0.7),
                          Colors.black,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Main Scroll Content
              CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // App Bar with Poster & Tab Selection
                  SliverAppBar(
                    expandedHeight: MediaQuery.of(context).size.height * 0.6,
                    pinned: true,
                    stretch: true,
                    backgroundColor: Colors.black.withValues(alpha: 0.5),
                    elevation: 0,
                    leadingWidth: 70,
                    leading: _buildGlassBackButton(),
                    flexibleSpace: FlexibleSpaceBar(
                      stretchModes: const [
                        StretchMode.zoomBackground,
                        StretchMode.blurBackground,
                      ],
                      background: _buildPosterSection(film),
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
                              ),
                      ),
                    ),
                  ),
                ],
              ),

              // 3. Floating Interactive CTA
              _buildStickyCTA(film),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Có lỗi xảy ra',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(filmDetailProvider(widget.slug)),
                child: const Text('Thử lại'),
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

  Widget _buildPosterSection(FilmDetail film) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AppImage(
          imageUrl: film.fullPosterUrl.isNotEmpty
              ? film.fullPosterUrl
              : film.fullThumbUrl,
          boxFit: BoxFit.cover,
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.4, 0.8, 1.0],
              colors: [
                Colors.black.withValues(alpha: 0.2),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.7),
                Colors.black,
              ],
            ),
          ),
        ),
        Positioned(
          left: 20,
          bottom: 110,
          child: Container(
            width: 105,
            height: 155,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.7),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: AppImage(
                imageUrl: film.fullPosterUrl,
                boxFit: BoxFit.cover,
              ),
            ),
          ),
        ),
        Positioned(right: 20, bottom: 110, child: _buildPlayButton(film)),
      ],
    );
  }

  Widget _buildPlayButton(FilmDetail film) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 25,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => _onPlayTap(film),
        icon: const Icon(Icons.play_arrow_rounded, size: 30),
        label: const Text(
          'XEM PHIM',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: 'THÔNG TIN'),
                Tab(text: 'TẬP PHIM'),
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
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AppImage(
                    imageUrl: film.fullPosterUrl,
                    width: 45,
                    height: 60,
                    boxFit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        film.name ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        film.episodeCurrent ?? 'Mới nhất',
                        style: TextStyle(
                          color: AppColors.primary.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _onPlayTap(film),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'XEM NGAY',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
