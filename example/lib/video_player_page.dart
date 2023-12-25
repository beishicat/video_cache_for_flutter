import 'package:flutter/material.dart';
import 'package:video_cache_plugin/video_cache.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerPage extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerPage({super.key, required this.videoUrl});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  VideoPlayerController? _videoPlayerController;

  @override
  void initState() {
    super.initState();

    final videoUrl = VideoCache.proxyURL(widget.videoUrl);
    print('代理链接: $videoUrl');

    _videoPlayerController =
        VideoPlayerController.networkUrl(Uri.parse(videoUrl!))
          ..setLooping(true)
          ..initialize().then((_) {
            // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
            setState(() {});

            Future.delayed(const Duration(milliseconds: 50), () {
              _videoPlayerController!.play();
            });
          });
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Player'),
      ),
      body: _videoPlayerController!.value.isInitialized
          ? AspectRatio(
              aspectRatio: _videoPlayerController!.value.aspectRatio,
              child: VideoPlayer(_videoPlayerController!),
            )
          : const SizedBox.shrink(),
    );
  }
}
