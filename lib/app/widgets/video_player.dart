import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:flutter/material.dart';
import 'package:better_player/better_player.dart';
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
  late BetterPlayerController _betterPlayerController;
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
      backgroundColor: GlobalColor.backgroundColor,
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: GlobalColor.backgroundColor,
      ),
      body: BetterPlayer(controller: _betterPlayerController),
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
          aspectRatio: 16 / 9,
          fullScreenByDefault: true,

          controlsConfiguration: BetterPlayerControlsConfiguration(
            controlBarColor: Colors.transparent,
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
          print(">>>>>>>>>>>>>>${_betterPlayerController.videoPlayerController!.value.position.inSeconds}");
        }
        if (event.betterPlayerEventType == BetterPlayerEventType.initialized) {
          // Video player initialized, seek to saved position if available
          if (savedPosition != null) {
            _betterPlayerController.seekTo(Duration(seconds: savedPosition));
            print(">>>>>>position: $savedPosition");
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
    int positionInSeconds = _betterPlayerController.videoPlayerController!.value.position.inSeconds;
    _prefs.setInt(_prefsKey, positionInSeconds);
  }
}