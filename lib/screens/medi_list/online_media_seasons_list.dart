// lib/screens/widgets/online_media_seasons_list.dart
import 'package:flutter/material.dart';
import 'package:stream_flutter/models/online_media_details_entity.dart'; // Your specific Online Media models
import 'package:stream_flutter/screens/medi_list/season_episode_switcher.dart';
import '../../models/generic_media_details.dart'; // Your generic models

class OnlineMediaSeasonsList extends StatelessWidget {
  final OnlineMediaDetailsEntity mediaDetails;

  // final ThemeData theme; // Theme will be picked up by SeasonEpisodeSwitcher from context
  // final bool isFetching; // loadingEpisode on SeasonEpisodeSwitcher handles specific episode loading
  final OnlineMediaDetailsEpisode? loadingEpisode;
  final void Function(
    OnlineMediaDetailsSeasons season,
    OnlineMediaDetailsEpisode episode,
    String? embedUrl,
    String? contentTitle,
  )
  onEpisodeTap;

  const OnlineMediaSeasonsList({
    super.key,
    required this.mediaDetails,
    required this.loadingEpisode,
    required this.onEpisodeTap,
  });

  @override
  Widget build(BuildContext context) {
    if (mediaDetails.seasons.isEmpty) {
      return const SliverToBoxAdapter(
        // Correct for CustomScrollView context
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("No seasons available."),
          ),
        ),
      );
    }

    // Cast to the generic types that SeasonEpisodeSwitcher expects.
    // This assumes OnlineMediaDetailsSeasons implements/extends GenericSeason, etc.
    final List<OnlineMediaDetailsSeasons> genericSeasons =
        mediaDetails.seasons.cast<OnlineMediaDetailsSeasons>().toList();
    final GenericEpisode? genericLoadingEpisode = loadingEpisode; // Direct cast
    final OnlineMediaDetailsEntity genericMediaData = mediaDetails; // Direct cast

    // For mediaId, SeasonEpisodeSwitcher uses it for generating unique keys.
    // Using title might be okay if it's unique enough, or if your OnlineMediaDetailsEntity
    // has a more specific ID field, that would be better.
    // The original code used mediaDetails.title.
    final String mediaIdForSwitcher =
        mediaDetails.title.replaceAll(' ', '_');

    return SliverToBoxAdapter(
      // SeasonEpisodeSwitcher is a Column, so wrap it for use in slivers
      child: SeasonEpisodeSwitcher(
        allSeasons: genericSeasons,
        mediaId: mediaIdForSwitcher,
        mediaData: genericMediaData,
        loadingEpisode: genericLoadingEpisode,
        onEpisodeTap: (
          GenericSeason season,
          GenericEpisode episode,
          String? embedUrl,
          String? contentTitle,
        ) {
          if (season is OnlineMediaDetailsSeasons &&
              episode is OnlineMediaDetailsEpisode) {
            onEpisodeTap(
              season, // Now correctly typed as OnlineMediaDetailsSeasons
              episode, // Now correctly typed as OnlineMediaDetailsEpisode
              embedUrl,
              contentTitle,
            );
          } else {
            // Handle error: The types received are not what was expected.
            debugPrint(
              "Error: Could not cast GenericSeason/GenericEpisode back to Online Media specific types in OnlineMediaSeasonsList.",
            );
          }
        },
      ),
    );
  }
}
