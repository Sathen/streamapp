import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/series_models.dart';
import 'episode_item.dart';

class Episodes extends StatelessWidget {
  final SeriesInfo seriesInfo;
  final int selectedSeasonIndex;
  final ValueChanged<int> onSeasonChanged;
  final void Function(Episode) onPlayEpisode;


  const Episodes({
    super.key,
    required this.seriesInfo,
    required this.selectedSeasonIndex,
    required this.onSeasonChanged,
    required this.onPlayEpisode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Episodes', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        _buildSeasonSelector(context),
        const SizedBox(height: 16),
        _buildEpisodesList(context),
      ],
    );
  }

  Widget _buildSeasonSelector(BuildContext context) {
    var seasonNumber = selectedSeasonIndex;
    // Ensure initial value exists in the seasons list
    if (selectedSeasonIndex == 0 && seriesInfo.seasons.isNotEmpty) {
      seasonNumber = seriesInfo.seasons[0].seasonNumber;
    }
    return DropdownButton<int>(
      value: seasonNumber,
      isExpanded: true,
      items:
          seriesInfo.seasons.map((season) {
            return DropdownMenuItem<int>(
              value: season.seasonNumber,
              child: Text(
                season.name,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }).toList(),
      onChanged: (value) {
        if (value != null) {
          onSeasonChanged(value);
        }
      },
    );
  }

  Widget _buildEpisodesList(BuildContext context) {
    var seasonNumber = selectedSeasonIndex;
    if (selectedSeasonIndex == 0 && seriesInfo.seasons.isNotEmpty) {
      seasonNumber = seriesInfo.seasons.first.seasonNumber;
    }

    final currentSeason = seriesInfo.seasons.firstWhere(
          (s) => s.seasonNumber == seasonNumber,
    );

    final episodes = seriesInfo.getEpisodesForSeason(currentSeason.id);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: episodes.length,
      itemBuilder: (context, index) {
        final episode = episodes[index];
        return _buildEpisodeItem(context, episode);
      },
    );
  }

  Widget _buildEpisodeItem(BuildContext context, Episode episode) {
    return EpisodeItem(
      episode: episode,
      onTap: () => context.go('/media/${episode.id}'),
      onPlay: () => onPlayEpisode(episode)
    );
  }

}
