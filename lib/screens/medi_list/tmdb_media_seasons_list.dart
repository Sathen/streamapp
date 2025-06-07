// tv_seasons_list.dart
import 'package:flutter/material.dart';
import 'package:stream_flutter/models/tmdb_models.dart'; // Your specific TMDB models
import 'package:stream_flutter/screens/medi_list/season_episode_switcher.dart';
import '../../models/generic_media_details.dart'; // Your generic models

class TVSeasonsList extends StatelessWidget {
  final List<TVSeasonDetails> seasonDetails;
  final int tmdbId;
  final TVEpisode? loadingEpisode;
  final TmdbMediaDetails? mediaData;
  final void Function(
    TVSeasonDetails season,
    TVEpisode episode,
    String? embedUrl,
    String? contentTitle,
  )
  onEpisodeTap;

  const TVSeasonsList({
    super.key,
    required this.seasonDetails,
    required this.tmdbId,
    required this.loadingEpisode,
    required this.mediaData,
    required this.onEpisodeTap,
  });

  @override
  Widget build(BuildContext context) {
    if (seasonDetails.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("No seasons available."),
        ),
      );
    }

    final List<GenericSeason> genericSeasons =
        seasonDetails.cast<GenericSeason>().toList();
    final GenericEpisode? genericLoadingEpisode = loadingEpisode;
    final GenericMediaData? genericMediaData = mediaData;

    return SeasonEpisodeSwitcher(
      allSeasons: genericSeasons,
      mediaId: tmdbId.toString(),
      mediaData: genericMediaData,
      loadingEpisode: genericLoadingEpisode,
      onEpisodeTap: (
        GenericSeason season,
        GenericEpisode episode,
        String? contentTitle,
        String? embedUrl,
      ) {
        if (season is TVSeasonDetails && episode is TVEpisode) {
          onEpisodeTap(season, episode, mediaData?.title, mediaData?.originalTitle!);
        } else {
          debugPrint(
            "Error: Could not cast GenericSeason/GenericEpisode back to TMDB specific types in TVSeasonsList.",
          );
        }
      },
    );
  }
}
