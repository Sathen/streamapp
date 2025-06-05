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
    final theme = Theme.of(context); // Get the current theme
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface, // Use theme's surface color
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Play: $contentTitle',
            style: textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface, // Use theme's onSurface color
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Stream: $streamName\nQuality selected. Play now?',
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)), // Adjust opacity for lighter text
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
                  if (Platform.isAndroid) { // Only attempt AndroidIntent on Android
                    await intent.launch();
                  } else {
                    // Fallback or error for other platforms if needed
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('External playback is only supported on Android.')),
                    );
                  }
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
                  // Optionally, add a snackbar here to confirm download started
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Download started for $fileName')),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final iconTheme = theme.iconTheme;

    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: iconTheme.color), // Use theme's icon color
          iconSize: 32,
          onPressed: onTap,
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)), // Use theme's text style and color
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