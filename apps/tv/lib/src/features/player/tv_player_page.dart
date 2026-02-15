import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:core/core.dart';
import '../../shared/tv_design_system.dart';
import '../../shared/widgets/tv_focus_button.dart';

class TvPlayerPage extends ConsumerStatefulWidget {
  final String videoUrl;
  final String filmName;
  final String episode;
  final String slug;
  final List<Episode> episodes;

  const TvPlayerPage({
    super.key,
    required this.videoUrl,
    required this.filmName,
    required this.episode,
    required this.slug,
    required this.episodes,
  });

  @override
  ConsumerState<TvPlayerPage> createState() => _TvPlayerPageState();
}

class _TvPlayerPageState extends ConsumerState<TvPlayerPage>
    with WidgetsBindingObserver {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _hasError = false;
  Timer? _positionSaveTimer;

  late String _currentVideoUrl;
  late String _currentEpisodeName;
  int _selectedServerIndex = 0;
  bool _showPlaylist = false;

  // Custom Controls State
  bool _controlsVisible = true;
  Timer? _hideTimer;
  BoxFit _videoFit = BoxFit.contain;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _currentVideoUrl = widget.videoUrl;
    _currentEpisodeName = widget.episode;
    _findCurrentServerIndex();
    _initializePlayer();
    _startHideTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _videoController?.pause();
      _saveCurrentPosition();
      if (mounted) setState(() => _controlsVisible = true);
    }
  }

  void _findCurrentServerIndex() {
    for (int i = 0; i < widget.episodes.length; i++) {
      final epData = widget.episodes[i].serverData ?? [];
      if (epData.any((e) => (e.linkM3u8 ?? e.linkEmbed) == _currentVideoUrl)) {
        _selectedServerIndex = i;
        break;
      }
    }
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _hasError = false;
      _chewieController = null;
    });

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(_currentVideoUrl),
    );

    try {
      await controller.initialize();

      // Restore saved playback position
      final repo = ref.read(historyRepositoryProvider);
      final savedPosition = await repo.getPlaybackPosition(
        widget.slug,
        _currentEpisodeName,
      );

      _videoController = controller;

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        allowFullScreen: false,
        showControls: false,
        startAt: savedPosition != null && savedPosition > 0
            ? Duration(seconds: savedPosition)
            : null,
        placeholder: Container(color: Colors.black),
        errorBuilder: (context, errorMessage) => _buildErrorView(),
      );

      // Save position periodically
      _positionSaveTimer?.cancel();
      _positionSaveTimer = Timer.periodic(
        const Duration(seconds: 10),
        (_) => _saveCurrentPosition(),
      );

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  Future<void> _saveCurrentPosition() async {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return;
    }
    final position = _videoController!.value.position.inSeconds;
    if (position <= 0) return;
    final repo = ref.read(historyRepositoryProvider);
    await repo.savePlaybackPosition(widget.slug, _currentEpisodeName, position);
  }

  void _switchEpisode(ServerData ep, int serverIndex) {
    final url = ep.linkM3u8 ?? ep.linkEmbed;
    if (url == null || url.isEmpty) return;

    if (url == _currentVideoUrl && _currentEpisodeName == ep.name) {
      setState(() => _showPlaylist = false);
      return;
    }

    _saveCurrentPosition();
    _videoController?.pause();

    _chewieController?.dispose();
    _videoController?.dispose();

    setState(() {
      _currentVideoUrl = url;
      _currentEpisodeName = ep.name ?? '';
      _selectedServerIndex = serverIndex;
      _showPlaylist = false;
      _controlsVisible = true;
    });

    _startHideTimer();

    final repo = ref.read(historyRepositoryProvider);
    repo.savePlaybackPosition(widget.slug, _currentEpisodeName, 0);
    repo.addHistory(
      WatchHistoryEntry(
        slug: widget.slug,
        name: widget.filmName,
        episode: _currentEpisodeName,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    ref.invalidate(watchHistoryProvider);

    _initializePlayer();
  }

  void _toggleControls() {
    if (_showPlaylist) {
      setState(() => _showPlaylist = false);
      _startHideTimer();
      return;
    }

    setState(() => _controlsVisible = !_controlsVisible);

    if (_controlsVisible) {
      _startHideTimer();
    } else {
      _hideTimer?.cancel();
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted &&
          !_showPlaylist &&
          _videoController?.value.isPlaying == true) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _positionSaveTimer?.cancel();
    _hideTimer?.cancel();

    if (_videoController != null && _videoController!.value.isInitialized) {
      _videoController!.pause();
      final position = _videoController!.value.position.inSeconds;
      if (position > 0) {
        final repo = ref.read(historyRepositoryProvider);
        repo.savePlaybackPosition(widget.slug, _currentEpisodeName, position);
      }
    }

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;

          final key = event.logicalKey;

          // D-pad SELECT or Enter → toggle controls
          if (key == LogicalKeyboardKey.select ||
              key == LogicalKeyboardKey.enter) {
            if (!_controlsVisible) {
              _toggleControls();
              return KeyEventResult.handled;
            }
            // If controls visible, toggle play/pause
            if (_videoController != null) {
              setState(() {
                if (_videoController!.value.isPlaying) {
                  _videoController!.pause();
                  _hideTimer?.cancel();
                } else {
                  _videoController!.play();
                  _startHideTimer();
                }
              });
              return KeyEventResult.handled;
            }
          }

          // D-pad LEFT → rewind 10s
          if (key == LogicalKeyboardKey.arrowLeft && !_showPlaylist) {
            if (_videoController != null) {
              final current = _videoController!.value.position;
              _videoController!.seekTo(current - const Duration(seconds: 10));
              setState(() => _controlsVisible = true);
              _startHideTimer();
              return KeyEventResult.handled;
            }
          }

          // D-pad RIGHT → forward 10s
          if (key == LogicalKeyboardKey.arrowRight && !_showPlaylist) {
            if (_videoController != null) {
              final current = _videoController!.value.position;
              _videoController!.seekTo(current + const Duration(seconds: 10));
              setState(() => _controlsVisible = true);
              _startHideTimer();
              return KeyEventResult.handled;
            }
          }

          // BACK key → close playlist or exit player
          if (key == LogicalKeyboardKey.goBack ||
              key == LogicalKeyboardKey.escape) {
            if (_showPlaylist) {
              setState(() => _showPlaylist = false);
              _startHideTimer();
              return KeyEventResult.handled;
            }
            Navigator.of(context).pop();
            return KeyEventResult.handled;
          }

          // MENU / contextMenu → toggle playlist
          if (key == LogicalKeyboardKey.contextMenu) {
            setState(() {
              _showPlaylist = !_showPlaylist;
              _controlsVisible = true;
            });
            return KeyEventResult.handled;
          }

          return KeyEventResult.ignored;
        },
        child: Stack(
          children: [
            // 1. Player Layer
            Positioned.fill(
              child: _hasError
                  ? _buildErrorView()
                  : _chewieController != null
                  ? FittedBox(
                      fit: _videoFit,
                      child: SizedBox(
                        width: _videoController!.value.size.width,
                        height: _videoController!.value.size.height,
                        child: Chewie(controller: _chewieController!),
                      ),
                    )
                  : const Center(
                      child: CircularProgressIndicator(
                        color: TvDesignSystem.primary,
                        strokeWidth: 3,
                      ),
                    ),
            ),

            // 2. Tap Surface
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleControls,
                behavior: HitTestBehavior.opaque,
              ),
            ),

            // 3. Custom Controls
            _buildCustomControls(),

            // 4. Playlist Sidebar
            if (_showPlaylist) _buildPlaylistOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomControls() {
    return AnimatedOpacity(
      opacity: _controlsVisible ? 1.0 : 0.0,
      duration: TvDesignSystem.durationMedium,
      child: IgnorePointer(
        ignoring: !_controlsVisible,
        child: Stack(
          children: [_buildTopHUD(), _buildCenterControls(), _buildBottomBar()],
        ),
      ),
    );
  }

  Widget _buildTopHUD() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 140,
        padding: const EdgeInsets.symmetric(horizontal: 48),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.9), Colors.transparent],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              TvFocusButton(
                icon: Icons.arrow_back_rounded,
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.filmName.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'NOW PLAYING: $_currentEpisodeName',
                      style: TextStyle(
                        color: TvDesignSystem.primary.withValues(alpha:0.9),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              TvFocusButton(
                icon: Icons.playlist_play_rounded,
                label: 'EPISODES',
                onPressed: () => setState(() {
                  _showPlaylist = true;
                  _controlsVisible = true;
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterControls() {
    final isPlaying = _videoController?.value.isPlaying ?? false;
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TvFocusButton(
            icon: Icons.replay_10_rounded,
            size: 80,
            onPressed: () {
              if (_videoController == null) return;
              final current = _videoController!.value.position;
              _videoController!.seekTo(current - const Duration(seconds: 10));
              _startHideTimer();
            },
          ),
          const SizedBox(width: 80),
          TvFocusButton(
            icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: 120,
            isPrimary: true,
            onPressed: () {
              setState(() {
                if (isPlaying) {
                  _videoController!.pause();
                  _hideTimer?.cancel();
                } else {
                  _videoController!.play();
                  _startHideTimer();
                }
              });
            },
          ),
          const SizedBox(width: 80),
          TvFocusButton(
            icon: Icons.forward_10_rounded,
            size: 80,
            onPressed: () {
              if (_videoController == null) return;
              final current = _videoController!.value.position;
              _videoController!.seekTo(current + const Duration(seconds: 10));
              _startHideTimer();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    if (_videoController == null) return const SizedBox();

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(48, 48, 48, 64),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.95), Colors.transparent],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            VideoProgressIndicator(
              _videoController!,
              allowScrubbing: true,
              padding: const EdgeInsets.symmetric(vertical: 20),
              colors: VideoProgressColors(
                playedColor: TvDesignSystem.primary,
                bufferedColor: Colors.white.withValues(alpha: 0.25),
                backgroundColor: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            Row(
              children: [
                ValueListenableBuilder(
                  valueListenable: _videoController!,
                  builder: (context, VideoPlayerValue value, child) {
                    return Text(
                      _formatDuration(value.position),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    );
                  },
                ),
                Text(
                  ' / ${_formatDuration(_videoController!.value.duration)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha:0.4),
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TvFocusButton(
                  icon: _videoFit == BoxFit.contain
                      ? Icons.fullscreen_rounded
                      : _videoFit == BoxFit.cover
                      ? Icons.crop_free_rounded
                      : Icons.aspect_ratio_rounded,
                  label: _videoFit == BoxFit.contain
                      ? 'FIT'
                      : _videoFit == BoxFit.cover
                      ? 'STRETCH'
                      : 'FILL',
                  onPressed: () {
                    setState(() {
                      _videoFit = _videoFit == BoxFit.contain
                          ? BoxFit.cover
                          : _videoFit == BoxFit.cover
                          ? BoxFit.fill
                          : BoxFit.contain;
                    });
                    _startHideTimer();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  Widget _buildErrorView() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white30,
              size: 100,
            ),
            const SizedBox(height: 32),
            const Text(
              'Oops! Something went wrong.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'The video could not be loaded.',
              style: TextStyle(color: Colors.white38, fontSize: 22),
            ),
            const SizedBox(height: 64),
            TvFocusButton(
              icon: Icons.arrow_back_rounded,
              label: 'GO BACK',
              isPrimary: true,
              autofocus: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistOverlay() {
    final servers = widget.episodes;
    final currentServer = servers[_selectedServerIndex];
    final episodes = currentServer.serverData ?? [];

    return Stack(
      children: [
        // Backdrop
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              setState(() => _showPlaylist = false);
              _startHideTimer();
            },
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.black54),
            ),
          ),
        ),
        // Liquid Glass Sidebar
        Positioned(
          top: 0,
          right: 0,
          bottom: 0,
          width: 480,
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha:0.7),
                  border: Border(
                    left: BorderSide(
                      color: Colors.white.withValues(alpha:0.1),
                      width: 1.5,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha:0.5),
                      blurRadius: 50,
                      spreadRadius: 20,
                    ),
                  ],
                ),
                child: SafeArea(
                  left: false,
                  child: Column(
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.all(40),
                        child: Row(
                          children: [
                            const Text(
                              'EPISODES',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                            const Spacer(),
                            TvFocusButton(
                              icon: Icons.close_rounded,
                              onPressed: () {
                                setState(() => _showPlaylist = false);
                                _startHideTimer();
                              },
                            ),
                          ],
                        ),
                      ),
                      // Server selector
                      if (servers.length > 1)
                        SizedBox(
                          height: 56,
                          child: FocusTraversalGroup(
                            child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            scrollDirection: Axis.horizontal,
                            itemCount: servers.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 16),
                            itemBuilder: (context, index) {
                              final isSelected = index == _selectedServerIndex;
                              return Focus(
                                onKeyEvent: (node, event) {
                                  if (event is KeyDownEvent &&
                                      (event.logicalKey ==
                                              LogicalKeyboardKey.select ||
                                          event.logicalKey ==
                                              LogicalKeyboardKey.enter)) {
                                    setState(
                                      () => _selectedServerIndex = index,
                                    );
                                    return KeyEventResult.handled;
                                  }
                                  return KeyEventResult.ignored;
                                },
                                child: Builder(
                                  builder: (context) {
                                    final hasFocus = Focus.of(context).hasFocus;
                                    return ChoiceChip(
                                      label: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: Text(
                                          servers[index].serverName ??
                                              'SERVER ${index + 1}',
                                        ),
                                      ),
                                      selected: isSelected,
                                      onSelected: (val) {
                                        if (val) {
                                          setState(
                                            () => _selectedServerIndex = index,
                                          );
                                        }
                                      },
                                      selectedColor: TvDesignSystem.primary,
                                      backgroundColor: hasFocus
                                          ? Colors.white.withValues(alpha:0.15)
                                          : Colors.white.withValues(alpha:0.05),
                                      labelStyle: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : (hasFocus
                                                  ? Colors.white
                                                  : Colors.white38),
                                        fontWeight: isSelected || hasFocus
                                            ? FontWeight.w900
                                            : FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                      side: BorderSide(
                                        color: hasFocus
                                            ? Colors.white
                                            : (isSelected
                                                  ? TvDesignSystem.primary
                                                  : Colors.transparent),
                                        width: 1.5,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                          ),
                        ),
                      const SizedBox(height: 32),
                      // Episode grid
                      Expanded(
                        child: FocusTraversalGroup(
                          child: GridView.builder(
                            padding: const EdgeInsets.fromLTRB(40, 0, 40, 60),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 24,
                                  crossAxisSpacing: 24,
                                  childAspectRatio: 2.2,
                                ),
                          itemCount: episodes.length,
                          itemBuilder: (context, index) {
                            final ep = episodes[index];
                            final isCurrent = ep.name == _currentEpisodeName;
                            final videoUrl = ep.linkM3u8 ?? ep.linkEmbed ?? '';
                            return Focus(
                              autofocus: isCurrent,
                              onKeyEvent: (node, event) {
                                if (event is KeyDownEvent &&
                                    (event.logicalKey ==
                                            LogicalKeyboardKey.select ||
                                        event.logicalKey ==
                                            LogicalKeyboardKey.enter) &&
                                    videoUrl.isNotEmpty) {
                                  _switchEpisode(ep, _selectedServerIndex);
                                  return KeyEventResult.handled;
                                }
                                return KeyEventResult.ignored;
                              },
                              child: Builder(
                                builder: (context) {
                                  final hasFocus = Focus.of(context).hasFocus;
                                  return AnimatedScale(
                                    scale: hasFocus ? 1.08 : 1.0,
                                    duration: TvDesignSystem.durationFast,
                                    curve: TvDesignSystem.curveFluid,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isCurrent
                                            ? TvDesignSystem.primary
                                                  .withValues(alpha:0.2)
                                            : (hasFocus
                                                  ? Colors.white.withValues(alpha:
                                                      0.15,
                                                    )
                                                  : Colors.white.withValues(alpha:
                                                      0.06,
                                                    )),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isCurrent
                                              ? TvDesignSystem.primary
                                              : (hasFocus
                                                    ? Colors.white
                                                    : Colors.white.withValues(alpha:
                                                        0.1,
                                                      )),
                                          width: hasFocus ? 2 : 1.5,
                                        ),
                                        boxShadow: hasFocus
                                            ? [
                                                BoxShadow(
                                                  color: Colors.white
                                                      .withValues(alpha:0.15),
                                                  blurRadius: 15,
                                                ),
                                              ]
                                            : [],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: videoUrl.isEmpty
                                              ? null
                                              : () => _switchEpisode(
                                                  ep,
                                                  _selectedServerIndex,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          child: Center(
                                            child: Text(
                                              ep.name ?? '',
                                              style: TextStyle(
                                                color: isCurrent || hasFocus
                                                    ? Colors.white
                                                    : Colors.white60,
                                                fontSize: 20,
                                                fontWeight:
                                                    isCurrent || hasFocus
                                                    ? FontWeight.w900
                                                    : FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
