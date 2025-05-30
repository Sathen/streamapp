import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:stream_flutter/models/series_models.dart';

class EpisodeItem extends StatelessWidget {
  final Episode episode;
  final VoidCallback onPlay;
  final VoidCallback onTap;

  const EpisodeItem({
    super.key,
    required this.episode,
    required this.onPlay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: ListTile(
        onTap: onTap,
        leading:
            episode.stillPath != null
                ? CachedNetworkImage(
                  imageUrl: episode.stillPath!,
                  width: 120,
                  height: 68,
                  fit: BoxFit.cover,
                )
                : Container(
                  width: 120,
                  height: 68,
                  color: Theme.of(context).colorScheme.surface,
                  child: const Icon(Icons.movie),
                ),
        title: Text(
          '${episode.episodeNumber}. ${episode.name}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle:
            episode.overview != null
                ? Text(
                  episode.overview!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                )
                : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (episode.runtime != null)
              Text(
                '${episode.runtime!.inMinutes}m',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            IconButton(
              icon: const Icon(Icons.play_circle_outline),
              onPressed: onPlay,
            ),
          ],
        ),
      ),
    );
  }
}
