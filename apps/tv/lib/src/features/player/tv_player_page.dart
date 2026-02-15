import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:core/core.dart';
import '../../shared/tv_design_system.dart';
import '../../shared/widgets/tv_focus_button.dart';
import '../../shared/widgets/tv_focus_wrapper.dart';

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
  int _focusedEpisodeIndex = 0;
  static const int _gridColumns = 6;

  // Custom Controls State
  bool _controlsVisible = true;
  Timer? _hideTimer;
  Timer? _uiUpdateTimer;
  BoxFit _videoFit = BoxFit.cover;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

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
        aspectRatio: _videoController!.value.aspectRatio,
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

      // Update UI position every 1 second (not every frame)
      _uiUpdateTimer?.cancel();
      _uiUpdateTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) {
          if (!mounted || _videoController == null) return;
          if (!_videoController!.value.isInitialized) return;
          final pos = _videoController!.value.position;
          final dur = _videoController!.value.duration;
          if (pos != _currentPosition || dur != _totalDuration) {
            setState(() {
              _currentPosition = pos;
              _totalDuration = dur;
            });
          }
        },
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
    _uiUpdateTimer?.cancel();

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
    _uiUpdateTimer?.cancel();

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

          // ── Playlist mode: grid navigation ──
          if (_showPlaylist) {
            final eps = widget.episodes[_selectedServerIndex].serverData ?? [];
            if (key == LogicalKeyboardKey.arrowRight) {
              if (_focusedEpisodeIndex < eps.length - 1) {
                setState(() => _focusedEpisodeIndex++);
              }
              return KeyEventResult.handled;
            }
            if (key == LogicalKeyboardKey.arrowLeft) {
              if (_focusedEpisodeIndex > 0) {
                setState(() => _focusedEpisodeIndex--);
              }
              return KeyEventResult.handled;
            }
            if (key == LogicalKeyboardKey.arrowDown) {
              final next = _focusedEpisodeIndex + _gridColumns;
              if (next < eps.length) {
                setState(() => _focusedEpisodeIndex = next);
              }
              return KeyEventResult.handled;
            }
            if (key == LogicalKeyboardKey.arrowUp) {
              final next = _focusedEpisodeIndex - _gridColumns;
              if (next >= 0) {
                setState(() => _focusedEpisodeIndex = next);
              } else {
                setState(() => _showPlaylist = false);
                _startHideTimer();
              }
              return KeyEventResult.handled;
            }
            if (key == LogicalKeyboardKey.select ||
                key == LogicalKeyboardKey.enter) {
              if (_focusedEpisodeIndex < eps.length) {
                _switchEpisode(eps[_focusedEpisodeIndex], _selectedServerIndex);
              }
              return KeyEventResult.handled;
            }
            if (key == LogicalKeyboardKey.goBack ||
                key == LogicalKeyboardKey.escape ||
                key == LogicalKeyboardKey.backspace) {
              setState(() => _showPlaylist = false);
              _startHideTimer();
              return KeyEventResult.handled;
            }
            return KeyEventResult.handled;
          }

          // ── Normal player mode ──
          if (key == LogicalKeyboardKey.select ||
              key == LogicalKeyboardKey.enter) {
            if (!_controlsVisible) {
              _toggleControls();
              return KeyEventResult.handled;
            }
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

          if (key == LogicalKeyboardKey.arrowLeft) {
            if (_videoController != null) {
              final current = _videoController!.value.position;
              _videoController!.seekTo(current - const Duration(seconds: 10));
              setState(() => _controlsVisible = true);
              _startHideTimer();
              return KeyEventResult.handled;
            }
          }

          if (key == LogicalKeyboardKey.arrowRight) {
            if (_videoController != null) {
              final current = _videoController!.value.position;
              _videoController!.seekTo(current + const Duration(seconds: 10));
              setState(() => _controlsVisible = true);
              _startHideTimer();
              return KeyEventResult.handled;
            }
          }

          if (key == LogicalKeyboardKey.goBack ||
              key == LogicalKeyboardKey.escape ||
              key == LogicalKeyboardKey.backspace) {
            context.pop();
            return KeyEventResult.handled;
          }

          if (key == LogicalKeyboardKey.contextMenu ||
              key == LogicalKeyboardKey.arrowUp) {
            if (!_controlsVisible) {
              setState(() => _controlsVisible = true);
              _startHideTimer();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          }

          if (key == LogicalKeyboardKey.arrowDown) {
            final eps = widget.episodes[_selectedServerIndex].serverData ?? [];
            final idx = eps.indexWhere((e) => e.name == _currentEpisodeName);
            setState(() {
              _focusedEpisodeIndex = idx >= 0 ? idx : 0;
              _showPlaylist = true;
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
              child: RepaintBoundary(
                child: _hasError
                    ? _buildErrorView()
                    : _chewieController != null
                    ? SizedBox.expand(
                        child: FittedBox(
                          fit: _videoFit,
                          child: SizedBox(
                            width: _videoController!.value.size.width,
                            height: _videoController!.value.size.height,
                            child: Chewie(controller: _chewieController!),
                          ),
                        ),
                      )
                    : const Center(
                        child: CircularProgressIndicator(
                          color: TvDesignSystem.primary,
                          strokeWidth: 3,
                        ),
                      ),
              ),
            ),

            // 2. Control Layout
            if (_controlsVisible)
              RepaintBoundary(
                child: Stack(
                  children: [
                    _buildTopHUD(),
                    _buildCenterControls(),
                    _buildBottomBar(),
                  ],
                ),
              ),

            // 3. Playlist Overlay
            if (_showPlaylist) _buildPlaylistOverlay(),
          ],
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
        height: 180,
        padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 48),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.9), Colors.transparent],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TvFocusButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => context.pop(),
            ),
            const SizedBox(width: 32),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.filmName.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: TvDesignSystem.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _currentEpisodeName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'ĐANG PHÁT',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            TvFocusButton(
              icon: Icons.video_settings_rounded,
              label: 'Tỉ Lệ',
              onPressed: () {
                setState(() {
                  _videoFit = _videoFit == BoxFit.cover
                      ? BoxFit.contain
                      : (_videoFit == BoxFit.contain
                            ? BoxFit.fill
                            : BoxFit.cover);
                });
                _startHideTimer();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterControls() {
    final isPlaying = _videoController?.value.isPlaying ?? false;
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSeekButton(Icons.replay_10_rounded, -10),
          const SizedBox(width: 64),
          TvFocusButton(
            icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: 140,
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
          const SizedBox(width: 64),
          _buildSeekButton(Icons.forward_10_rounded, 10),
        ],
      ),
    );
  }

  Widget _buildSeekButton(IconData icon, int seconds) {
    return TvFocusWrapper(
      onTap: () {
        if (_videoController == null) return;
        final current = _videoController!.value.position;
        _videoController!.seekTo(current + Duration(seconds: seconds));
        _startHideTimer();
      },
      builder: (context, hasFocus) {
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: hasFocus
                ? Colors.white
                : Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: hasFocus ? Colors.black : Colors.white,
            size: 40,
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    if (_videoController == null) return const SizedBox();

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(64, 60, 64, 64),
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
            RepaintBoundary(
              child: Focus(
                onKeyEvent: (node, event) {
                  if (event is KeyDownEvent) {
                    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                      _videoController!.seekTo(
                        _videoController!.value.position -
                            const Duration(seconds: 30),
                      );
                      return KeyEventResult.handled;
                    }
                    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                      _videoController!.seekTo(
                        _videoController!.value.position +
                            const Duration(seconds: 30),
                      );
                      return KeyEventResult.handled;
                    }
                  }
                  return KeyEventResult.ignored;
                },
                child: Builder(
                  builder: (context) {
                    final hasFocus = Focus.of(context).hasFocus;
                    final h = hasFocus ? 12.0 : 6.0;
                    final progress = _totalDuration.inMilliseconds > 0
                        ? (_currentPosition.inMilliseconds /
                                _totalDuration.inMilliseconds)
                            .clamp(0.0, 1.0)
                        : 0.0;
                    return SizedBox(
                      height: h,
                      child: Stack(
                        children: [
                          Container(
                            height: h,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(h / 2),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: progress,
                            child: Container(
                              height: h,
                              decoration: BoxDecoration(
                                color: TvDesignSystem.primary,
                                borderRadius: BorderRadius.circular(h / 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text(
                  _formatDuration(_currentPosition),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  ' / ${_formatDuration(_totalDuration)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TvFocusButton(
                  icon: Icons.apps_rounded,
                  label: 'TẬP PHIM',
                  onPressed: () => setState(() {
                    _showPlaylist = true;
                    _controlsVisible = true;
                  }),
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
              size: 120,
            ),
            const SizedBox(height: 40),
            const Text(
              'KHÔNG THỂ TẢI VIDEO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Vui lòng kiểm tra lại kết nối hoặc đổi server.',
              style: TextStyle(color: Colors.white38, fontSize: 20),
            ),
            const SizedBox(height: 60),
            TvFocusButton(
              icon: Icons.arrow_back_rounded,
              label: 'QUAY LẠI',
              isPrimary: true,
              autofocus: true,
              onPressed: () => context.pop(),
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
        // Dim overlay
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              setState(() => _showPlaylist = false);
              _startHideTimer();
            },
            child: Container(color: Colors.black.withValues(alpha: 0.7)),
          ),
        ),
        // Bottom panel
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black,
                    Colors.black.withValues(alpha: 0.95),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(48, 24, 48, 16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.playlist_play_rounded,
                          color: TvDesignSystem.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _currentEpisodeName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'ĐANG PHÁT',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${episodes.length} tập',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Episode grid (max 3 rows visible)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 240),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(48, 0, 48, 32),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          for (int i = 0; i < episodes.length; i++)
                            _buildEpCell(episodes[i], i),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

  Widget _buildEpCell(ServerData ep, int index) {
    final isCurrent = ep.name == _currentEpisodeName;
    final isFocused = index == _focusedEpisodeIndex;
    final cellKey = GlobalKey();

    // Auto-scroll focused cell into view
    if (isFocused) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (cellKey.currentContext != null) {
          Scrollable.ensureVisible(
            cellKey.currentContext!,
            alignment: 0.3,
            duration: TvDesignSystem.durationFast,
          );
        }
      });
    }

    return AnimatedScale(
      key: cellKey,
      scale: isFocused ? 1.08 : 1.0,
      duration: TvDesignSystem.durationFast,
      child: Container(
        width: 130,
        height: 60,
        decoration: BoxDecoration(
          color: isCurrent
              ? TvDesignSystem.primary
              : (isFocused
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.08)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isFocused
                ? Colors.white
                : Colors.white.withValues(alpha: 0.1),
            width: isFocused ? 3 : 1.5,
          ),
          boxShadow: isFocused
              ? [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.15),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ep.name ?? '',
                style: TextStyle(
                  color: isFocused && !isCurrent
                      ? Colors.black
                      : Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (isCurrent)
                Text(
                  'ĐANG XEM',
                  style: TextStyle(
                    color: isFocused
                        ? Colors.black54
                        : Colors.white.withValues(alpha: 0.7),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
