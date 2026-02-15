import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';

import '../../shared/tv_design_system.dart';

class TvSeasonPage extends ConsumerStatefulWidget {
  final String slug;
  final String filmName;
  final String thumbUrl;
  final List<Episode> episodes;

  const TvSeasonPage({
    super.key,
    required this.slug,
    required this.filmName,
    required this.thumbUrl,
    required this.episodes,
  });

  @override
  ConsumerState<TvSeasonPage> createState() => _TvSeasonPageState();
}

class _TvSeasonPageState extends ConsumerState<TvSeasonPage> {
  int _selectedServerIndex = 0;

  List<ServerData> get _currentEpisodes =>
      widget.episodes[_selectedServerIndex].serverData ?? [];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

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
            Navigator.of(context).pop();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: FocusTraversalGroup(
          policy: ReadingOrderTraversalPolicy(),
          child: Stack(
            children: [
              // Subtle gradient background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      TvDesignSystem.surface.withValues(alpha: 0.5),
                      TvDesignSystem.background,
                    ],
                    stops: const [0.0, 0.3],
                  ),
                ),
              ),
              Row(
                children: [
                  // ─── LEFT PANEL: Poster + Title + Season ───
                  SizedBox(
                    width: screenWidth * 0.30,
                    child: _buildLeftPanel(),
                  ),

                  // Divider
                  Container(
                    width: 1,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),

                  // ─── RIGHT PANEL: Episode List ───
                  Expanded(
                    child: _buildRightPanel(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Padding(
      padding: EdgeInsets.all(TvDesignSystem.overscanMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Poster thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(TvDesignSystem.radiusMd),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: AppImage(
                imageUrl: widget.thumbUrl,
                boxFit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Film name
          Text(
            widget.filmName,
            style: TvDesignSystem.headlineLarge,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),

          // Server/Season selector
          if (widget.episodes.length > 1) ...[
            const SizedBox(height: 8),
            FocusTraversalGroup(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (int i = 0; i < widget.episodes.length; i++)
                    _buildServerChip(i),
                ],
              ),
            ),
          ] else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(TvDesignSystem.radiusSm),
              ),
              child: Text(
                widget.episodes.first.serverName ?? 'Season 1',
                style: TvDesignSystem.bodyMedium,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildServerChip(int index) {
    final isSelected = index == _selectedServerIndex;
    final serverName =
        widget.episodes[index].serverName ?? 'Server ${index + 1}';

    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter) {
            setState(() => _selectedServerIndex = index);
            return KeyEventResult.handled;
          }
          // Arrow-right from server chip → move to episode list
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            FocusManager.instance.primaryFocus
                ?.focusInDirection(TraversalDirection.right);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;
          return AnimatedScale(
            scale: hasFocus ? 1.05 : 1.0,
            duration: TvDesignSystem.durationFast,
            curve: TvDesignSystem.curveFluid,
            child: AnimatedContainer(
              duration: TvDesignSystem.durationFast,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? TvDesignSystem.primary
                    : hasFocus
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.06),
                borderRadius:
                    BorderRadius.circular(TvDesignSystem.radiusSm),
                border: Border.all(
                  color: isSelected
                      ? TvDesignSystem.primary
                      : hasFocus
                          ? Colors.white.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.08),
                  width: hasFocus ? 2 : 1,
                ),
              ),
              child: Text(
                serverName,
                style: TextStyle(
                  color: isSelected || hasFocus
                      ? Colors.white
                      : Colors.white54,
                  fontSize: 16,
                  fontWeight:
                      isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRightPanel() {
    final episodes = _currentEpisodes;

    if (episodes.isEmpty) {
      return Center(
        child: Text(
          'Không có tập nào',
          style: TvDesignSystem.titleLarge.copyWith(
            color: Colors.white.withValues(alpha: 0.3),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(
        horizontal: TvDesignSystem.overscanMargin,
        vertical: TvDesignSystem.overscanMargin,
      ),
      itemCount: episodes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final ep = episodes[index];
        return _SeasonEpisodeRow(
          index: index + 1,
          episode: ep,
          filmThumbUrl: widget.thumbUrl,
          autofocus: index == 0,
          onTap: () => _playEpisode(ep),
        );
      },
    );
  }

  void _playEpisode(ServerData ep) {
    final videoUrl = ep.linkM3u8 ?? ep.linkEmbed ?? '';
    if (videoUrl.isEmpty) return;

    ref.read(historyRepositoryProvider).addHistory(
          WatchHistoryEntry(
            slug: widget.slug,
            name: widget.filmName,
            thumbUrl: widget.thumbUrl,
            episode: ep.name,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          ),
        );
    ref.invalidate(watchHistoryProvider);

    context.push('/player', extra: {
      'videoUrl': videoUrl,
      'filmName': widget.filmName,
      'episode': ep.name ?? '',
      'slug': widget.slug,
      'episodes': widget.episodes,
    });
  }
}

// ─── Episode Row (iQIYI style) ───────────────────────────────

class _SeasonEpisodeRow extends StatelessWidget {
  final int index;
  final ServerData episode;
  final String filmThumbUrl;
  final bool autofocus;
  final VoidCallback onTap;

  const _SeasonEpisodeRow({
    required this.index,
    required this.episode,
    required this.filmThumbUrl,
    required this.onTap,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: autofocus,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter) {
            onTap();
            return KeyEventResult.handled;
          }
          // Arrow-left from episode row → move to left panel
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            FocusManager.instance.primaryFocus
                ?.focusInDirection(TraversalDirection.left);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;
          return AnimatedContainer(
            duration: TvDesignSystem.durationFast,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: hasFocus
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(TvDesignSystem.radiusMd),
              border: Border.all(
                color: hasFocus
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                // Large landscape thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 280,
                    height: 158,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AppImage(
                          imageUrl: filmThumbUrl,
                          boxFit: BoxFit.cover,
                        ),
                        // Play overlay on focus
                        if (hasFocus)
                          Container(
                            color: Colors.black.withValues(alpha: 0.4),
                            child: const Center(
                              child: Icon(
                                Icons.play_circle_filled_rounded,
                                color: Colors.white,
                                size: 52,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 28),

                // Metadata column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Episode label
                      Text(
                        'S1 Ep$index',
                        style: TextStyle(
                          color: hasFocus
                              ? TvDesignSystem.primary
                              : Colors.white54,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Episode name
                      Text(
                        episode.name ?? 'Tập $index',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight:
                              hasFocus ? FontWeight.w800 : FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Filename / subtitle
                      if (episode.filename != null &&
                          episode.filename!.isNotEmpty)
                        Text(
                          episode.filename!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 15,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),

                // Chevron on focus
                if (hasFocus)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white38,
                    size: 32,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
