import 'package:flutter/material.dart';
import '../services/video_player_service.dart';
import '../models/media_detail.dart';

class VideoPlayerScreen extends StatelessWidget {
  final String streamUrl;

  const VideoPlayerScreen({
    super.key,
    required this.streamUrl});

  @override
  Widget build(BuildContext context) {
    return PlatformVideoPlayer(
        url: streamUrl);
  }
}