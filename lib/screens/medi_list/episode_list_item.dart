import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/generic_media_details.dart'; // Assuming your model paths
import '../../providers/download_manager.dart'; // Assuming your provider path

class EpisodeListItem extends StatelessWidget {
  final GenericEpisode episode;
  final GenericSeason season;
  final GenericMediaData? mediaData;
  final String episodeKey;
  final bool isCurrentlyLoading; // For initial loading of episode metadata
  final VoidCallback onTap; // Main tap action (play/initiate download)

  const EpisodeListItem({
    super.key,
    required this.episode,
    required this.season,
    this.mediaData,
    required this.episodeKey,
    required this.isCurrentlyLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final downloadManager = context.watch<DownloadManager>();
    final isDownloadingFile = downloadManager.isDownloading(episodeKey);
    final downloadInfo = downloadManager.getDownloadInfo(episodeKey);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isCurrentlyLoading ? null : onTap,
          child: Container(
            // Fixed height to ensure consistency
            constraints: const BoxConstraints(minHeight: 120),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: colorScheme.surface,
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Main content
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Episode thumbnail with consistent size
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 100,
                          child: _buildEpisodeStillImage(context, episode),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              'E${episode.episodeNumber}: ${episode.name.isNotEmpty ? episode.name : "Episode ${episode.episodeNumber}"}',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (episode.airDate != null &&
                                episode.airDate!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Aired: ${episode.airDate}',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: textTheme.bodySmall?.color
                                        ?.withOpacity(0.7),
                                  ),
                                ),
                              ),
                            // Download progress text with better styling
                            if (isDownloadingFile)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Downloading ${(downloadInfo.progress * 100).toStringAsFixed(0)}%',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _EpisodeTrailingAction(
                        episodeKey: episodeKey,
                        isItemCurrentlyLoading: isCurrentlyLoading,
                        episode: episode,
                        season: season,
                        mediaData: mediaData,
                        onItemTap: onTap,
                      ),
                    ],
                  ),
                ),

                // Progress bar overlay at bottom - consistent positioning
                if (isDownloadingFile)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: colorScheme.surfaceVariant.withOpacity(0.5),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: downloadInfo.progress.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primary,
                                colorScheme.primary.withOpacity(0.8),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEpisodeStillImage(BuildContext context, GenericEpisode episode) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6.0),
        child: episode.stillPath != null && episode.stillPath!.isNotEmpty
            ? Image.network(
          'https://image.tmdb.org/t/p/w300${episode.stillPath!}',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: colorScheme.surfaceVariant.withOpacity(0.3),
            child: Center(
              child: Icon(
                Icons.broken_image_outlined,
                size: 24,
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ),
        )
            : Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.surfaceVariant.withOpacity(0.4),
                colorScheme.surfaceVariant.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(6.0),
          ),
          child: Center(
            child: Icon(
              Icons.ondemand_video_outlined,
              size: 30,
              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }
}

class _EpisodeTrailingAction extends StatelessWidget {
  final String episodeKey;
  final bool isItemCurrentlyLoading;
  final GenericEpisode episode;
  final GenericSeason season;
  final GenericMediaData? mediaData;
  final VoidCallback onItemTap; // Main tap action from parent

  const _EpisodeTrailingAction({
    super.key,
    required this.episodeKey,
    required this.isItemCurrentlyLoading,
    required this.episode,
    required this.season,
    this.mediaData,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    final manager = context.watch<DownloadManager>();
    final downloadInfo = manager.getDownloadInfo(episodeKey);
    final isDownloadingFile = manager.isDownloading(episodeKey);
    final isDownloaded = downloadInfo.isCompleted;

    // If the episode item itself is loading its initial metadata
    if (isItemCurrentlyLoading) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.primary,
            ),
          ),
        ),
      );
    }

    // If the episode file is currently downloading
    if (isDownloadingFile) {
      return Container(
        decoration: BoxDecoration(
          color: colorScheme.errorContainer.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: IconButton(
          icon: Icon(
            Icons.close_rounded,
            color: colorScheme.error,
          ),
          iconSize: 24,
          tooltip: 'Cancel Download',
          onPressed: () {
            manager.cancelDownload(episodeKey);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Download cancelled for Episode ${episode.episodeNumber}',
                  ),
                  backgroundColor: colorScheme.inverseSurface,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  margin: const EdgeInsets.all(10),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
        ),
      );
    }

    // If downloaded or not downloaded (default state), show a play-style icon.
    // The actual play/download initiation logic is handled by `onItemTap`.
    IconData iconData = isDownloaded
        ? Icons.play_circle_filled_rounded
        : Icons.play_arrow_rounded;
    Color iconColor = isDownloaded ? colorScheme.primary : colorScheme.secondary;
    Color backgroundColor = isDownloaded
        ? colorScheme.primaryContainer.withOpacity(0.3)
        : colorScheme.secondaryContainer.withOpacity(0.3);
    String tooltipText = isDownloaded ? 'Play Downloaded Episode' : 'Play Episode';

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: IconButton(
        icon: Icon(iconData, color: iconColor, size: 26),
        tooltip: tooltipText,
        onPressed: onItemTap, // Trigger the main item's tap action
      ),
    );
  }
}