import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';

class EpisodeSelector extends StatefulWidget {
  final List<Episode> episodes;
  final String filmName;
  final String slug;

  const EpisodeSelector({
    super.key,
    required this.episodes,
    required this.filmName,
    required this.slug,
  });

  @override
  State<EpisodeSelector> createState() => _EpisodeSelectorState();
}

class _EpisodeSelectorState extends State<EpisodeSelector> {
  int _selectedServer = 0;

  @override
  Widget build(BuildContext context) {
    final servers = widget.episodes;
    if (servers.isEmpty) return const SizedBox.shrink();

    final currentServer = servers[_selectedServer];
    final episodes = currentServer.serverData ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Danh sách tập',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (servers.length > 1) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: servers.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final isSelected = index == _selectedServer;
                  return ChoiceChip(
                    label: Text(
                      servers[index].serverName ?? 'Server ${index + 1}',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surfaceColor,
                    side: BorderSide.none,
                    onSelected: (_) => setState(() => _selectedServer = index),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: episodes.map((ep) {
              final videoUrl = ep.linkM3u8 ?? ep.linkEmbed ?? '';
              return SizedBox(
                width: 70,
                height: 40,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceColor,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: videoUrl.isEmpty
                      ? null
                      : () => context.push(
                            '/player',
                            extra: {
                              'videoUrl': videoUrl,
                              'filmName': widget.filmName,
                              'episode': ep.name ?? '',
                              'slug': widget.slug,
                            },
                          ),
                  child: Text(
                    ep.name ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
