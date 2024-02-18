import 'dart:async';

import 'package:flutter/material.dart';
import 'package:better_player/better_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class ChewieVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String fileName;
  final String episode;
  final String slug;

  ChewieVideoPlayer({
    required this.videoUrl,
    required this.fileName,
    required this.episode,
    required this.slug,
  });

  @override
  _ChewieVideoPlayerState createState() => _ChewieVideoPlayerState();
}

class _ChewieVideoPlayerState extends State<ChewieVideoPlayer> {
  late BetterPlayerController _betterPlayerController;
  late SharedPreferences _prefs;
  late String _prefsKey;

  double _progress = 0.0;
  String _videoDuration = "00:00";
  String _currentTime = "00:00";
  bool isSeek = false;

  @override
  void initState() {
    super.initState();
    _prefsKey = "${widget.fileName}-${widget.episode}";
    _initializePlayer();
    setState(() {
              isSeek = true;
            });
            Timer(Duration(seconds: 5), () {
              setState(() {
                isSeek = false;
              });
              print('After 5 seconds: isSeek = $isSeek');
            });
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
      },
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (RawKeyEvent event) {
          if (event.logicalKey == LogicalKeyboardKey.select) {
            _handlePlayPause();
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
              event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            setState(() {
              isSeek = true;
            });
            Timer(Duration(seconds: 10), () {
              setState(() {
                isSeek = false;
              });
              print('After 5 seconds: isSeek = $isSeek');
            });
          }
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              BetterPlayer(controller: _betterPlayerController),
              Visibility(
                visible: isSeek == true,
                child: Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    color: Colors.black.withOpacity(0.5),
                    child: Row(
                      children: [
                        Text(
                          _currentTime,
                          style: TextStyle(color: Colors.white),
                        ),
                        Expanded(
                          child: Slider(
                            
                            value: _progress,
                            
                            onChanged: (newValue) {
                              
                              setState(() {
                                _progress = newValue;
                              });
                              _onProgressChanged(newValue);
                            },
                          ),
                        ),
                        Text(
                          _videoDuration,
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _betterPlayerController.dispose();
  }

  void _initializePlayer() {
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _prefs = prefs;
      });
      int? savedPosition = _prefs.getInt(_prefsKey);

      _betterPlayerController = BetterPlayerController(
        BetterPlayerConfiguration(
          overlay: Padding(
            padding: const EdgeInsets.all(8),
            child: Text("${widget.fileName}-${widget.episode}"),
          ),
          autoPlay: true,
          looping: false,
          controlsConfiguration: BetterPlayerControlsConfiguration(
            controlBarColor: Colors.transparent,
            enableProgressText: false,
            enableFullscreen: false,
            enableOverflowMenu: false,
            enableSkips: false,
            enablePlaybackSpeed: false,
            enableProgressBar: false,
            enablePlayPause: false,
            enableMute: false,
          ),
        ),
        betterPlayerDataSource: BetterPlayerDataSource(
          BetterPlayerDataSourceType.network,
          widget.videoUrl,
        ),
      );

      // Listen to video player events
      _betterPlayerController.addEventsListener((event) {
        if (event.betterPlayerEventType == BetterPlayerEventType.progress) {
          _savePosition();
          setState(() {
            _progress = _betterPlayerController
                    .videoPlayerController!.value.position.inSeconds /
                _betterPlayerController
                    .videoPlayerController!.value.duration!.inSeconds;
            _currentTime = _formatDuration(
                _betterPlayerController.videoPlayerController!.value.position);
            _videoDuration = _formatDuration(
                _betterPlayerController.videoPlayerController!.value.duration!);
          });
        }
        if (event.betterPlayerEventType == BetterPlayerEventType.initialized) {
          // Video player initialized, seek to saved position if available
          if (savedPosition != null) {
            _betterPlayerController.seekTo(Duration(seconds: savedPosition));
          }
        }
      });
    });
  }

  @override
  void didUpdateWidget(covariant ChewieVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Save video position when widget updates
    _savePosition();
  }

  void _savePosition() {
    int positionInSeconds =
        _betterPlayerController.videoPlayerController!.value.position.inSeconds;
    _prefs.setInt(_prefsKey, positionInSeconds);
  }

  void _onProgressChanged(double newValue) {
    Duration? duration =
        _betterPlayerController.videoPlayerController!.value.duration;

    if (duration != null) {
      int newPositionInSeconds = (duration.inSeconds * newValue).round();
      int currentPosInSeconds = _betterPlayerController
          .videoPlayerController!.value.position.inSeconds;

      // Xác định chiều tua
      if (newPositionInSeconds > currentPosInSeconds) {
        // Tua tới
        int seekToPosition =
            (currentPosInSeconds + 10).clamp(0, duration.inSeconds).toInt();
        double newProgress = seekToPosition / duration.inSeconds;

        setState(() {
          _progress = newProgress;
        });

        _betterPlayerController.seekTo(Duration(seconds: seekToPosition));
      } else {
        // Tua lại
        int seekToPosition =
            (currentPosInSeconds - 10).clamp(0, duration.inSeconds).toInt();
        double newProgress = seekToPosition / duration.inSeconds;

        setState(() {
          _progress = newProgress;
        });

        _betterPlayerController.seekTo(Duration(seconds: seekToPosition));
      }
    }
  }

  // Biến lưu trữ trạng thái phát trước đó

  bool isHandlingKeyPress = false;

  void _handlePlayPause() {
    if (isHandlingKeyPress) {
      return; // Nếu hàm đang được thực thi, bỏ qua các lần gọi tiếp theo
    }

    isHandlingKeyPress = true;

    bool isPlaying = _betterPlayerController.isPlaying()!;

    if (isPlaying) {
      _betterPlayerController.pause();
    } else {
      _betterPlayerController.play();
    }

    Future.delayed(Duration(milliseconds: 300), () {
      isHandlingKeyPress = false;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
