import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';

class TvHomePage extends ConsumerStatefulWidget {
  const TvHomePage({super.key});

  @override
  ConsumerState<TvHomePage> createState() => _TvHomePageState();
}

class _TvHomePageState extends ConsumerState<TvHomePage> {
  int _selectedTypeIndex = 0;
  int _focusedCardIndex = -1;

  @override
  Widget build(BuildContext context) {
    final typeSlug = AppConstants.filmTypes[_selectedTypeIndex]['slug']!;
    final filmsAsync = ref.watch(
      filmsByTypeProvider((typeSlug: typeSlug, page: 1, sortField: null, year: null)),
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Row(
        children: [
          // Left sidebar - categories
          SizedBox(
            width: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'TMOVIE',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: AppConstants.filmTypes.length,
                    itemBuilder: (context, index) {
                      final isSelected = index == _selectedTypeIndex;
                      return Focus(
                        onKeyEvent: (node, event) {
                          if (event is KeyDownEvent &&
                              event.logicalKey == LogicalKeyboardKey.select) {
                            setState(() => _selectedTypeIndex = index);
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        child: Builder(
                          builder: (context) {
                            final hasFocus = Focus.of(context).hasFocus;
                            return Container(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.2)
                                  : hasFocus
                                      ? AppColors.surfaceColor
                                      : Colors.transparent,
                              child: ListTile(
                                title: Text(
                                  AppConstants.filmTypes[index]['title']!,
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                onTap: () =>
                                    setState(() => _selectedTypeIndex = index),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                // Search button
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/search'),
                    icon: const Icon(Icons.search, color: Colors.white),
                    label: const Text('Tìm kiếm',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Container(width: 1, color: AppColors.surfaceColor),
          // Main content
          Expanded(
            child: filmsAsync.when(
              data: (response) {
                final items = response.data?.items ?? [];
                if (items.isEmpty) {
                  return const Center(
                    child: Text('Không có phim',
                        style: TextStyle(color: Colors.white)),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    childAspectRatio: 0.6,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final film = items[index];
                    return Focus(
                      onFocusChange: (hasFocus) {
                        setState(() =>
                            _focusedCardIndex = hasFocus ? index : -1);
                      },
                      onKeyEvent: (node, event) {
                        if (event is KeyDownEvent &&
                            event.logicalKey == LogicalKeyboardKey.select) {
                          context.push('/detail/${film.slug}');
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        transform: _focusedCardIndex == index
                            ? Matrix4.diagonal3Values(1.05, 1.05, 1.0)
                            : Matrix4.identity(),
                        transformAlignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: _focusedCardIndex == index
                              ? Border.all(color: AppColors.primary, width: 3)
                              : null,
                        ),
                        child: GestureDetector(
                          onTap: () =>
                              context.push('/detail/${film.slug}'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: AppImage(
                                    imageUrl: film.fullThumbUrl,
                                    boxFit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                film.name ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (film.episodeCurrent != null)
                                Text(
                                  film.episodeCurrent!,
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 10,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: ElevatedButton(
                  onPressed: () => ref.invalidate(
                    filmsByTypeProvider((typeSlug: typeSlug, page: 1, sortField: null, year: null)),
                  ),
                  child: const Text('Thử lại'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
