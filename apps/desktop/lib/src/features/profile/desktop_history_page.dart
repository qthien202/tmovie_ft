import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';
import 'package:media_library/media_library.dart';
import '../../shared/desktop_design_system.dart';
import '../../shared/widgets/desktop_film_card.dart';

class DesktopHistoryPage extends ConsumerWidget {
  const DesktopHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(watchHistoryProvider);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Vừa xem',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              historyAsync.whenOrNull(
                    data: (entries) => entries.isNotEmpty
                        ? TextButton.icon(
                            onPressed: () async {
                              await ref
                                  .read(historyRepositoryProvider)
                                  .clearHistory();
                              ref.invalidate(watchHistoryProvider);
                            },
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 18, color: DS.textMuted),
                            label: const Text('Xóa tất cả',
                                style: TextStyle(
                                    color: DS.textMuted, fontSize: 13)),
                          )
                        : null,
                  ) ??
                  const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: historyAsync.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return _buildEmpty();
                }
                final items = entries
                    .map((e) => FilmItem(
                          slug: e.slug,
                          name: e.name,
                          originName: e.originName,
                          thumbUrl: e.thumbUrl,
                          episodeCurrent: e.episode,
                        ))
                    .toList();
                return GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    childAspectRatio: DS.cardAspectRatio * 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return DesktopFilmCard(
                      film: items[index],
                      onTap: () =>
                          context.push('/detail/${items[index].slug}'),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: DS.primary),
              ),
              error: (_, _) => const Center(
                child: Text('Lỗi tải dữ liệu',
                    style: TextStyle(color: DS.textMuted)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded,
              size: 64, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text(
            'Chưa có lịch sử xem',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
