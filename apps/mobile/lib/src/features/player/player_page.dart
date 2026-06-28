import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:media_library/media_library.dart';

class PlayerPage extends ConsumerStatefulWidget {
  final String videoUrl;
  final String filmName;
  final String episode;
  final String slug;
  final List<Episode> episodes;

  const PlayerPage({
    super.key,
    required this.videoUrl,
    required this.filmName,
    required this.episode,
    required this.slug,
    required this.episodes,
  });

  @override
  ConsumerState<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends ConsumerState<PlayerPage>
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

  bool _initialized = false;
  bool _wasPlaying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentVideoUrl = widget.videoUrl;
    _currentEpisodeName = widget.episode;
    _findCurrentIndices();
    _startHideTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      _initializePlayer();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Tự động pause khi thoát ra ngoài (background) hoặc màn hình bị khóa
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _videoController?.pause();
      _saveCurrentPosition();
      if (mounted) setState(() => _controlsVisible = true);
    }
  }

  void _findCurrentIndices() {
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

    // HLS (.m3u8): tell ExoPlayer the format outright. Without this hint Android
    // probes the stream on the first attempt and frequently fails the very first
    // play — passing VideoFormat.hls makes it use the HLS source factory directly.
    final isHls = _currentVideoUrl.toLowerCase().contains('.m3u8');

    VideoPlayerController? controller;
    // ExoPlayer cold-start can throw a transient error on the first init; retry a
    // couple of times with a short backoff before surfacing the error screen.
    for (var attempt = 0; attempt < 3; attempt++) {
      final c = VideoPlayerController.networkUrl(
        Uri.parse(_currentVideoUrl),
        formatHint: isHls ? VideoFormat.hls : null,
      );
      try {
        await c.initialize();
        controller = c;
        break;
      } catch (_) {
        await c.dispose();
        if (!mounted) return;
        await Future.delayed(const Duration(milliseconds: 400));
      }
    }

    if (controller == null) {
      if (mounted) setState(() => _hasError = true);
      return;
    }

    // The page may have been popped while we were initializing/retrying.
    if (!mounted) {
      await controller.dispose();
      return;
    }

    // Restore saved playback position
    final repo = ref.read(historyRepositoryProvider);
    final savedPosition = await repo.getPlaybackPosition(
      widget.slug,
      _currentEpisodeName,
    );

    _videoController = controller;
    // Keep the screen awake while a video is actually playing.
    _wasPlaying = false;
    controller.addListener(_handlePlaybackStateForWakelock);

    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
      autoPlay: true,
      allowFullScreen: false,
      allowMuting: true,
      showControls: false,
      startAt: savedPosition != null && savedPosition > 0
          ? Duration(seconds: savedPosition)
          : null,
      placeholder: Container(color: Colors.black),
      errorBuilder: (context, errorMessage) {
        return _buildErrorView();
      },
    );

    // Save position periodically
    _positionSaveTimer ??= Timer.periodic(
      const Duration(seconds: 10),
      (_) => _saveCurrentPosition(),
    );

    if (mounted) setState(() {});
  }

  /// Toggle the wakelock so the screen never sleeps mid-playback, but is freed
  /// the moment playback pauses/ends.
  void _handlePlaybackStateForWakelock() {
    final playing = _videoController?.value.isPlaying ?? false;
    if (playing == _wasPlaying) return;
    _wasPlaying = playing;
    WakelockPlus.toggle(enable: playing);
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
    _videoController?.pause(); // Đảm bảo ngừng phát tập cũ

    _videoController?.removeListener(_handlePlaybackStateForWakelock);
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

    setState(() {
      _controlsVisible = !_controlsVisible;
    });

    if (_controlsVisible) {
      _startHideTimer();
    } else {
      _hideTimer?.cancel();
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted &&
          !_showPlaylist &&
          _videoController?.value.isPlaying == true) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  Future<void> _exitPlayer() async {
    // First unlock all orientations so iOS allows the transition
    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    // Then lock to portrait
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _positionSaveTimer?.cancel();
    _hideTimer?.cancel();

    // Ngắt phát ngay lập tức và lưu vị trí khi thoát hoàn toàn màn hình
    if (_videoController != null && _videoController!.value.isInitialized) {
      _videoController!.pause();
      final position = _videoController!.value.position.inSeconds;
      if (position > 0) {
        final repo = ref.read(historyRepositoryProvider);
        repo.savePlaybackPosition(widget.slug, _currentEpisodeName, position);
      }
    }

    _videoController?.removeListener(_handlePlaybackStateForWakelock);
    WakelockPlus.disable();

    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exitPlayer();
      },
      child: Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
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
                      color: AppColors.primaryValue,
                      strokeWidth: 2,
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
      duration: const Duration(milliseconds: 300),
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
        height: 100,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: _exitPlayer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.filmName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'ĐANG PHÁT: $_currentEpisodeName',
                      style: TextStyle(
                        color: AppColors.primaryValue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              _HUDButton(
                icon: Icons.playlist_play_rounded,
                label: 'TẬP PHIM',
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
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _CircleIconButton(
            icon: Icons.replay_10_rounded,
            onPressed: () {
              if (_videoController == null) return;
              final current = _videoController!.value.position;
              _videoController!.seekTo(current - const Duration(seconds: 10));
              _startHideTimer();
            },
          ),
          _CircleIconButton(
            icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: 64,
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
          _CircleIconButton(
            icon: Icons.forward_10_rounded,
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              VideoProgressIndicator(
                _videoController!,
                allowScrubbing: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                colors: VideoProgressColors(
                  playedColor: AppColors.primaryValue,
                  bufferedColor: Colors.white.withValues(alpha: 0.2),
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  ValueListenableBuilder(
                    valueListenable: _videoController!,
                    builder: (context, VideoPlayerValue value, child) {
                      return Text(
                        _formatDuration(value.position),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                  const Text(
                    ' / ',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  Text(
                    _formatDuration(_videoController!.value.duration),
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _videoFit = _videoFit == BoxFit.contain
                            ? BoxFit.cover
                            : _videoFit == BoxFit.cover
                                ? BoxFit.fill
                                : BoxFit.contain;
                      });
                      _startHideTimer();
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _videoFit == BoxFit.contain
                              ? Icons.fit_screen_rounded
                              : _videoFit == BoxFit.cover
                                  ? Icons.crop_free_rounded
                                  : Icons.aspect_ratio_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _videoFit == BoxFit.contain
                              ? 'VỪA'
                              : _videoFit == BoxFit.cover
                                  ? 'PHÓNG'
                                  : 'GIÃN',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
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
            const Icon(Icons.error_outline, color: Colors.white, size: 60),
            const SizedBox(height: 16),
            const Text(
              'Không thể tải video này',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            AppButton(label: 'Quay lại', onPressed: _exitPlayer),
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
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              setState(() => _showPlaylist = false);
              _startHideTimer();
            },
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.black45),
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          bottom: 0,
          width: 380,
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.85),
                  border: Border(left: BorderSide(color: Colors.white10)),
                ),
                child: SafeArea(
                  left: false,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(25),
                        child: Row(
                          children: [
                            const Text(
                              'DANH SÁCH TẬP',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () {
                                setState(() => _showPlaylist = false);
                                _startHideTimer();
                              },
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (servers.length > 1)
                        SizedBox(
                          height: 48,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 25),
                            scrollDirection: Axis.horizontal,
                            itemCount: servers.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final isSelected = index == _selectedServerIndex;
                              return ChoiceChip(
                                label: Text(
                                  servers[index].serverName ?? 'S${index + 1}',
                                ),
                                selected: isSelected,
                                onSelected: (val) {
                                  if (val) {
                                    setState(
                                      () => _selectedServerIndex = index,
                                    );
                                  }
                                },
                                selectedColor: AppColors.primaryValue,
                                backgroundColor: Colors.white10,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white60,
                                ),
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.fromLTRB(25, 0, 25, 40),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 2.2,
                              ),
                          itemCount: episodes.length,
                          itemBuilder: (context, index) {
                            final ep = episodes[index];
                            final isCurrent = ep.name == _currentEpisodeName;
                            final videoUrl = ep.linkM3u8 ?? ep.linkEmbed ?? '';
                            return InkWell(
                              onTap: videoUrl.isEmpty
                                  ? null
                                  : () => _switchEpisode(
                                      ep,
                                      _selectedServerIndex,
                                    ),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? AppColors.primaryValue.withValues(
                                          alpha: 0.2,
                                        )
                                      : Colors.white10,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isCurrent
                                        ? AppColors.primaryValue
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Text(
                                  ep.name ?? '',
                                  style: TextStyle(
                                    color: isCurrent
                                        ? Colors.white
                                        : Colors.white70,
                                    fontWeight: isCurrent
                                        ? FontWeight.bold
                                        : FontWeight.normal,
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
            ),
          ),
        ),
      ],
    );
  }
}

class _HUDButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  const _HUDButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final bool isPrimary;
  const _CircleIconButton({
    required this.icon,
    required this.onPressed,
    this.size = 48,
    this.isPrimary = false,
  });
  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Material(
        color: isPrimary
            ? AppColors.primaryValue
            : Colors.black.withValues(alpha: 0.3),
        child: InkWell(
          onTap: onPressed,
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            child: Icon(icon, color: Colors.white, size: size * 0.6),
          ),
        ),
      ),
    );
  }
}
