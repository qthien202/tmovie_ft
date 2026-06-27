import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:core/core.dart';
import '../../shared/desktop_design_system.dart';

class DesktopPlayerPage extends ConsumerStatefulWidget {
  final String videoUrl;
  final String filmName;
  final String episode;
  final String slug;
  final List<Episode> episodes;

  const DesktopPlayerPage({
    super.key,
    required this.videoUrl,
    required this.filmName,
    required this.episode,
    required this.slug,
    required this.episodes,
  });

  @override
  ConsumerState<DesktopPlayerPage> createState() => _DesktopPlayerPageState();
}

class _DesktopPlayerPageState extends ConsumerState<DesktopPlayerPage> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _showEpisodes = false;
  bool _showOverlay = true;
  int _selectedServerIndex = 0;
  Timer? _hideTimer;

  List<ServerData> get _currentEpisodes =>
      widget.episodes.isNotEmpty
          ? widget.episodes[_selectedServerIndex].serverData ?? []
          : [];

  @override
  void initState() {
    super.initState();
    _initPlayer(widget.videoUrl);
    _startHideTimer();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_showEpisodes) {
        setState(() => _showOverlay = false);
      }
    });
  }

  void _onMouseMove() {
    if (!_showOverlay) {
      setState(() => _showOverlay = true);
    }
    _startHideTimer();
  }

  void _initPlayer(String url) {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
    _videoController.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _videoController,
          autoPlay: true,
          aspectRatio: _videoController.value.aspectRatio,
          allowFullScreen: true,
          allowMuting: true,
          showControlsOnInitialize: false,
        );
      });
      _saveHistory();
    });
  }

  void _saveHistory() {
    final historyRepo = ref.read(historyRepositoryProvider);
    historyRepo.addHistory(WatchHistoryEntry(
      slug: widget.slug,
      name: widget.filmName,
      episode: widget.episode,
      thumbUrl: null,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  void _switchEpisode(ServerData ep) {
    _chewieController?.dispose();
    _videoController.dispose();

    setState(() => _chewieController = null);

    _videoController =
        VideoPlayerController.networkUrl(Uri.parse(ep.linkM3u8 ?? ''));
    _videoController.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _videoController,
          autoPlay: true,
          aspectRatio: _videoController.value.aspectRatio,
          allowFullScreen: true,
          allowMuting: true,
          showControlsOnInitialize: false,
        );
      });
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _chewieController?.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape) {
            if (_showEpisodes) {
              setState(() => _showEpisodes = false);
            } else {
              context.pop();
            }
          }
        },
        child: MouseRegion(
          onHover: (_) => _onMouseMove(),
          child: Stack(
            children: [
              // Video Player - full screen, no obstruction
              Positioned.fill(
                child: _chewieController != null
                    ? Chewie(controller: _chewieController!)
                    : const Center(
                        child:
                            CircularProgressIndicator(color: DS.primary),
                      ),
              ),

              // Top bar - auto-hide, doesn't block video interaction
              if (_showOverlay)
                Positioned(
                  top: 0,
                  left: 0,
                  right: _showEpisodes ? 300 : 0,
                  child: IgnorePointer(
                    ignoring: false,
                    child: AnimatedOpacity(
                      opacity: _showOverlay ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(8, 8, 16, 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => context.pop(),
                              icon: const Icon(Icons.arrow_back_rounded,
                                  color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${widget.filmName} - ${widget.episode}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.episodes.isNotEmpty)
                              TextButton.icon(
                                onPressed: () {
                                  setState(
                                      () => _showEpisodes = !_showEpisodes);
                                  if (_showEpisodes) {
                                    _hideTimer?.cancel();
                                  } else {
                                    _startHideTimer();
                                  }
                                },
                                icon: Icon(
                                  _showEpisodes
                                      ? Icons.close_rounded
                                      : Icons.list_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                label: Text(
                                  _showEpisodes ? 'Dong' : 'Danh sach tap',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 13),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Episode list panel
              if (_showEpisodes)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: 300,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.9),
                      border: Border(
                        left: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Close button
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 8, 0),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Danh sach tap',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() => _showEpisodes = false);
                                  _startHideTimer();
                                },
                                icon: const Icon(Icons.close_rounded,
                                    color: Colors.white70, size: 20),
                              ),
                            ],
                          ),
                        ),
                        // Server tabs
                        if (widget.episodes.length > 1)
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(12, 8, 12, 8),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: List.generate(
                                  widget.episodes.length,
                                  (i) {
                                    final isActive =
                                        i == _selectedServerIndex;
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(right: 6),
                                      child: ChoiceChip(
                                        label: Text(
                                          widget.episodes[i].serverName ??
                                              'Server ${i + 1}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isActive
                                                ? Colors.white
                                                : DS.textMuted,
                                          ),
                                        ),
                                        selected: isActive,
                                        onSelected: (_) => setState(
                                            () => _selectedServerIndex = i),
                                        selectedColor: DS.primary,
                                        backgroundColor: DS.surfaceLight,
                                        side: BorderSide.none,
                                        visualDensity:
                                            VisualDensity.compact,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        const Divider(
                          color: Colors.white12,
                          height: 1,
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            itemCount: _currentEpisodes.length,
                            itemBuilder: (context, index) {
                              final ep = _currentEpisodes[index];
                              final isCurrent =
                                  ep.name == widget.episode;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 2),
                                child: Material(
                                  color: isCurrent
                                      ? DS.primary
                                          .withValues(alpha: 0.15)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(
                                      DS.radiusSm),
                                  child: InkWell(
                                    onTap: () => _switchEpisode(ep),
                                    borderRadius:
                                        BorderRadius.circular(
                                            DS.radiusSm),
                                    hoverColor: DS.primary
                                        .withValues(alpha: 0.1),
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      child: Row(
                                        children: [
                                          if (isCurrent)
                                            const Icon(
                                                Icons
                                                    .play_arrow_rounded,
                                                color: DS.primary,
                                                size: 18)
                                          else
                                            Text(
                                              '${index + 1}',
                                              style: const TextStyle(
                                                color: DS.textMuted,
                                                fontSize: 13,
                                              ),
                                            ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              ep.name ??
                                                  'Tap ${index + 1}',
                                              style: TextStyle(
                                                color: isCurrent
                                                    ? DS.primary
                                                    : Colors.white,
                                                fontSize: 13,
                                                fontWeight: isCurrent
                                                    ? FontWeight.w600
                                                    : FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
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
