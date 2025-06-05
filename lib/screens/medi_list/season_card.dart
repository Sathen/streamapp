// lib/screens/season_card.dart
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/generic_media_details.dart';
import '../../providers/download_manager.dart';

class SeasonCard extends StatelessWidget {
  final GenericSeason season;
  final ThemeData theme;
  final String? tmdbId;
  final bool isFetching;
  final GenericEpisode? loadingEpisode;
  final GenericMediaData? mediaData;

  final void Function(GenericSeason, GenericEpisode, String?, String?)
  onEpisodeTap;

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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 4,
      // Provides a shadow effect
      clipBehavior: Clip.antiAlias,
      // Ensures content is clipped by the rounded corners
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
                leading:
                    season.posterPath != null && season.posterPath!.isNotEmpty
                        ? Image.network(
                          'https://image.tmdb.org/t/p/w500${season.posterPath!}',
                          // Correct TMDB image URL
                          width: 50,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => const Icon(
                                Icons.broken_image,
                                size: 50,
                              ), // Fallback on image loading error
                        )
                        : null, // No leading widget if posterPath is null or empty
              );
            },
            body: Column(
              children: [
                Divider(
                  height: 1, // Minimal height for the divider
                  thickness: 1, // Minimal thickness for the divider
                  color:
                      theme
                          .dividerColor, // Uses the theme's default divider color
                ),
                ...List.generate(season.episodes.length, (epIndex) {
                  final episode = season.episodes[epIndex];
                  final isCurrentlyLoading =
                      loadingEpisode?.episodeNumber == episode.episodeNumber;

                  var episodeKey = generateEpisodeKey(
                    tmdbId.toString(),
                    season.seasonNumber.toString(),
                    episode.episodeNumber.toString(),
                  );

                  final String? episodeEmbedUrl =
                      season.embedEpisodesUrls?[episode.episodeNumber] ??
                      episode.embedUrl;

                  return ListTile(
                    title: Text(
                      'Episode ${episode.episodeNumber}: ${episode.name}',
                    ),
                    subtitle: Text(
                      // Display air date, or 'N/A' if null/empty
                      episode.airDate != null
                          ? 'Air Date: ${episode.airDate}'
                          : 'Air Date: N/A',
                    ),
                    leading: _buildSeasonImageCover(episode),
                    trailing: _buildTrailing(
                      context,
                      isCurrentlyLoading,
                      episodeKey,
                    ),
                    onTap:
                        isCurrentlyLoading
                            ? null // Disable tap if currently loading
                            : () {
                              onEpisodeTap(
                                season,
                                episode,
                                episodeEmbedUrl,
                                mediaData?.title,
                              );
                            },
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonImageCover(GenericEpisode episode) {
    return episode.stillPath != null && episode.stillPath!.isNotEmpty
        ? Image.network(
          'https://image.tmdb.org/t/p/w200${episode.stillPath!}',
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) => const Icon(
                Icons.broken_image,
                size: 50,
              ), // Fallback on image loading error
        )
        : const Icon(Icons.movie, size: 50);
  }

  Widget _buildTrailing(
    BuildContext context,
    isCurrentlyLoading,
    String episodeKey,
  ) {
    if (isCurrentlyLoading) {
      log("buildTrailing: isCurrentlyLoading: $isCurrentlyLoading");
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final manager = context.watch<DownloadManager>();
    final downloading = manager.isDownloading(episodeKey);
    final downloadInfo = manager.getDownloadInfo(episodeKey);
    log(
      "buildTrailing: Episode key: $episodeKey progress: ${downloadInfo.progress} isDownloading: $downloading",
    );

    if (downloading) {
      return InkWell(
        onTap: () {
          // Call cancel download when tapped
          manager.cancelDownload(episodeKey);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Download cancelled for ${episodeKey.split('_').last}',
              ),
            ),
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                value: downloadInfo.progress,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
            Text(
              '${(downloadInfo.progress * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      );
    }
    return const Icon(Icons.play_arrow);
  }
}
