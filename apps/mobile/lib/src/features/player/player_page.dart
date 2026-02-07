import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';

class PlayerPage extends StatefulWidget {
  final String videoUrl;
  final String filmName;
  final String episode;
  final String slug;

  const PlayerPage({
    super.key,
    required this.videoUrl,
    required this.filmName,
    required this.episode,
    required this.slug,
  });

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );

    try {
      await _videoController.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: true,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        placeholder: Container(color: Colors.black),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.white, size: 42),
                const SizedBox(height: 8),
                Text(
                  'Không thể phát video',
                  style: TextStyle(color: Colors.grey[300]),
                ),
              ],
            ),
          );
        },
      );
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _chewieController?.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _hasError
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Không thể phát video này',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.filmName} - ${widget.episode}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Quay lại'),
                  ),
                ],
              ),
            )
          : _chewieController != null
              ? Chewie(controller: _chewieController!)
              : const Center(child: CircularProgressIndicator()),
    );
  }
}
