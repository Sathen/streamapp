import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/download_manager.dart'; // Ensure this path is correct

class MoviePlayButton extends StatelessWidget {
  final VoidCallback onPlayPressed;
  final String episodeKey;
  final bool isFetchingStreams;
  final ThemeData theme;

  const MoviePlayButton({
    super.key,
    required this.onPlayPressed,
    required this.episodeKey,
    required this.theme,
    required this.isFetchingStreams,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<DownloadManager>(
      builder: (context, manager, _) {
        final downloadInfo = manager.getDownloadInfo(episodeKey);
        final isDownloading = manager.isDownloading(episodeKey);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: isFetchingStreams ? CircularProgressIndicator() : const Icon(Icons.play_arrow),
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: SizedBox(
                      height: 15.0,
                      child: LinearProgressIndicator(
                        value: downloadInfo.progress,
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.secondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded( // Allow the text to take up remaining space
                        child: Text(
                          '⬇️ Завантаження: '
                              '${(downloadInfo.progress * 100).toStringAsFixed(0)}% '
                              '${downloadInfo.formattedSpeed} '
                              '${downloadInfo.totalSize != null ? '/ ${downloadInfo.totalSize}' : ''}',
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis, // Prevent text overflow
                        ),
                      ),
                      IconButton( // The Cancel Button
                        icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                        onPressed: () {
                          manager.cancelDownload(episodeKey);
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}