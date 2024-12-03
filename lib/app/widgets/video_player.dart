import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:tmovie_app/app/core/global_color.dart';
import 'package:flick_video_player/flick_video_player.dart';

class ChewieVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String fileName;
  final String episode;
  final String slug;

  const ChewieVideoPlayer({
    Key? key,
    required this.videoUrl,
    required this.fileName,
    required this.episode,
    required this.slug,
  }) : super(key: key);

  @override
  _ChewieVideoPlayerState createState() => _ChewieVideoPlayerState();
}

class _ChewieVideoPlayerState extends State<ChewieVideoPlayer> {
  late VideoPlayerController _videoPlayerController;
  // late ChewieController _chewieController;
  late FlickManager flickManager;
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
        title: Text("${widget.fileName} - Episode ${widget.episode}"),
      ),
      body: Center(
        child: _isInitialized
            ? FlickVideoPlayer(
                flickManager: flickManager,
                flickVideoWithControls: FlickVideoWithControls(
                  videoFit: BoxFit.fill,
                  controls: FlickLandscapeControls(),
                ),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }

  @override
  void dispose() {
    _savePosition();
    // _chewieController.dispose();
    _videoPlayerController.dispose();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    _prefs = await SharedPreferences.getInstance();
    int? savedPosition = _prefs.getInt(_prefsKey);

    _videoPlayerController = VideoPlayerController.network(widget.videoUrl);
    await _videoPlayerController.initialize();

    if (savedPosition != null) {
      _videoPlayerController.seekTo(Duration(seconds: savedPosition));
    }
    _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl ?? ""),
        videoPlayerOptions: VideoPlayerOptions(allowBackgroundPlayback: false));
    flickManager = FlickManager(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        autoInitialize: true);
    setState(() {
      _isInitialized = true;
    });

    _videoPlayerController.addListener(_savePosition);
  }

  void _savePosition() {
    if (_videoPlayerController.value.isInitialized) {
      int positionInSeconds = _videoPlayerController.value.position.inSeconds;
      _prefs.setInt(_prefsKey, positionInSeconds);
    }
  }
}
