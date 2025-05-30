import 'package:flutter/material.dart';
import 'package:stream_flutter/models/media_detail.dart';

class TitleSection extends StatelessWidget {
  final MediaDetail mediaDetail;

  const TitleSection({super.key, required this.mediaDetail});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          mediaDetail.name,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        if (mediaDetail.releaseYear != null)
          Text(
            mediaDetail.releaseYear!,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (mediaDetail.communityRating != null)
              Row(
                children: [
                  const Icon(Icons.star, size: 20, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    '${mediaDetail.communityRating!.toStringAsFixed(1)} / 10',
                  ),
                ],
              ),
            if (mediaDetail.resumePosition != null)
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Text(
                  'Resume from: ${(mediaDetail.resumePosition! ~/ 600000000)}m',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (mediaDetail.studio != null)
          Text(
            'Studio: ${mediaDetail.studio}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        if (mediaDetail.directors.isNotEmpty)
          Text(
            'Director: ${mediaDetail.directors.join(', ')}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        if (mediaDetail.writers.isNotEmpty)
          Text(
            'Writer: ${mediaDetail.writers.join(', ')}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        const SizedBox(height: 8),
        _buildGenres(context),
      ],
    );
  }

  Widget _buildGenres(BuildContext context) {
    return Wrap(
      spacing: 8,
      children:
      (mediaDetail.genres)
          .map(
            (genre) => Chip(
          label: Text(
            genre,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),
      )
          .toList(),
    );
  }
}