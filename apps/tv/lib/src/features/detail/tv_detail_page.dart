import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:catalog/catalog.dart';
import 'package:detail/detail.dart';
import 'package:media_library/media_library.dart';
import '../../shared/widgets/tv_shelf.dart';
import '../../shared/widgets/tv_focus_button.dart';
import '../../shared/tv_design_system.dart';

class TvDetailPage extends ConsumerStatefulWidget {
  final String slug;
  const TvDetailPage({super.key, required this.slug});

  @override
  ConsumerState<TvDetailPage> createState() => _TvDetailPageState();
}

class _TvDetailPageState extends ConsumerState<TvDetailPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(filmDetailProvider(widget.slug));
    final isFavAsync = ref.watch(isFavoriteProvider(widget.slug));

    return Scaffold(
      backgroundColor: TvDesignSystem.background,
      body: Focus(
        skipTraversal: true,
        canRequestFocus: false,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.goBack ||
                  event.logicalKey == LogicalKeyboardKey.escape ||
                  event.logicalKey == LogicalKeyboardKey.backspace)) {
            context.pop();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: detailAsync.when(
          data: (response) {
            final film = response.data?.item;
            if (film == null) return _buildErrorState('Phim không tồn tại');
            return _buildContent(film, isFavAsync);
          },
          loading: () => _buildLoading(),
          error: (err, _) => _buildErrorState('Lỗi kết nối máy chủ'),
        ),
      ),
    );
  }

  Widget _buildContent(FilmDetail film, AsyncValue<bool> isFavAsync) {
    final screenHeight = MediaQuery.of(context).size.height;

    return FocusTraversalGroup(
      policy: ReadingOrderTraversalPolicy(),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ─── HERO SECTION ──────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: screenHeight * 0.88,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Backdrop image
                  AppImage(imageUrl: film.fullThumbUrl, boxFit: BoxFit.cover),
                  // Gradient overlays
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.3),
                          Colors.black.withValues(alpha: 0.85),
                          TvDesignSystem.background,
                        ],
                        stops: const [0.0, 0.3, 0.7, 1.0],
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withValues(alpha: 0.7),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.6],
                      ),
                    ),
                  ),

                  // Back button (top-left)
                  Positioned(
                    top: 40,
                    left: 48,
                    child: TvFocusButton(
                      icon: Icons.arrow_back_rounded,
                      onPressed: () => context.pop(),
                    ),
                  ),

                  // Hero content
                  Positioned(
                    left: 80,
                    bottom: 80,
                    right: MediaQuery.of(context).size.width * 0.15,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Meta chips (category + year)
                        if (film.category != null &&
                            film.category!.isNotEmpty) ...[
                          Row(
                            children: [
                              Text(
                                film.category!
                                    .take(2)
                                    .map((c) => c.name ?? '')
                                    .join('  ·  '),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (film.year != null) ...[
                                Text(
                                  '   ${film.year}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Film title
                        Text(
                          film.name ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 56,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                            letterSpacing: -1,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 24),

                        // Description
                        if (film.content != null &&
                            film.content!.isNotEmpty) ...[
                          Text(
                            _stripHtml(film.content!),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 18,
                              height: 1.5,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 36),
                        ],

                        // Action buttons
                        FocusTraversalGroup(
                          child: Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              TvFocusButton(
                                icon: Icons.play_arrow_rounded,
                                label: 'XEM PHIM',
                                isPrimary: true,
                                autofocus: true,
                                onPressed: () {
                                  final firstEp = film
                                      .episodes
                                      ?.firstOrNull
                                      ?.serverData
                                      ?.firstOrNull;
                                  if (firstEp != null) {
                                    _playEpisode(context, film, firstEp);
                                  }
                                },
                              ),
                              if (_hasMultipleEpisodes(film))
                                TvFocusButton(
                                  icon: Icons.layers_rounded,
                                  label: 'TẬP PHIM',
                                  onPressed: () => context.push(
                                    '/season/${widget.slug}',
                                    extra: {
                                      'filmName': film.name ?? '',
                                      'thumbUrl': film.fullThumbUrl,
                                      'episodes': film.episodes!,
                                    },
                                  ),
                                ),
                              TvFocusButton(
                                icon: isFavAsync.valueOrNull == true
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                label: isFavAsync.valueOrNull == true
                                    ? 'ĐÃ THÍCH'
                                    : 'YÊU THÍCH',
                                onPressed: () => _toggleFavorite(
                                  film,
                                  isFavAsync.valueOrNull == true,
                                ),
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

          // ─── CAST & CREW ───────────────────────────────
          ..._buildCastSection(film),

          // ─── RELATED ───────────────────────────────────
          ..._buildRelatedSection(film),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // ─── CAST & CREW ─────────────────────────────────────────────

  List<Widget> _buildCastSection(FilmDetail film) {
    final peoplesAsync = ref.watch(filmPeoplesProvider(widget.slug));

    return [
      peoplesAsync.when(
        data: (res) {
          final peoples = res.data?.peoples ?? [];
          final profileBaseUrl = res.data?.profileSizes?.w185 ?? '';
          final actors = peoples
              .where((p) => p.knownForDepartment == 'Acting')
              .take(15)
              .toList();

          if (actors.isEmpty)
            return const SliverToBoxAdapter(child: SizedBox.shrink());

          return SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(80, 40, 80, 24),
                  child: Text(
                    'Cast & Crew',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SizedBox(
                  height: 200,
                  child: FocusTraversalGroup(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 80),
                      scrollDirection: Axis.horizontal,
                      itemCount: actors.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 28),
                      itemBuilder: (context, index) {
                        return _ActorCard(
                          person: actors[index],
                          profileBaseUrl: profileBaseUrl,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
        error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      ),
    ];
  }

  // ─── RELATED ─────────────────────────────────────────────────

  List<Widget> _buildRelatedSection(FilmDetail film) {
    final relatedSlug = film.category?.firstOrNull?.slug ?? 'phim-le';
    final filmsAsync = ref.watch(
      filmsByTypeProvider((
        typeSlug: relatedSlug,
        page: 1,
        sortField: null,
        year: null,
      )),
    );

    return [
      filmsAsync.when(
        data: (res) {
          final items = res.data?.items ?? [];
          final filtered = items
              .where((f) => f.slug != widget.slug)
              .take(12)
              .toList();
          if (filtered.isEmpty) {
            return const SliverToBoxAdapter(child: SizedBox.shrink());
          }
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: TvShelf(
                title: 'Nếu bạn thích ${film.name ?? ''}',
                items: filtered,
                onFilmTap: (f) => context.push('/detail/${f.slug}'),
              ),
            ),
          );
        },
        loading: () => const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(
              child: CircularProgressIndicator(color: TvDesignSystem.primary),
            ),
          ),
        ),
        error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      ),
    ];
  }

  // ─── ACTIONS ─────────────────────────────────────────────────

  void _playEpisode(
    BuildContext context,
    FilmDetail film,
    ServerData serverData,
  ) {
    final videoUrl = serverData.linkM3u8 ?? serverData.linkEmbed ?? '';
    if (videoUrl.isEmpty) return;

    ref
        .read(historyRepositoryProvider)
        .addHistory(
          WatchHistoryEntry(
            slug: widget.slug,
            name: film.name ?? '',
            originName: film.originName,
            thumbUrl: film.fullThumbUrl,
            episode: serverData.name,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          ),
        );
    ref.invalidate(watchHistoryProvider);

    context.push(
      '/player',
      extra: {
        'videoUrl': videoUrl,
        'filmName': film.name ?? '',
        'episode': serverData.name ?? '',
        'slug': widget.slug,
        'episodes': film.episodes!,
      },
    );
  }

  void _toggleFavorite(FilmDetail film, bool isFav) async {
    final favRepo = ref.read(favoritesRepositoryProvider);
    if (isFav) {
      await favRepo.removeFavorite(widget.slug);
    } else {
      await favRepo.addFavorite(
        WatchHistoryEntry(
          slug: widget.slug,
          name: film.name ?? '',
          originName: film.originName,
          thumbUrl: film.fullThumbUrl,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }
    ref.invalidate(isFavoriteProvider(widget.slug));
    ref.invalidate(favoritesProvider);
  }

  // ─── STATES ──────────────────────────────────────────────────

  Widget _buildLoading() {
    return Container(
      color: TvDesignSystem.background,
      child: const Center(
        child: CircularProgressIndicator(color: TvDesignSystem.primary),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 48),
          TvFocusButton(
            icon: Icons.refresh_rounded,
            label: 'THỬ LẠI',
            isPrimary: true,
            onPressed: () => ref.invalidate(filmDetailProvider(widget.slug)),
          ),
        ],
      ),
    );
  }

  bool _hasMultipleEpisodes(FilmDetail film) {
    final eps = film.episodes;
    if (eps == null || eps.isEmpty) return false;
    final serverData = eps.first.serverData ?? [];
    return serverData.length > 1;
  }

  String _stripHtml(String html) => html.replaceAll(RegExp(r'<[^>]*>'), '');
}

// ─── ACTOR CARD (Circle Avatar) ──────────────────────────────

class _ActorCard extends StatelessWidget {
  final FilmPerson person;
  final String profileBaseUrl;
  const _ActorCard({required this.person, required this.profileBaseUrl});

  @override
  Widget build(BuildContext context) {
    final hasProfile =
        person.profilePath != null && person.profilePath!.isNotEmpty;
    final imageUrl = hasProfile ? '$profileBaseUrl${person.profilePath}' : '';

    return Focus(
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;
          return AnimatedScale(
            scale: hasFocus ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutQuart,
            child: SizedBox(
              width: 120,
              child: Column(
                children: [
                  // Avatar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: hasFocus
                            ? TvDesignSystem.primary
                            : Colors.white.withValues(alpha: 0.1),
                        width: hasFocus ? 3 : 2,
                      ),
                    ),
                    child: ClipOval(
                      child: hasProfile
                          ? AppImage(imageUrl: imageUrl, boxFit: BoxFit.cover)
                          : Container(
                              color: Colors.white.withValues(alpha: 0.08),
                              child: Icon(
                                Icons.person_rounded,
                                color: Colors.white.withValues(alpha: 0.3),
                                size: 48,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Name
                  Text(
                    person.name ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: hasFocus ? Colors.white : Colors.white70,
                      fontSize: 15,
                      fontWeight: hasFocus ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  // Character
                  if (person.character != null &&
                      person.character!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      person.character!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
