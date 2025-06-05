// lib/screens/widgets/online_media_seasons_list.dart
import 'package:flutter/material.dart';
import 'package:stream_flutter/models/online_media_details_entity.dart';

import '../../models/generic_media_details.dart';
import 'generic_season_list.dart';

class OnlineMediaSeasonsList extends StatelessWidget {
  final OnlineMediaDetailsEntity mediaDetails;
  final ThemeData theme;
  final bool isFetching;
  final OnlineMediaDetailsEpisode? loadingEpisode;
  final void Function(
    OnlineMediaDetailsSeasons,
    OnlineMediaDetailsEpisode,
    String?,
    String?,
  )
  onEpisodeTap;

  const OnlineMediaSeasonsList({
    super.key,
    required this.mediaDetails,
    required this.theme,
    required this.isFetching,
    required this.loadingEpisode,
    required this.onEpisodeTap,
  });

  @override
  Widget build(BuildContext context) {
    if (mediaDetails.seasons.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(child: Text("No seasons available.")),
      );
    }

    final List<GenericSeason> genericSeasons =
        mediaDetails.seasons.cast<GenericSeason>();
    final GenericEpisode? genericLoadingEpisode = loadingEpisode;
    final GenericMediaData genericMediaData = mediaDetails;

    return GenericSeasonsList(
      seasonDetails: genericSeasons,
      theme: theme,
      mediaId: null,
      // No specific TMDB ID for online media, pass null
      isFetching: isFetching,
      loadingEpisode: genericLoadingEpisode,
      mediaData: genericMediaData,
      onEpisodeTap: (
        GenericSeason season,
        GenericEpisode episode,
        String? embedUrl,
        String? contentTitle,
      ) {
        // Cast back to original types for your specific callback
        onEpisodeTap(
          season as OnlineMediaDetailsSeasons,
          episode as OnlineMediaDetailsEpisode,
          embedUrl,
          contentTitle,
        );
      },
    );
  }
}
