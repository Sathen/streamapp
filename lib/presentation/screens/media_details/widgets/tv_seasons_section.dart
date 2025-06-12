import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../screens/medi_list/tmdb_media_seasons_list.dart';
import '../../../providers/media_details/media_details_provider.dart';

class TvSeasonsSection extends StatelessWidget {
  final MediaDetailsProvider provider;
  final int tmdbId;

  const TvSeasonsSection({
    super.key,
    required this.provider,
    required this.tmdbId,
  });

  @override
  Widget build(BuildContext context) {
    if (provider.seasonDetails == null || provider.seasonDetails!.isEmpty) {
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
        child: TVSeasonsList(
          seasonDetails: provider.seasonDetails!,
          tmdbId: tmdbId,
          loadingEpisode: provider.loadingEpisode,
          mediaData: provider.mediaData,
          onEpisodeTap: (season, episode, title, originalTitle) {
            _handleEpisodeTap(context, season, episode, title, originalTitle);
          },
        ),
      ),
    );
  }

  void _handleEpisodeTap(
    BuildContext context,
    season,
    episode,
    String? title,
    String? originalTitle,
  ) {
    provider.setEpisodeLoading(episode);

    // Handle episode playback logic here
    // This would integrate with your existing episode tap handling

    // Reset loading state after handling
    Future.delayed(const Duration(seconds: 2), () {
      provider.setEpisodeLoading(null);
    });
  }
}
