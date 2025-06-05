import 'package:flutter/material.dart';

import '../models/online_media_details_entity.dart';
import '../models/tmdb_models.dart';

class MediaHeaderSection extends StatelessWidget {
  final TmdbMediaDetails? media;
  final OnlineMediaDetailsEntity? mediaDetail;

  const MediaHeaderSection({
    super.key,
    this.media,
    this.mediaDetail,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = media?.title ?? mediaDetail?.title;
    final overview = media?.overview ?? mediaDetail?.description;
    final genres = media?.genres.map((g) => g.name).toList();
    final rating = media?.voteAverage ?? mediaDetail?.rating;
    final voteCount = media?.voteCount;
    final releaseDate = (media is MovieDetails) ? (media as MovieDetails).releaseDate : mediaDetail?.year;
    final runtime = (media is MovieDetails) ? (media as MovieDetails).runtime : mediaDetail?.year;
    final firstAirDate = (media is TVDetails) ? (media as TVDetails).firstAirDate : mediaDetail?.year;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold),
          ),
        const SizedBox(height: 8),
        if (genres != null && genres.isNotEmpty)
          Text(
            'Genres: ${genres.join(', ')}',
            style: theme.textTheme.bodyMedium,
          ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.star, color: Colors.amber, size: 20),
            const SizedBox(width: 4),
            if (rating != null )
              Text(
                '${rating.toStringAsFixed(1)}/10',
                style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold),
              ),
            if (voteCount != null)
              Text(
                ' ($voteCount votes)',
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (releaseDate != null && releaseDate.isNotEmpty)
          Text('Release: $releaseDate', style: theme.textTheme.bodyMedium),
        if (runtime != null)
          Text('Runtime: $runtime min', style: theme.textTheme.bodyMedium),
        if (firstAirDate != null && firstAirDate.isNotEmpty)
          Text('First Air: $firstAirDate', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 24),
        Text(
          'Overview',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          overview ?? 'No overview available.',
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.justify,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

}
