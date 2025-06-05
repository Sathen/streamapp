import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/generic_media_details.dart';
import '../../providers/download_manager.dart';

class EpisodeListItem extends StatelessWidget {
  final GenericEpisode episode;
  final GenericSeason season;
  final GenericMediaData? mediaData;
  final String episodeKey;
  final bool isCurrentlyLoading;
  final VoidCallback onTap;

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
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;

    return Material(
      color: isCurrentlyLoading ? colorScheme.primary.withOpacity(0.05) : Colors.transparent,
      child: InkWell(
        onTap: isCurrentlyLoading ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 100,
                child: _buildEpisodeStillImage(context, episode),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'E${episode.episodeNumber}: ${episode.name.isNotEmpty ? episode.name : "Episode ${episode.episodeNumber}"}',
                      style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (episode.airDate != null && episode.airDate!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Aired: ${episode.airDate}',
                          style: textTheme.bodySmall?.copyWith(color: textTheme.bodySmall?.color?.withOpacity(0.7)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _EpisodeTrailingAction(
                episodeKey: episodeKey,
                isCurrentlyLoading: isCurrentlyLoading,
                episode: episode,
                season: season,
                mediaData: mediaData,
              ),
            ],
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
            child: Center(child: Icon(Icons.broken_image_outlined, size: 24, color: colorScheme.onSurfaceVariant.withOpacity(0.7))),
          ),
        )
            : Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(6.0),
          ),
          child: Center(child: Icon(Icons.ondemand_video_outlined, size: 30, color: colorScheme.onSurfaceVariant.withOpacity(0.7))),
        ),
      ),
    );
  }
}

class _EpisodeTrailingAction extends StatelessWidget {
  final String episodeKey;
  final bool isCurrentlyLoading;
  final GenericEpisode episode;
  final GenericSeason season;
  final GenericMediaData? mediaData;

  const _EpisodeTrailingAction({
    required this.episodeKey,
    required this.isCurrentlyLoading,
    required this.episode,
    required this.season,
    this.mediaData,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;

    if (isCurrentlyLoading) {
      return SizedBox(
        width: 36,
        height: 36,
        child: Center(
          child: SizedBox(
            width: 24, height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: colorScheme.primary),
          ),
        ),
      );
    }

    final manager = context.watch<DownloadManager>();
    final downloadInfo = manager.getDownloadInfo(episodeKey);
    final isDownloading = manager.isDownloading(episodeKey);
    final isDownloaded = downloadInfo.isCompleted;


    if (isDownloading) {
      return InkWell(
        onTap: () {
          manager.cancelDownload(episodeKey);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Download cancelled for ${episode.name}'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                margin: const EdgeInsets.all(10),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  value: downloadInfo.progress > 0 ? downloadInfo.progress : null,
                  backgroundColor: colorScheme.primary.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  strokeWidth: 3,
                ),
              ),
              if (downloadInfo.progress > 0)
                Text(
                  '${(downloadInfo.progress * 100).toStringAsFixed(0)}%',
                  style: textTheme.labelSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 9),
                )
              else
                Icon(Icons.close, size: 16, color: colorScheme.primary),
            ],
          ),
        ),
      );
    }

    if (isDownloaded) {
      return Icon(Icons.play_circle_filled_rounded, color: colorScheme.primary, size: 28);
    }

    return Icon(Icons.play_arrow_rounded, color: colorScheme.secondary, size: 28);
  }
}