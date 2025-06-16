import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/datasources/remote/client/online_server_api.dart';
import '../../../providers/watch_history/watch_history_provider.dart';
import '../../../widgets/common/dialogs/play_options_dialog.dart';
import '../../../../core/utils/errors.dart';
import '../../../providers/download/download_provider.dart';
import '../../../providers/media_details/media_details_provider.dart';

class MoviePlaySection extends StatelessWidget {
  final MediaDetailsProvider provider;
  final int? tmdbId;
  final bool isOnlineMedia;

  const MoviePlaySection({
    super.key,
    required this.provider,
    this.tmdbId,
    this.isOnlineMedia = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.surfaceBlue,
            AppTheme.surfaceVariant.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outlineVariant, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Play Button
              _buildPlayButton(context),

              // Download Progress (if downloading)
              Consumer<DownloadProvider>(
                builder: (context, downloadProvider, child) {
                  final episodeKey = _getEpisodeKey();
                  if (downloadProvider.isDownloading(episodeKey)) {
                    return Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildDownloadProgress(
                          context,
                          downloadProvider,
                          episodeKey,
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayButton(BuildContext context) {
    final theme = Theme.of(context);
    final title =
        isOnlineMedia
            ? provider.onlineMediaData?.title ?? 'Unknown'
            : provider.mediaData?.title ?? 'Unknown';

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed:
            provider.isFetchingStreams ? null : () => _handlePlay(context),
        icon:
            provider.isFetchingStreams
                ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.onPrimary,
                    ),
                  ),
                )
                : const Icon(Icons.play_arrow_rounded, size: 28),
        label: Text(
          provider.isFetchingStreams ? 'Loading...' : 'Play',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildDownloadProgress(
    BuildContext context,
    DownloadProvider downloadProvider,
    String episodeKey,
  ) {
    final downloadInfo = downloadProvider.getDownloadInfo(episodeKey);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.download, color: AppTheme.primaryBlue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Downloading...',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
              Text(
                '${(downloadInfo.progress * 100).toInt()}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: downloadInfo.progress,
            backgroundColor: AppTheme.outlineVariant,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                downloadInfo.formattedSpeed,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.mediumEmphasisText,
                ),
              ),
              if (downloadInfo.totalSize != null)
                Text(
                  downloadInfo.totalSize!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.mediumEmphasisText,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handlePlay(BuildContext context) async {
    try {
      provider.setFetchingStreams(true);

      if (isOnlineMedia) {
        await _handleOnlinePlay(context);
      } else {
        await _handleTmdbPlay(context);
      }
    } catch (e) {
      if (context.mounted) {
        showErrorSnackbar(context, 'Error playing media: $e');
      }
    } finally {
      provider.setFetchingStreams(false);
    }
  }

  Future<void> _handleOnlinePlay(BuildContext context) async {
    final mediaData = provider.onlineMediaData;
    if (mediaData?.embedUrl == null) {
      throw Exception('No embed URL available');
    }

    // Add to watch history for online movies (no seasons)
    if (context.mounted && mediaData!.seasons.isEmpty) {
      final historyProvider = Provider.of<WatchHistoryProvider>(context, listen: false);
      await historyProvider.addMovieToHistory(
        tmdbId: mediaData.tmdbId,
        title: mediaData.title,
        originalTitle: mediaData.title, // Online media might not have separate original title
        posterPath: mediaData.posterPath,
        backdropPath: mediaData.backdropPath,
        rating: mediaData.rating,
      );
    }

    final streams = await get<OnlineServerApi>().getVideoStreamsByPath(mediaData!.embedUrl!);

    if (streams.data.isEmpty) {
      throw Exception('No streams available');
    }

    if (context.mounted) {
      showPlayOptionsDialog(
        context: context,
        streamUrl: streams.data.first.sources.first.links.first.url,
        streamName: streams.data.first.sourceName,
        contentTitle: mediaData.title,
        episodeKey: _getEpisodeKey(),
        fileName: mediaData.title.replaceAll(' ', '_'),
      );
    }
  }

  Future<void> _handleTmdbPlay(BuildContext context) async {
    final mediaData = provider.mediaData;
    if (mediaData == null || tmdbId == null) {
      throw Exception('No media data available');
    }

    // Add to watch history when streams are requested
    if (context.mounted) {
      final historyProvider = Provider.of<WatchHistoryProvider>(context, listen: false);
      await historyProvider.addMovieToHistory(
        tmdbId: tmdbId.toString(),
        title: mediaData.title,
        originalTitle: mediaData.originalTitle ?? mediaData.title,
        posterPath: mediaData.posterPath,
        backdropPath: mediaData.backdropPath,
        rating: mediaData.voteAverage,
      );
    }

    final streams = await get<OnlineServerApi>().getVideoSteams(
      title: mediaData.title,
      originalTitle: mediaData.originalTitle,
      mediaType: 'movie',
    );

    if (streams.data.isEmpty) {
      throw Exception('No streams available');
    }

    if (context.mounted) {
      showPlayOptionsDialog(
        context: context,
        streamUrl: streams.data.first.sources.first.links.first.url,
        streamName: streams.data.first.sourceName,
        contentTitle: mediaData.title,
        episodeKey: _getEpisodeKey(),
        fileName: mediaData.title.replaceAll(' ', '_'),
      );
    }
  }

  String _getEpisodeKey() {
    return generateMovieKey(tmdbId.toString());
  }
}
