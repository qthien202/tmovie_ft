import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';

/// Episode list: a server selector + a compact grid of "Tập N" tiles — every
/// episode visible at a glance and tappable directly (no long horizontal
/// scroll), which scales to series with dozens of episodes.
class EpisodesRail extends StatefulWidget {
  final List<Episode> episodes;
  final String filmName;
  final String slug;
  final String thumbUrl;
  final String? currentEpisode;
  final void Function(ServerData episode)? onEpisodeTap;

  const EpisodesRail({
    super.key,
    required this.episodes,
    required this.filmName,
    required this.slug,
    required this.thumbUrl,
    this.currentEpisode,
    this.onEpisodeTap,
  });

  @override
  State<EpisodesRail> createState() => _EpisodesRailState();
}

class _EpisodesRailState extends State<EpisodesRail> {
  int _server = 0;

  void _open(ServerData ep) {
    final url = ep.linkM3u8 ?? ep.linkEmbed ?? '';
    if (url.isEmpty) return;
    widget.onEpisodeTap?.call(ep);
    context.push(
      '/player',
      extra: {
        'videoUrl': url,
        'filmName': widget.filmName,
        'episode': ep.name ?? '',
        'slug': widget.slug,
        'episodes': widget.episodes,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final servers = widget.episodes;
    if (servers.isEmpty) return const SizedBox.shrink();
    final list = servers[_server].serverData ?? [];
    if (list.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 0),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primaryValue,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('Tập phim', style: AppTypography.titleLarge),
              const Spacer(),
              Text(
                '${list.length} tập',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),

        // Server selector (only when there are multiple servers).
        if (servers.length > 1) ...[
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: servers.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, i) {
                final selected = i == _server;
                return GestureDetector(
                  onTap: () => setState(() => _server = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primaryValue
                          : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: selected
                            ? Colors.transparent
                            : AppColors.border,
                      ),
                    ),
                    child: Text(
                      servers[i].serverName ?? 'Server ${i + 1}',
                      style: AppTypography.labelMedium.copyWith(
                        color: selected
                            ? AppColors.onPrimary
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1.7,
            ),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final ep = list[i];
              final url = ep.linkM3u8 ?? ep.linkEmbed ?? '';
              final label = _tileLabel(ep.name, i + 1);
              return _EpisodeTile(
                label: label,
                disabled: url.isEmpty,
                isCurrent: ep.name == widget.currentEpisode,
                onTap: url.isEmpty ? null : () => _open(ep),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Prefer a short numeric label; fall back to the position. Long names get
  /// truncated by the tile itself.
  String _tileLabel(String? name, int position) {
    final t = (name ?? '').trim();
    if (t.isEmpty) return '$position';
    return t;
  }
}

class _EpisodeTile extends StatelessWidget {
  final String label;
  final bool disabled;
  final bool isCurrent;
  final VoidCallback? onTap;

  const _EpisodeTile({
    required this.label,
    required this.disabled,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final Color borderColor;
    if (isCurrent) {
      bg = AppColors.primaryValue.withValues(alpha: 0.18);
      fg = AppColors.primaryValue;
      borderColor = AppColors.primaryValue;
    } else if (disabled) {
      bg = AppColors.surfaceElevated.withValues(alpha: 0.4);
      fg = AppColors.textTertiary;
      borderColor = AppColors.border;
    } else {
      bg = AppColors.surfaceElevated;
      fg = AppColors.textPrimary;
      borderColor = AppColors.border;
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isCurrent) ...[
                const Icon(
                  Icons.equalizer_rounded,
                  size: 13,
                  color: AppColors.primaryValue,
                ),
                const SizedBox(width: 3),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTypography.labelMedium.copyWith(
                    color: fg,
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
