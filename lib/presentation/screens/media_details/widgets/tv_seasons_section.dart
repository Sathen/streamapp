import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
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
        onEpisodeTap: (season, episode, embedUrl, contentTitle) {
          _handleEpisodeTap(context, season, episode, embedUrl, contentTitle);
        },
      );
    }

    return TVSeasonsList(
      seasonDetails: provider.seasonDetails,
      tmdbId: int.parse(provider.getTmdbId(isOnlineMedia)!),
      loadingEpisode: provider.loadingEpisode,
      mediaData: provider.mediaData,
      onEpisodeTap: (season, episode, embedUrl, contentTitle) {
        _handleEpisodeTap(context, season, episode, embedUrl, contentTitle);
      },
    );
  }

  void _handleEpisodeTap(
    BuildContext context,
    dynamic season,
    dynamic episode,
    String? embedUrl,
    String? contentTitle,
  ) async {
    // Use the provider's new handleEpisodeTap method
    await provider.handleEpisodeTap(
      context: context,
      season: season,
      episode: episode,
      tmdbId: int.parse(provider.getTmdbId(isOnlineMedia)!),
      embedUrl: embedUrl,
      contentTitle: contentTitle,
    );
  }
}
