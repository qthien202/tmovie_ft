import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class ChewieVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String  fileName;
  final String episode;

  ChewieVideoPlayer({required this.videoUrl, required this.fileName, required this.episode});

  @override
  _ChewieVideoPlayerState createState() => _ChewieVideoPlayerState();
}

class _ChewieVideoPlayerState extends State<ChewieVideoPlayer> {
  late VideoPlayerController _videoPlayerController;
  late ChewieController _chewieController;

  @override
  void initState() {
    super.initState();
    _videoPlayerController = VideoPlayerController.network(
      widget.videoUrl,
    );
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: false,
      autoInitialize: true,
      // allowFullScreen: true,
      allowMuting: true,
      fullScreenByDefault: true,
      // allowPlaybackSpeedChanging: true,
      overlay: Padding(
        padding: const EdgeInsets.all(8),
        child: Text("${widget.fileName}-${widget.episode}"),
      ),
      
      

      // isLive: true,
      // showControls: true,
      // zoomAndPan: true
      
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalColor.backgroundColor,
      appBar: AppBar(
        backgroundColor: GlobalColor.backgroundColor,
        automaticallyImplyLeading: true,
        foregroundColor: Colors.white,
      ),
      body: Chewie(

      controller: _chewieController,
    ),
    ) ;
    
    
  }

  @override
  void dispose() {
    super.dispose();
    _videoPlayerController.dispose();
    _chewieController.dispose();
    Navigator.pop(context);
  }
}
