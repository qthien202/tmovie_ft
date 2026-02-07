import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';
import 'widgets/film_carousel.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: AppConstants.filmTypes.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppColors.backgroundColor,
            title: Text(
              'TMOVIE',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppColors.primary,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              tabAlignment: TabAlignment.start,
              tabs: AppConstants.filmTypes.map((type) {
                return Tab(text: type['title']);
              }).toList(),
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: AppConstants.filmTypes.map((type) {
          return _FilmTypeTab(typeSlug: type['slug']!);
        }).toList(),
      ),
    );
  }
}

class _FilmTypeTab extends ConsumerStatefulWidget {
  final String typeSlug;
  const _FilmTypeTab({required this.typeSlug});

  @override
  ConsumerState<_FilmTypeTab> createState() => _FilmTypeTabState();
}

class _FilmTypeTabState extends ConsumerState<_FilmTypeTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final filmsAsync = ref.watch(
      filmsByTypeProvider((typeSlug: widget.typeSlug, page: 1)),
    );

    return filmsAsync.when(
      data: (response) {
        final items = response.data?.items ?? [];
        if (items.isEmpty) {
          return const Center(
            child: Text('Không có phim', style: TextStyle(color: Colors.white)),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(filmsByTypeProvider((typeSlug: widget.typeSlug, page: 1)));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                FilmCarousel(films: items.take(6).toList()),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Danh sách',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push(
                          '/film-list/${widget.typeSlug}',
                          extra: {'title': widget.typeSlug},
                        ),
                        child: Text('Xem thêm', style: TextStyle(color: AppColors.primary)),
                      ),
                    ],
                  ),
                ),
                FilmGrid(
                  films: items,
                  onFilmTap: (film) => context.push('/detail/${film.slug}'),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Có lỗi xảy ra', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.invalidate(
                filmsByTypeProvider((typeSlug: widget.typeSlug, page: 1)),
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
