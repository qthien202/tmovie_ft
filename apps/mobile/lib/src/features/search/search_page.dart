import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _keyword = '';
  int _currentPage = 1;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (value.trim().isNotEmpty) {
        setState(() {
          _keyword = value.trim();
          _currentPage = 1;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _controller,
                onChanged: _onSearchChanged,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm phim...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _controller.clear();
                            setState(() {
                              _keyword = '';
                              _currentPage = 1;
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _keyword.isEmpty
                  ? const Center(
                      child: Text(
                        'Nhập từ khóa để tìm kiếm',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : _SearchResults(
                      keyword: _keyword,
                      page: _currentPage,
                      onPageChanged: (page) {
                        setState(() => _currentPage = page);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResults extends ConsumerWidget {
  final String keyword;
  final int page;
  final ValueChanged<int> onPageChanged;

  const _SearchResults({
    required this.keyword,
    required this.page,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchAsync = ref.watch(
      searchFilmsProvider((keyword: keyword, page: page)),
    );

    return searchAsync.when(
      data: (response) {
        final items = response.data?.items ?? [];
        if (items.isEmpty) {
          return const Center(
            child: Text(
              'Không tìm thấy phim',
              style: TextStyle(color: Colors.white),
            ),
          );
        }
        final pagination = response.data?.params?.pagination;
        final totalPages = pagination?.totalPages ?? 1;

        return Column(
          children: [
            Expanded(
              child: FilmGrid(
                films: items,
                onFilmTap: (film) => context.push('/detail/${film.slug}'),
              ),
            ),
            if (totalPages > 1)
              PaginationBar(
                currentPage: page,
                totalPages: totalPages,
                onPageChanged: onPageChanged,
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Có lỗi xảy ra', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.invalidate(
                searchFilmsProvider((keyword: keyword, page: page)),
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
