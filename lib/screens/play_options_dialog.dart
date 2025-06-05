import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/download_manager.dart';
import '../screens/video_player_screen.dart';

class PlayOptionsDialog extends StatelessWidget {
  final String streamUrl;
  final String streamName;
  final String contentTitle;
  final String episodeKey;
  final String fileName;

  const PlayOptionsDialog({
    super.key,
    required this.streamUrl,
    required this.streamName,
    required this.contentTitle,
    required this.episodeKey,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Play: $contentTitle',
            style: textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Stream: $streamName\nQuality selected. Play now?',
            style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionButton(
                icon: Icons.play_arrow,
                label: 'Play Internally',
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoPlayerScreen(streamUrl: streamUrl),
                    ),
                  );
                },
              ),
              _ActionButton(
                icon: Icons.open_in_new,
                label: 'Play Externally',
                onTap: () async {
                  Navigator.of(context).pop();
                  final intent = AndroidIntent(
                    action: 'action_view',
                    data: streamUrl,
                    type: 'video/*',
                  );
                  await intent.launch();
                },
              ),
              _ActionButton(
                icon: Icons.download,
                label: 'Download',
                onTap: () {
                  Navigator.of(context).pop();
                  context.read<DownloadManager>().downloadEpisode(
                    episodeKey: episodeKey,
                    m3u8Url: streamUrl,
                    fileName: fileName,
                  );
                },
              ),
              _ActionButton(
                icon: Icons.close,
                label: 'Cancel',
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.white),
          iconSize: 32,
          onPressed: onTap,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
        ),
      ],
    );
  }
}

void showPlayOptionsDialog({
  required BuildContext context,
  required String streamUrl,
  required String streamName,
  required String contentTitle,
  required String episodeKey,
  required String fileName,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => PlayOptionsDialog(
      streamUrl: streamUrl,
      streamName: streamName,
      contentTitle: contentTitle,
      episodeKey: episodeKey,
      fileName: fileName,
    ),
  );
}
