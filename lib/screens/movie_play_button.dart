import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/download_manager.dart';

class MoviePlayButton extends StatelessWidget {
  final VoidCallback onPlayPressed;
  final String episodeKey;
  final ThemeData theme;

  const MoviePlayButton({
    super.key,
    required this.onPlayPressed,
    required this.episodeKey,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<DownloadManager>(
      builder: (context, manager, _) {
        final progress = manager.getProgress(episodeKey);
        final isDownloading = manager.isDownloading(episodeKey);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Play'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                textStyle: theme.textTheme.titleMedium,
              ),
              onPressed: onPlayPressed,
            ),
            const SizedBox(height: 12),
            if (isDownloading)
              Column(
                children: [
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 6),
                  Text(
                    '⬇️ Завантаження: ${(progress * 100).toStringAsFixed(0)}%',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}
