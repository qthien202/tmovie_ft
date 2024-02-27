import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chewie/chewie.dart';

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
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _prefsKey = "${widget.fileName}-${widget.episode}";
    _initializePlayer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalColor.backgroundColor,
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: GlobalColor.backgroundColor,
      ),
      body: Center(
        child: _isInitialized
            ? Chewie(controller: _chewieController)
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

      _videoPlayerController = VideoPlayerController.network(widget.videoUrl)
        ..initialize().then((_) {
          setState(() {
            _isInitialized = true;
            if (savedPosition != null) {
              _videoPlayerController.seekTo(Duration(seconds: savedPosition));
            }
            _videoPlayerController.play();
          });
        });

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        fullScreenByDefault: true,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        aspectRatio: 16 / 9,
        overlay: Padding(
          padding: const EdgeInsets.all(8),
          child: Text("${widget.fileName}-${widget.episode}"),
        ),
        // Other ChewieController configurations...
      );

      _videoPlayerController.addListener(() {
        if (_videoPlayerController.value.isPlaying &&
            !_videoPlayerController.value.isBuffering) {
          _savePosition();
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
    if (_videoPlayerController.value.isInitialized) {
      int positionInSeconds = _videoPlayerController.value.position.inSeconds;
      _prefs.setInt(_prefsKey, positionInSeconds);
    }
  }
}
