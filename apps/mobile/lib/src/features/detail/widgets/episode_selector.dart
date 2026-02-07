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
          const SizedBox(height: 12),
          // Tiêu đề và Server Selector
          Row(
            children: [
              const Text(
                'Danh sách tập',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (servers.length > 1) _buildServerDropdown(servers),
            ],
          ),

          const SizedBox(height: 20),

          // Episode Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.2,
            ),
            itemCount: episodes.length,
            itemBuilder: (context, index) {
              final ep = episodes[index];
              final videoUrl = ep.linkM3u8 ?? ep.linkEmbed ?? '';

              return InkWell(
                onTap: videoUrl.isEmpty
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
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Text(
                    ep.name ?? '',
                    style: TextStyle(
                      color: videoUrl.isEmpty ? Colors.white30 : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServerDropdown(List<Episode> servers) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedServer,
          dropdownColor: Colors.grey[900],
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white70,
          ),
          items: List.generate(servers.length, (index) {
            return DropdownMenuItem(
              value: index,
              child: Text(
                servers[index].serverName ?? 'Server ${index + 1}',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            );
          }),
          onChanged: (val) {
            if (val != null) setState(() => _selectedServer = val);
          },
        ),
      ),
    );
  }
}
