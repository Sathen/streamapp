// lib/screens/widgets/generic_seasons_list.dart
import 'package:flutter/material.dart';
import 'package:stream_flutter/screens/medi_list/season_card.dart';

import '../../models/generic_media_details.dart';

class GenericSeasonsList extends StatelessWidget {
  final List<GenericSeason> seasonDetails;
  final ThemeData theme;
  final int? mediaId;
  final bool isFetching;
  final GenericEpisode? loadingEpisode;
  final GenericMediaData? mediaData;
  final void Function(GenericSeason, GenericEpisode, String?, String?)
  onEpisodeTap;

  const GenericSeasonsList({
    super.key,
    required this.seasonDetails,
    required this.theme,
    this.mediaId,
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

    return SliverList(
      delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
        final season = seasonDetails[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          child: SeasonCard(
            season: season,
            theme: theme,
            tmdbId: mediaId,
            isFetching: isFetching,
            loadingEpisode: loadingEpisode,
            mediaData: mediaData,
            onEpisodeTap: onEpisodeTap,
          ),
        );
      }, childCount: seasonDetails.length),
    );
  }
}
