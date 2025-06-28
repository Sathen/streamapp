import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/errors.dart';
import '../../../../data/models/models/video_streams.dart';
import '../../../providers/download/download_provider.dart';
import '../../../providers/watch_history/watch_history_provider.dart';
import '../../../widgets/common/dialogs/play_options_dialog.dart';
import '../../../widgets/common/stream_selector_modal.dart';
import 'online_media_seasons_list.dart';
import 'tmdb_media_seasons_list.dart';
import '../../../providers/media_details/media_details_provider.dart';

class TvSeasonsSection extends StatelessWidget {
  final MediaDetailsProvider provider;
  final bool isOnlineMedia;

  const TvSeasonsSection({
    super.key,
    required this.provider,
    required this.isOnlineMedia,
  });

  @override
  Widget build(BuildContext context) {
    var stringTmdb = provider.getTmdbId(isOnlineMedia);

    if (stringTmdb == null || !provider.hasSeasons(isOnlineMedia)) {
      return const SizedBox.shrink();
    }

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
        borderRadius: BorderRadius.circular(24),
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
        borderRadius: BorderRadius.circular(24),
        child: buildSeasonsList(context),
      ),
    );
  }

  Widget buildSeasonsList(BuildContext context) {
    if (isOnlineMedia) {
      return OnlineMediaSeasonsList(
        mediaDetails: provider.onlineMediaData!,
        loadingEpisode: provider.loadingEpisode,
        onEpisodeTap: (season, episode, year, embedUrl, contentTitle) {
          _handleEpisodeTap(context: context, season: season, episode: episode, year: year, embedUrl: embedUrl, contentTitle: contentTitle);
        },
      );
    }

    return TmdbSeasonsList(
      seasonDetails: provider.seasonDetails,
      tmdbId: int.parse(provider.getTmdbId(isOnlineMedia)!),
      loadingEpisode: provider.loadingEpisode,
      mediaData: provider.tmdbMediaData,
      onEpisodeTap: (season, episode, year, embedUrl, contentTitle) {
        _handleEpisodeTap(context: context, season: season, episode: episode, year: year!, embedUrl: embedUrl, contentTitle: contentTitle);
      },
    );
  }

  // Handle episode tap with stream selection
  void _handleEpisodeTap({
    required BuildContext context,
    required dynamic season,
    required dynamic episode,
    required int year,
    String? embedUrl,
    String? contentTitle,
  }) async {
    // Set episode as loading
    provider.setEpisodeLoading(episode);

    var tmdbId = provider.getTmdbId(isOnlineMedia);
    var mediaData = provider.getMediaDetails(isOnlineMedia);
    try {
      // Get series title from provider or contentTitle
      final seriesTitle = mediaData?.title ?? contentTitle ?? 'Unknown Series';
      final seriesOriginalTitle =
          mediaData?.originalTitle ?? mediaData?.title;

      // Generate episode key for caching/tracking
      final episodeKey = generateEpisodeKey(
        tmdbId.toString(),
        season.seasonNumber.toString(),
        episode.episodeNumber.toString(),
      );

      // Generate filename for downloads
      final fileName =
          '${seriesTitle.replaceAll(" ", "_")}_S${season.seasonNumber}E${episode.episodeNumber}';

      if (context.mounted) {
        final historyProvider = Provider.of<WatchHistoryProvider>(context, listen: false);
        await historyProvider.addEpisodeToHistory(
          tmdbId: tmdbId.toString(),
          title: seriesTitle,
          originalTitle: seriesOriginalTitle ?? seriesTitle,
          seasonNumber: season.seasonNumber,
          episodeNumber: episode.episodeNumber,
          posterPath: mediaData?.posterPath,
          backdropPath: mediaData?.backdropPath,
          rating: mediaData?.rating,
        );
      }

      if (isOnlineMedia) {
        _showStreamSelectorByPath(
            context, embedUrl!, fileName, episodeKey, contentTitle!);
      } else {
        // Show stream selector using the provider's stream handling
        await _showStreamSelectorFromApi(
          context: context,
          title: seriesTitle,
          originalTitle: seriesOriginalTitle,
          season: season,
          year: year,
          episode: episode,
          contentTitle: seriesTitle,
          episodeKey: episodeKey,
          fileName: fileName,
        );
      }

    } catch (e) {
      // Show error using your existing error handling
      if (context.mounted) {
        showErrorSnackbar(context, 'Error fetching streams: $e');
      }
      debugPrint('Error in episode tap: $e');
    } finally {
      // Clear loading state
      provider.setEpisodeLoading(null);
    }
  }


  void _showStreamSelectorByPath(BuildContext context, String embedUrl, String fileName, String episodeKey, String contentTitle) async {
    provider.setFetchingStreams(true);
    var videoStreams = await provider.getVideoSteamsByPath(embedUrl: embedUrl);
    provider.setFetchingStreams(false);

    _showStreamSelectorFromStreams(
      context: context,
      streams: videoStreams,
      contentTitle: contentTitle,
      episodeKey: episodeKey,
      fileName: fileName,
    );
  }

  Future<void> _showStreamSelectorFromApi({
    required BuildContext context,
    required String title,
    String? originalTitle,
    dynamic season,
    dynamic episode,
    int? year,
    required String contentTitle,
    required String episodeKey,
    required String fileName,
  }) async {
    try {
      provider.setFetchingStreams(true);

      final streams = await provider.getVideoSteams(
        title: title,
        originalTitle: originalTitle,
        year: year,
        seasonNumber: season?.seasonNumber,
        episodeNumber: episode?.episodeNumber,
        mediaType: season != null ? 'tv' : 'movie',
      );

      if (!context.mounted) return;

      provider.setFetchingStreams(false);

      _showStreamSelectorFromStreams(
        context: context,
        streams: streams,
        contentTitle: contentTitle,
        episodeKey: episodeKey,
        fileName: fileName,
      );
    } catch (e) {
      if (!context.mounted) return;

      provider.setFetchingStreams(false);
      showErrorSnackbar(context, 'Failed to load streams. Please try again.');
      debugPrint('Error fetching video streams: $e');
    }
  }

  void _showStreamSelectorFromStreams({
    required BuildContext context,
    required VideoStreams streams,
    required String contentTitle,
    required String episodeKey,
    required String fileName,
    String? streamName,
  }) async {
    if (streams.data.isEmpty) {
      showErrorSnackbar(context, 'No streams available for this content.');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StreamSelectorModal(
          itemTitle: contentTitle,
          streams: streams,
          onStreamSelected: (url, name) {
            showPlayOptionsDialog(
              context: context,
              streamUrl: url,
              streamName: streamName ?? name,
              contentTitle: contentTitle,
              episodeKey: episodeKey,
              fileName: fileName,
            );
          },
        );
      },
    );
  }

}
