// lib/screens/season_card.dart
import 'package:flutter/material.dart';

import '../../models/generic_media_details.dart';

class SeasonCard extends StatelessWidget {
  final GenericSeason season;
  final ThemeData theme;
  final int? tmdbId;
  final bool isFetching;
  final GenericEpisode? loadingEpisode;
  final GenericMediaData? mediaData;
  // Reverting onEpisodeTap signature to the original order:
  // (GenericSeason, GenericEpisode, String, String?)
  // where the third argument is episodeEmbedUrl and the fourth is contentTitle.
  final void Function(GenericSeason, GenericEpisode, String?, String?) onEpisodeTap;

  const SeasonCard({
    super.key,
    required this.season,
    required this.theme,
    this.tmdbId,
    required this.isFetching,
    required this.loadingEpisode,
    required this.mediaData,
    required this.onEpisodeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card( // Wrapped with Card for rounded corners and elevation
      margin: const EdgeInsets.symmetric(vertical: 4.0), // Adds vertical space between cards
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0), // Rounded corners with a radius of 12
      ),
      elevation: 4, // Provides a shadow effect
      clipBehavior: Clip.antiAlias, // Ensures content is clipped by the rounded corners
      child: ExpansionPanelList.radio(
        expandedHeaderPadding: EdgeInsets.zero,
        initialOpenPanelValue: null, // Ensures all panels are closed by default
        elevation: 0, // Set elevation to 0 here, as the Card is providing it
        children: [
          ExpansionPanelRadio(
            value: '${tmdbId ?? 'online'}_${season.seasonNumber}',
            headerBuilder: (context, isExpanded) {
              return ListTile(
                title: Text(
                  'Season ${season.seasonNumber} - ${season.title}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${season.numberOfEpisodes} episodes',
                  style: const TextStyle(fontSize: 12),
                ),
                leading: season.posterPath != null && season.posterPath!.isNotEmpty
                    ? Image.network(
                  'https://image.tmdb.org/t/p/w500${season.posterPath!}', // Correct TMDB image URL
                  width: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, size: 50), // Fallback on image loading error
                )
                    : null, // No leading widget if posterPath is null or empty
              );
            },
            body: Column(
              children: List.generate(season.episodes.length, (epIndex) {
                final episode = season.episodes[epIndex];
                final isCurrentlyLoading = loadingEpisode?.episodeNumber == episode.episodeNumber;

                final String? episodeEmbedUrl = season.embedEpisodesUrls?[episode.episodeNumber] ?? episode.embedUrl;

                return ListTile(
                  title: Text('Episode ${episode.episodeNumber}: ${episode.name}'),
                  subtitle: Text(
                    // Display air date, or 'N/A' if null/empty
                    episode.airDate != null ? 'Air Date: ${episode.airDate}' : 'Air Date: N/A',
                  ),
                  leading: episode.stillPath != null && episode.stillPath!.isNotEmpty
                      ? Image.network(
                    'https://image.tmdb.org/t/p/w200${episode.stillPath!}', // Common TMDB still path size
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, size: 50), // Fallback on image loading error
                  )
                      : const Icon(Icons.movie, size: 50), // Fallback icon if no stillPath
                  trailing: isCurrentlyLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.play_arrow),
                  onTap: isCurrentlyLoading
                      ? null // Disable tap if currently loading
                      : () {
                    // Only proceed if episodeEmbedUrl is not null to prevent null-assertion errors down the line
                    if (episodeEmbedUrl != null) {
                      // Calling onEpisodeTap with original order: (season, episode, episodeEmbedUrl, contentTitle)
                      onEpisodeTap(
                        season,
                        episode,
                        episodeEmbedUrl,
                        mediaData?.title,
                      );
                    } else {
                      // Optionally, show a message to the user if no stream is available
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No stream available for this episode.')),
                      );
                    }
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}