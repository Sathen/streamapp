// tv_seasons_list.dart
import 'package:flutter/material.dart';
import 'package:stream_flutter/models/tmdb_models.dart';

import '../../models/generic_media_details.dart';
import 'generic_season_list.dart'; // Import generic interfaces

class TVSeasonsList extends StatelessWidget {
  final List<TVSeasonDetails> seasonDetails;
  final ThemeData theme;
  final int tmdbId;
  final bool isFetching;
  final TVEpisode? loadingEpisode;
  final TmdbMediaDetails? mediaData;
  final void Function(TVSeasonDetails, TVEpisode, String?, String?) onEpisodeTap;

  const TVSeasonsList({
    super.key,
    required this.seasonDetails,
    required this.theme,
    required this.tmdbId,
    required this.isFetching,
    required this.loadingEpisode,
    required this.mediaData,
    required this.onEpisodeTap,
  });

  @override
  Widget build(BuildContext context) {
    if (seasonDetails.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(child: Text("No seasons available.")),
      );
    }

    final List<GenericSeason> genericSeasons =
        seasonDetails.cast<GenericSeason>();
    final GenericEpisode? genericLoadingEpisode = loadingEpisode;
    final GenericMediaData? genericMediaData = mediaData;

    return GenericSeasonsList(
      seasonDetails: genericSeasons,
      theme: theme,
      mediaId: tmdbId,
      isFetching: isFetching,
      loadingEpisode: genericLoadingEpisode,
      mediaData: genericMediaData,
      onEpisodeTap: (
        GenericSeason season,
        GenericEpisode episode,
        String? embedUrl,
        String? contentTitle,
      ) {
        onEpisodeTap(
          season as TVSeasonDetails,
          episode as TVEpisode,
          contentTitle,
          embedUrl,
        );
      },
    );
  }
}
