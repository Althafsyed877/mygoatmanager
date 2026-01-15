
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart';


class SplashScreen extends StatefulWidget {
  final VoidCallback onFinish;
  const SplashScreen({Key? key, required this.onFinish}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _isVideoReady = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/videos/splashscreen.mp4')
      ..initialize().then((_) {
        setState(() {
          _isVideoReady = true;
        });
        _controller.play();
      });
    _controller.addListener(_onVideoEnd);
  }

  void _onVideoEnd() {
    if (_controller.value.position >= _controller.value.duration && _controller.value.isInitialized) {
      widget.onFinish();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoEnd);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // On web, show only the logo as splash
      Future.delayed(const Duration(seconds: 2), widget.onFinish);
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
            child: Image.asset(
              'assets/images/applogo.png',
              width: 256,
              height: 256,
            ),
        ),
      );
    }
    // On mobile/desktop, show the video splash
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _isVideoReady
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
