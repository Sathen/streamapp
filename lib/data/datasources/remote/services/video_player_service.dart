import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

class PlatformVideoPlayer extends StatefulWidget {
  final String url;

  const PlatformVideoPlayer({super.key, required this.url});

  @override
  State<PlatformVideoPlayer> createState() => _PlatformVideoPlayerState();
}

class _PlatformVideoPlayerState extends State<PlatformVideoPlayer> {
  late VlcPlayerController _vlcController;
  bool _isPlaying = false;
  bool _showControls = true;
  Timer? _hideTimer;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = const Duration(seconds: 1);

  @override
  void initState() {
    super.initState();

    final isFile = widget.url.startsWith('/') || widget.url.startsWith('file://');
    _vlcController = isFile
        ? VlcPlayerController.file(
      File(widget.url),
      hwAcc: HwAcc.full,
      autoPlay: true,
      options: VlcPlayerOptions(),
    )
        : VlcPlayerController.network(
      widget.url,
      hwAcc: HwAcc.full,
      autoPlay: true,
      options: VlcPlayerOptions(),
    );

    _vlcController.addListener(() {
      setState(() {
        _isPlaying = _vlcController.value.isPlaying;
        _currentPosition = _vlcController.value.position;
        _totalDuration = _vlcController.value.duration;
      });
    });

    _startHideTimer();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _onUserInteraction() {
    setState(() => _showControls = true);
    _startHideTimer();
  }

  @override
  void dispose() {
    _vlcController.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

  void _seekForward() {
    final target = _currentPosition + const Duration(seconds: 30);
    _vlcController.seekTo(target);
  }

  void _seekBackward() {
    final target = _currentPosition - const Duration(seconds: 30);
    _vlcController.seekTo(target < Duration.zero ? Duration.zero : target);
  }

  void _seekTo(double value) {
    final position = Duration(milliseconds: value.toInt());
    _vlcController.seekTo(position);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onUserInteraction,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: VlcPlayer(
                controller: _vlcController,
                aspectRatio: 16 / 9,
                placeholder: const Center(child: CircularProgressIndicator()),
              ),
            ),
            if (_showControls) ...[
              Align(
                alignment: Alignment.topLeft,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 32),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: IconButton(
                      icon: const Icon(Icons.fullscreen, color: Colors.white, size: 40),
                      onPressed: () {
                        SystemChrome.setPreferredOrientations([
                          DeviceOrientation.landscapeLeft,
                          DeviceOrientation.landscapeRight,
                        ]);
                      },
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.replay_30, color: Colors.white, size: 56),
                      onPressed: _seekBackward,
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 64,
                      ),
                      onPressed: () {
                        if (_isPlaying) {
                          _vlcController.pause();
                        } else {
                          _vlcController.play();
                        }
                      },
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      icon: const Icon(Icons.forward_30, color: Colors.white, size: 56),
                      onPressed: _seekForward,
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                    left: 16,
                    right: 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Slider(
                        value: _currentPosition.inMilliseconds.clamp(0, _totalDuration.inMilliseconds).toDouble(),
                        min: 0,
                        max: _totalDuration.inMilliseconds.toDouble(),
                        activeColor: Colors.white,
                        inactiveColor: Colors.white54,
                        onChanged: (value) => _seekTo(value),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_currentPosition),
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          Text(
                            _formatDuration(_totalDuration),
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '${duration.inHours > 0 ? '${twoDigits(duration.inHours)}:' : ''}$minutes:$seconds';
  }
}
