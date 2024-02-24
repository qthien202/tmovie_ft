import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  late VideoPlayerController _videoPlayerController;
  late ChewieController _chewieController;
  late SharedPreferences _prefs;
  late String _prefsKey;

  @override
  void initState() {
    super.initState();
    _prefsKey = "${widget.fileName}-${widget.episode}";
    _initializePlayer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.fileName}-${widget.episode}"),
      ),
      body: Center(
        child: _chewieController != null && _chewieController.videoPlayerController.value.isInitialized
            ? Chewie(
                controller: _chewieController,
              )
            : CircularProgressIndicator(),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _videoPlayerController.dispose();
    _chewieController.dispose();
  }

  void _initializePlayer() {
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _prefs = prefs;
      });
      int? savedPosition = _prefs.getInt(_prefsKey);

      _videoPlayerController = VideoPlayerController.network(
        widget.videoUrl,
      );

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        allowMuting: true,
        allowPlaybackSpeedChanging: false,
        placeholder: CircularProgressIndicator(),
        allowFullScreen: true,
        showControls: true,
      );

      // Listen to video player events
      _videoPlayerController.addListener(() {
        if (_videoPlayerController.value.isPlaying) {
          _savePosition();
        }
      });

      _videoPlayerController.initialize().then((_) {
        // Video player initialized, seek to saved position if available
        if (savedPosition != null) {
          _videoPlayerController.seekTo(Duration(seconds: savedPosition));
        }
        setState(() {});
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
    int positionInSeconds = _videoPlayerController.value.position.inSeconds;
    _prefs.setInt(_prefsKey, positionInSeconds);
  }
}
